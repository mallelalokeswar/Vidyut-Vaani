"""
Package init — import all models for Flask-Migrate auto-detection.
"""
from app.models.user import User, UserRole, AccountStatus  # noqa: F401
from app.models.complaint import Complaint, ComplaintStatus, ComplaintPriority  # noqa: F401
from app.models.scheme import Scheme  # noqa: F401
from app.models.audit_log import AuditLog  # noqa: F401
from app.models.token_blocklist import TokenBlocklist  # noqa: F401
