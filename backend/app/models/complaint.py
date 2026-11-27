"""
Complaint model for electricity outage reports.
"""
from datetime import datetime, timezone
from enum import Enum as PyEnum
from app import db


class ComplaintStatus(str, PyEnum):
    PENDING = "pending"
    ASSIGNED = "assigned"
    IN_PROGRESS = "in_progress"
    RESOLVED = "resolved"
    CLOSED = "closed"
    REJECTED = "rejected"


class ComplaintPriority(str, PyEnum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


class Complaint(db.Model):
    __tablename__ = "complaints"

    id = db.Column(db.Integer, primary_key=True)
    complaint_number = db.Column(db.String(20), unique=True, nullable=False)
    title = db.Column(db.String(255), nullable=False)
    description = db.Column(db.Text, nullable=False)
    locality = db.Column(db.String(200), nullable=False)
    landmark = db.Column(db.String(200), nullable=True)
    latitude = db.Column(db.Float, nullable=True)
    longitude = db.Column(db.Float, nullable=True)
    status = db.Column(
        db.Enum(ComplaintStatus, name="complaint_status"),
        nullable=False,
        default=ComplaintStatus.PENDING,
    )
    priority = db.Column(
        db.Enum(ComplaintPriority, name="complaint_priority"),
        nullable=False,
        default=ComplaintPriority.MEDIUM,
    )
    # Foreign keys
    reporter_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    assigned_operator_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=True)
    # Timestamps
    created_at = db.Column(
        db.DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False
    )
    updated_at = db.Column(
        db.DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )
    resolved_at = db.Column(db.DateTime(timezone=True), nullable=True)
    estimated_restoration = db.Column(db.DateTime(timezone=True), nullable=True)
    resolution_notes = db.Column(db.Text, nullable=True)

    # Relationships
    reporter = db.relationship("User", foreign_keys=[reporter_id], back_populates="complaints")
    assigned_operator = db.relationship("User", foreign_keys=[assigned_operator_id])

    def to_dict(self):
        return {
            "id": self.id,
            "complaint_number": self.complaint_number,
            "title": self.title,
            "description": self.description,
            "locality": self.locality,
            "landmark": self.landmark,
            "latitude": self.latitude,
            "longitude": self.longitude,
            "status": self.status.value,
            "priority": self.priority.value,
            "reporter_id": self.reporter_id,
            "assigned_operator_id": self.assigned_operator_id,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
            "resolved_at": self.resolved_at.isoformat() if self.resolved_at else None,
            "estimated_restoration": (
                self.estimated_restoration.isoformat()
                if self.estimated_restoration
                else None
            ),
            "resolution_notes": self.resolution_notes,
        }
