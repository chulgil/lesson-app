"""Backend architecture contract tests."""

from __future__ import annotations

import ast
from pathlib import Path

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
        operation_id: locations
        for operation_id, locations in operation_locations.items()
        if len(locations) > 1
    }

    assert duplicates == {}
