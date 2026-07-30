"""Backend architecture contract tests."""

from __future__ import annotations

import ast
import inspect
from pathlib import Path

from app import main as app_main
from app.main import app

BACKEND_ROOT = Path(__file__).resolve().parent.parent
API_V1_ROOT = BACKEND_ROOT / "app" / "api" / "v1"
APP_ROOT = BACKEND_ROOT / "app"

DB_METHODS = {
    "add",
    "delete",
    "execute",
    "flush",
    "get",
    "refresh",
    "scalar",
    "scalars",
}
SQLALCHEMY_QUERY_IMPORTS = {
    "delete",
    "func",
    "insert",
    "select",
    "update",
}
ROUTER_HTTP_METHODS = {"get", "post", "put", "patch", "delete"}
MUTATING_HTTP_METHODS = {"post", "put", "patch", "delete"}
PUBLIC_API_OPERATIONS = {
    ("POST", "/api/v1/auth/oauth/{provider}"),
    ("POST", "/api/v1/auth/dev-login"),
    ("POST", "/api/v1/auth/token/refresh"),
    ("GET", "/api/v1/address/search"),
    ("GET", "/api/v1/app/version"),
    ("GET", "/api/v1/public/academies/invites/{token}/preview"),
    ("GET", "/api/v1/public/growth-reports/{token}"),
    ("GET", "/api/v1/public/invites/{code}/landing"),
    ("GET", "/api/v1/public/student-summaries/{token}"),
    ("GET", "/api/v1/teachers/public/{teacher_id}"),
    ("GET", "/api/v1/users/supported-locales"),
}


def _python_files(root: Path) -> list[Path]:
    return sorted(path for path in root.rglob("*.py") if "__pycache__" not in path.parts)


def _module_path(path: Path) -> str:
    return str(path.relative_to(BACKEND_ROOT))


def test_api_routers_do_not_run_database_queries_directly() -> None:
    """Routers should delegate business queries and mutations to services."""
    violations: list[str] = []
    for path in _python_files(API_V1_ROOT):
        if path.name == "__init__.py":
            continue
        tree = ast.parse(path.read_text())
        for node in ast.walk(tree):
            if isinstance(node, ast.ImportFrom) and node.module == "sqlalchemy":
                imported = {alias.name for alias in node.names}
                disallowed = sorted(imported & SQLALCHEMY_QUERY_IMPORTS)
                for name in disallowed:
                    violations.append(f"{_module_path(path)} imports sqlalchemy.{name}")
            if isinstance(node, ast.Attribute) and node.attr in DB_METHODS:
                if isinstance(node.value, ast.Name) and node.value.id in {"db", "session"}:
                    violations.append(f"{_module_path(path)} calls {node.value.id}.{node.attr}()")

    assert violations == []


def test_mutating_api_routes_declare_status_codes() -> None:
    """POST, PUT, PATCH, and DELETE routes should not rely on FastAPI's default 200."""
    violations: list[str] = []
    for path in _python_files(API_V1_ROOT):
        if path.name == "__init__.py":
            continue
        tree = ast.parse(path.read_text())
        for node in ast.walk(tree):
            if not isinstance(node, ast.AsyncFunctionDef | ast.FunctionDef):
                continue
            for decorator in node.decorator_list:
                if not isinstance(decorator, ast.Call) or not isinstance(decorator.func, ast.Attribute):
                    continue
                method = decorator.func.attr
                if method not in MUTATING_HTTP_METHODS:
                    continue
                if any(keyword.arg == "status_code" for keyword in decorator.keywords):
                    continue
                route_path = "<unknown>"
                if decorator.args and isinstance(decorator.args[0], ast.Constant):
                    route_path = str(decorator.args[0].value)
                violations.append(f"{_module_path(path)}:{node.lineno} @{method}({route_path})")

    assert violations == []


def test_all_api_routes_declare_status_codes() -> None:
    """Every API route should declare status_code for explicit OpenAPI contracts."""
    violations: list[str] = []
    for path in _python_files(API_V1_ROOT):
        if path.name == "__init__.py":
            continue
        tree = ast.parse(path.read_text())
        for node in ast.walk(tree):
            if not isinstance(node, ast.AsyncFunctionDef | ast.FunctionDef):
                continue
            for decorator in node.decorator_list:
                if not isinstance(decorator, ast.Call) or not isinstance(decorator.func, ast.Attribute):
                    continue
                method = decorator.func.attr
                if method not in ROUTER_HTTP_METHODS:
                    continue
                if any(keyword.arg == "status_code" for keyword in decorator.keywords):
                    continue
                route_path = "<unknown>"
                if decorator.args and isinstance(decorator.args[0], ast.Constant):
                    route_path = str(decorator.args[0].value)
                violations.append(f"{_module_path(path)}:{node.lineno} @{method}({route_path})")

    assert violations == []


def test_api_v1_does_not_expose_payments_router() -> None:
    """Current tuition deposit policy stays on subscriptions, not /payments."""
    api_init = (API_V1_ROOT / "__init__.py").read_text()
    assert "payments" not in api_init
    assert not (API_V1_ROOT / "payments.py").exists()


def test_lower_layers_do_not_import_api_layer() -> None:
    """Models, schemas, and services must not depend on FastAPI router modules."""
    violations: list[str] = []
    for root_name in ("models", "schemas", "services"):
        for path in _python_files(APP_ROOT / root_name):
            tree = ast.parse(path.read_text())
            for node in ast.walk(tree):
                if isinstance(node, ast.ImportFrom) and node.module and node.module.startswith("app.api"):
                    violations.append(f"{_module_path(path)} imports {node.module}")
                elif isinstance(node, ast.Import):
                    for alias in node.names:
                        if alias.name.startswith("app.api"):
                            violations.append(f"{_module_path(path)} imports {alias.name}")

    assert violations == []


def test_schemas_do_not_import_model_layer() -> None:
    """Pydantic schemas should describe API contracts without depending on ORM models."""
    violations: list[str] = []
    for path in _python_files(APP_ROOT / "schemas"):
        tree = ast.parse(path.read_text())
        for node in ast.walk(tree):
            if isinstance(node, ast.ImportFrom) and node.module and node.module.startswith("app.models"):
                violations.append(f"{_module_path(path)} imports {node.module}")
            elif isinstance(node, ast.Import):
                for alias in node.names:
                    if alias.name.startswith("app.models"):
                        violations.append(f"{_module_path(path)} imports {alias.name}")

    assert violations == []


def test_openapi_operation_ids_are_unique() -> None:
    """OpenAPI operation IDs must be stable and unique for docs and generated clients."""
    schema = app.openapi()
    operation_locations: dict[str, list[str]] = {}
    for path, path_item in schema["paths"].items():
        for method, operation in path_item.items():
            if method not in {"get", "post", "put", "patch", "delete"}:
                continue
            operation_id = operation.get("operationId")
            if not operation_id:
                continue
            operation_locations.setdefault(operation_id, []).append(f"{method.upper()} {path}")

    duplicates = {
        operation_id: locations for operation_id, locations in operation_locations.items() if len(locations) > 1
    }

    assert duplicates == {}


def test_api_v1_routes_require_security_unless_publicly_documented() -> None:
    """Every v1 API operation must declare auth unless it is an explicit public contract."""
    schema = app.openapi()
    unsecured_operations: list[str] = []
    for path, path_item in schema["paths"].items():
        if not path.startswith("/api/v1/"):
            continue
        for method, operation in path_item.items():
            if method not in {"get", "post", "put", "patch", "delete"}:
                continue
            route_key = (method.upper(), path)
            if route_key in PUBLIC_API_OPERATIONS:
                continue
            if not operation.get("security"):
                operation_id = operation.get("operationId", "<missing operationId>")
                unsecured_operations.append(f"{method.upper()} {path} ({operation_id})")

    assert unsecured_operations == []


def test_api_v1_success_responses_declare_body_schemas_unless_no_content() -> None:
    """2xx responses with bodies must be explicit OpenAPI contracts."""
    schema = app.openapi()
    missing_response_schemas: list[str] = []
    for path, path_item in schema["paths"].items():
        if not path.startswith("/api/v1/"):
            continue
        for method, operation in path_item.items():
            if method not in {"get", "post", "put", "patch", "delete"}:
                continue
            for status_code, response in operation.get("responses", {}).items():
                if not str(status_code).startswith("2") or str(status_code) == "204":
                    continue
                content = response.get("content", {}) if isinstance(response, dict) else {}
                has_schema = any(media_type.get("schema") for media_type in content.values())
                if not has_schema:
                    operation_id = operation.get("operationId", "<missing operationId>")
                    missing_response_schemas.append(f"{method.upper()} {path} {status_code} ({operation_id})")

    assert missing_response_schemas == []


def test_app_lifespan_runs_runtime_configuration_validation() -> None:
    """FastAPI startup must fail early for unsafe production-like configuration."""
    source = inspect.getsource(app_main.lifespan)

    assert "validate_runtime_configuration()" in source


def test_docker_runtime_uses_locked_uv_dependencies() -> None:
    """Runtime image must not resync to newer dependency versions at container start."""
    dockerfile = (BACKEND_ROOT / "Dockerfile").read_text()

    assert "COPY --from=builder /app/uv.lock /app/uv.lock" in dockerfile
    assert '"--locked"' in dockerfile


def test_student_create_routes_use_runtime_annotations_for_openapi() -> None:
    """StudentCreate request bodies must be concrete types for Python 3.12 OpenAPI generation."""
    for route_file in (API_V1_ROOT / "students.py", API_V1_ROOT / "teachers.py"):
        source = route_file.read_text()
        assert "from __future__ import annotations" not in source


def test_subscription_access_policy_lives_in_dedicated_service() -> None:
    """Subscription visibility and teacher ownership checks should stay reusable."""
    subscription_service = (APP_ROOT / "services" / "subscription_service.py").read_text()
    access_service = APP_ROOT / "services" / "subscription_access_service.py"

    assert access_service.exists()
    source = access_service.read_text()
    assert "class SubscriptionAccessService" in source
    assert "async def get_subscription_for_user" in source
    assert "async def require_teacher_subscription" in source
    assert "async def get_membership_for_teacher" in source
    assert "async def visible_subscription_query" in source
    assert "async def visible_student_ids" in source
    assert "_get_subscription_for_user" not in subscription_service
    assert "_get_subscription_for_teacher" not in subscription_service
