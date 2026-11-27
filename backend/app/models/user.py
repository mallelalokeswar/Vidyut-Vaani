"""
User model with role-based access control.
"""
from datetime import datetime, timezone
from enum import Enum as PyEnum
from app import db


class UserRole(str, PyEnum):
    """
    Supported roles.  Add new roles here — the rest of the
    system (guards, JWT claims) picks them up automatically.
    """
    CITIZEN = "citizen"
    ADMIN = "admin"
    OPERATOR = "operator"


class AccountStatus(str, PyEnum):
    ACTIVE = "active"
    INACTIVE = "inactive"
    SUSPENDED = "suspended"
    PENDING_VERIFICATION = "pending_verification"


class User(db.Model):
    __tablename__ = "users"

    id = db.Column(db.Integer, primary_key=True)
    full_name = db.Column(db.String(150), nullable=False)
    email = db.Column(db.String(255), unique=True, nullable=False, index=True)
    username = db.Column(db.String(80), unique=True, nullable=False, index=True)
    password_hash = db.Column(db.String(255), nullable=False)
    role = db.Column(
        db.Enum(UserRole, name="user_role"),
        nullable=False,
        default=UserRole.CITIZEN,
    )
    status = db.Column(
        db.Enum(AccountStatus, name="account_status"),
        nullable=False,
        default=AccountStatus.ACTIVE,
    )
    phone = db.Column(db.String(20), nullable=True)
    locality = db.Column(db.String(200), nullable=True)
    meter_number = db.Column(db.String(50), nullable=True)
    profile_picture_url = db.Column(db.String(500), nullable=True)
    is_email_verified = db.Column(db.Boolean, default=False, nullable=False)
    last_login_at = db.Column(db.DateTime(timezone=True), nullable=True)
    created_at = db.Column(
        db.DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False
    )
    updated_at = db.Column(
        db.DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    # Relationships
    complaints = db.relationship(
        "Complaint",
        foreign_keys="Complaint.reporter_id",
        back_populates="reporter",
        lazy="dynamic",
    )
    audit_logs = db.relationship("AuditLog", back_populates="user", lazy="dynamic")

    def __repr__(self):
        return f"<User {self.username} ({self.role.value})>"

    def to_dict(self):
        return {
            "id": self.id,
            "full_name": self.full_name,
            "email": self.email,
            "username": self.username,
            "role": self.role.value,
            "status": self.status.value,
            "phone": self.phone,
            "locality": self.locality,
            "meter_number": self.meter_number,
            "is_email_verified": self.is_email_verified,
            "last_login_at": self.last_login_at.isoformat() if self.last_login_at else None,
            "created_at": self.created_at.isoformat(),
        }
