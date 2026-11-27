"""
Authentication routes — register, login, refresh, logout, verify.
"""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import (
    jwt_required,
    get_jwt,
    get_jwt_identity,
    get_current_user,
)
from app.services.auth_service import AuthService
from app.utils.validators import (
    validate_email,
    validate_username,
    validate_password_strength,
)
from app.models.user import UserRole

auth_bp = Blueprint("auth", __name__)

VALID_ROLES = {r.value for r in UserRole}


@auth_bp.route("/register", methods=["POST"])
def register():
    """Public endpoint — citizen self-registration."""
    data = request.get_json(silent=True) or {}
    errors = []

    full_name = (data.get("full_name") or "").strip()
    email = (data.get("email") or "").strip()
    username = (data.get("username") or "").strip()
    password = data.get("password") or ""

    if not full_name:
        errors.append("Full name is required.")
    if not validate_email(email):
        errors.append("A valid email address is required.")
    if not validate_username(username):
        errors.append("Username must be 3–30 alphanumeric characters or underscores.")
    pw_errors = validate_password_strength(password)
    if pw_errors:
        errors.extend(pw_errors)

    if errors:
        return jsonify({"errors": errors}), 422

    try:
        user = AuthService.register_citizen(
            {
                "full_name": full_name,
                "email": email,
                "username": username,
                "password": password,
                "phone": data.get("phone"),
                "locality": data.get("locality"),
                "meter_number": data.get("meter_number"),
            }
        )
        return jsonify({"message": "Registration successful.", "user": user.to_dict()}), 201
    except ValueError as exc:
        return jsonify({"error": str(exc)}), 409


@auth_bp.route("/login", methods=["POST"])
def login():
    """
    Authenticate user and return JWT tokens.
    The 'role' field is what the user selected on the frontend.
    The backend verifies the actual stored role matches.
    """
    data = request.get_json(silent=True) or {}
    identifier = (data.get("identifier") or data.get("email") or data.get("username") or "").strip()
    password = data.get("password") or ""
    requested_role = (data.get("role") or "").strip()

    if not identifier or not password or not requested_role:
        return jsonify({"error": "identifier/email, password and role are required."}), 400

    if requested_role not in VALID_ROLES:
        return jsonify({"error": f"Invalid role. Allowed: {', '.join(sorted(VALID_ROLES))}."}), 400

    ip = request.remote_addr
    try:
        user, access_token, refresh_token = AuthService.login(
            identifier=identifier,
            password=password,
            requested_role=requested_role,
            ip=ip,
        )
        return jsonify(
            {
                "message": "Login successful.",
                "access_token": access_token,
                "refresh_token": refresh_token,
                "user": user.to_dict(),
            }
        ), 200
    except PermissionError as exc:
        return jsonify({"error": str(exc)}), 403
    except ValueError as exc:
        return jsonify({"error": str(exc)}), 401


@auth_bp.route("/refresh", methods=["POST"])
@jwt_required(refresh=True)
def refresh():
    """Issue a new access token from a valid refresh token."""
    claims = get_jwt()
    if AuthService.is_token_revoked(None, claims):
        return jsonify({"error": "Token has been revoked."}), 401
    user_id = int(get_jwt_identity())
    try:
        access_token = AuthService.refresh_token(user_id, claims)
        return jsonify({"access_token": access_token}), 200
    except PermissionError as exc:
        return jsonify({"error": str(exc)}), 403


@auth_bp.route("/logout", methods=["DELETE"])
@jwt_required(verify_type=False)
def logout():
    """Revoke the presented token (access or refresh)."""
    jwt_data = get_jwt()
    user_id = int(get_jwt_identity())
    AuthService.logout(jwt_data["jti"], jwt_data["type"], user_id)
    return jsonify({"message": "Logged out successfully."}), 200


@auth_bp.route("/me", methods=["GET"])
@jwt_required()
def me():
    """Return the currently authenticated user's profile."""
    from app.models.user import User
    user_id = int(get_jwt_identity())
    user = User.query.get_or_404(user_id)
    return jsonify({"user": user.to_dict()}), 200


@auth_bp.route("/forgot-password", methods=["POST"])
def forgot_password():
    """
    Initiate password reset.
    In production, send an email with a signed reset link.
    """
    data = request.get_json(silent=True) or {}
    email = (data.get("email") or "").strip()
    if not validate_email(email):
        return jsonify({"error": "A valid email address is required."}), 400
    # Always return success to prevent user enumeration
    return jsonify(
        {"message": "If that email is registered, a reset link has been sent."}
    ), 200
