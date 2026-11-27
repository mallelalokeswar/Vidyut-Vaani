"""
Authentication service — registration, login, token management.
"""
from datetime import datetime, timezone
from flask_jwt_extended import (
    create_access_token,
    create_refresh_token,
    get_jwt,
)
from app import db, bcrypt
from app.models.user import User, UserRole, AccountStatus
from app.models.token_blocklist import TokenBlocklist
from app.models.audit_log import AuditLog


class AuthService:

    @staticmethod
    def register_citizen(data: dict) -> User:
        """Register a new citizen account."""
        # Uniqueness checks
        if User.query.filter_by(email=data["email"].lower()).first():
            raise ValueError("An account with this email already exists.")
        if User.query.filter_by(username=data["username"].lower()).first():
            raise ValueError("This username is already taken.")

        hashed = bcrypt.generate_password_hash(data["password"]).decode("utf-8")
        user = User(
            full_name=data["full_name"],
            email=data["email"].lower(),
            username=data["username"].lower(),
            password_hash=hashed,
            role=UserRole.CITIZEN,
            status=AccountStatus.ACTIVE,
            phone=data.get("phone"),
            locality=data.get("locality"),
            meter_number=data.get("meter_number"),
        )
        db.session.add(user)
        db.session.commit()
        AuthService._log(user.id, "REGISTER", "user", user.id, {"email": user.email})
        return user

    @staticmethod
    def login(identifier: str, password: str, requested_role: str, ip: str = None):
        """
        Authenticate user.

        1. Look up by email or username.
        2. Verify password hash.
        3. Check account status.
        4. Verify backend role == requested role (never trust frontend alone).
        Returns (user, access_token, refresh_token) or raises.
        """
        user = (
            User.query.filter_by(email=identifier.lower()).first()
            or User.query.filter_by(username=identifier.lower()).first()
        )
        if not user:
            raise ValueError("Invalid credentials.")

        if not bcrypt.check_password_hash(user.password_hash, password):
            AuthService._log(None, "LOGIN_FAILED", "user", None, {"identifier": identifier})
            raise ValueError("Invalid credentials.")

        if user.status == AccountStatus.SUSPENDED:
            raise PermissionError("Your account has been suspended. Contact support.")
        if user.status == AccountStatus.INACTIVE:
            raise PermissionError("Your account is inactive.")

        # Role verification — backend is authoritative
        if user.role.value != requested_role:
            AuthService._log(
                user.id,
                "ROLE_MISMATCH",
                "user",
                user.id,
                {"requested": requested_role, "actual": user.role.value},
            )
            raise PermissionError(
                f"Your account is registered as '{user.role.value}', "
                f"not '{requested_role}'. Please select the correct role."
            )

        # Update last login
        user.last_login_at = datetime.now(timezone.utc)
        db.session.commit()

        additional_claims = {
            "role": user.role.value,
            "username": user.username,
            "full_name": user.full_name,
        }
        access_token = create_access_token(identity=str(user.id), additional_claims=additional_claims)
        refresh_token = create_refresh_token(identity=str(user.id), additional_claims=additional_claims)

        AuthService._log(user.id, "LOGIN_SUCCESS", "user", user.id, {"ip": ip})
        return user, access_token, refresh_token

    @staticmethod
    def refresh_token(user_id: int, additional_claims: dict):
        """Issue a new access token from a valid refresh token."""
        user = User.query.get(user_id)
        if not user or user.status != AccountStatus.ACTIVE:
            raise PermissionError("Account not accessible.")
        claims = {
            "role": user.role.value,
            "username": user.username,
            "full_name": user.full_name,
        }
        access_token = create_access_token(identity=str(user_id), additional_claims=claims)
        return access_token

    @staticmethod
    def logout(jti: str, token_type: str, user_id: int):
        """Revoke a token by adding it to the blocklist."""
        entry = TokenBlocklist(jti=jti, token_type=token_type, user_id=user_id)
        db.session.add(entry)
        db.session.commit()
        AuthService._log(user_id, "LOGOUT", "user", user_id, {})

    @staticmethod
    def is_token_revoked(jwt_header, jwt_payload) -> bool:
        jti = jwt_payload["jti"]
        return db.session.query(TokenBlocklist.id).filter_by(jti=jti).scalar() is not None

    @staticmethod
    def _log(user_id, action, resource_type, resource_id, details):
        log = AuditLog(
            user_id=user_id,
            action=action,
            resource_type=resource_type,
            resource_id=resource_id,
            details=details,
        )
        db.session.add(log)
        db.session.commit()
