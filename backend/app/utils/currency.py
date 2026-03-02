"""Currency formatting utilities."""

CURRENCY_CONFIG = {
    "KRW": {"symbol": "\u20a9", "decimals": 0, "min_unit": 1},
    "USD": {"symbol": "$", "decimals": 2, "min_unit": 100},
    "JPY": {"symbol": "\u00a5", "decimals": 0, "min_unit": 1},
}


def format_currency(amount_min_unit: int, currency: str = "KRW") -> str:
    """Format amount from minimum units to display string.

    Args:
        amount_min_unit: Amount in minimum currency units (won, cents, yen)
        currency: ISO 4217 currency code
    """
    config = CURRENCY_CONFIG.get(currency, CURRENCY_CONFIG["KRW"])
    if config["decimals"] > 0:
        display = amount_min_unit / config["min_unit"]
        return f"{config['symbol']}{display:,.{config['decimals']}f}"
    return f"{config['symbol']}{amount_min_unit:,}"


def to_min_unit(amount: float, currency: str = "KRW") -> int:
    """Convert display amount to minimum currency units."""
    config = CURRENCY_CONFIG.get(currency, CURRENCY_CONFIG["KRW"])
    return int(amount * config["min_unit"])
