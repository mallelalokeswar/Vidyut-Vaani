"""
Route decorators for role-based access control.
"""
from functools import wraps
from flask import jsonify
from flask_jwt_extended import verify_jwt_in_request, get_jwt
from app.models.user import UserRole


def roles_required(*roles: UserRole):
    """
    Decorator that enforces JWT presence and verifies the JWT role claim
    is in the allowed set.  Backend is authoritative — no frontend bypass possible.
    """
    def decorator(fn):
        @wraps(fn)
        def wrapper(*args, **kwargs):
            verify_jwt_in_request()
            claims = get_jwt()
            user_role = claims.get("role")
            allowed = {r.value if isinstance(r, UserRole) else r for r in roles}
            if user_role not in allowed:
                return jsonify(
                    {
                        "error": "Forbidden",
                        "message": "You do not have permission to access this resource.",
                    }
                ), 403
            return fn(*args, **kwargs)
        return wrapper
    return decorator


def citizen_required(fn):
    return roles_required(UserRole.CITIZEN)(fn)


def admin_required(fn):
    return roles_required(UserRole.ADMIN)(fn)


def operator_required(fn):
    return roles_required(UserRole.OPERATOR)(fn)


def admin_or_operator_required(fn):
    return roles_required(UserRole.ADMIN, UserRole.OPERATOR)(fn)
