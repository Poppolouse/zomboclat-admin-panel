RCON_AUDIT_EXEMPT_USERS = frozenset({"poppolouse"})


def should_log_rcon(username: str) -> bool:
    """Return whether a successful RCON request belongs in the audit log."""
    return username.strip().casefold() not in RCON_AUDIT_EXEMPT_USERS
