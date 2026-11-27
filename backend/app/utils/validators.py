"""
Request validation helpers.
"""
import re


EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")
USERNAME_RE = re.compile(r"^[a-zA-Z0-9_]{3,30}$")


def validate_email(email: str) -> bool:
    return bool(EMAIL_RE.match(email or ""))


def validate_username(username: str) -> bool:
    return bool(USERNAME_RE.match(username or ""))


def validate_password_strength(password: str) -> list:
    """Return a list of unmet password requirements."""
    errors = []
    if len(password) < 8:
        errors.append("Password must be at least 8 characters.")
    if not re.search(r"[A-Z]", password):
        errors.append("Password must contain at least one uppercase letter.")
    if not re.search(r"[a-z]", password):
        errors.append("Password must contain at least one lowercase letter.")
    if not re.search(r"\d", password):
        errors.append("Password must contain at least one digit.")
    return errors


def paginated_response(pagination, items_key: str = "items"):
    return {
        items_key: [item.to_dict() for item in pagination.items],
        "pagination": {
            "page": pagination.page,
            "per_page": pagination.per_page,
            "total": pagination.total,
            "pages": pagination.pages,
            "has_next": pagination.has_next,
            "has_prev": pagination.has_prev,
        },
    }
