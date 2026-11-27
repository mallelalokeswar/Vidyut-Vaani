"""
Complaint service — CRUD and status management.
"""
import random
import string
from datetime import datetime, timezone
from app import db
from app.models.complaint import Complaint, ComplaintStatus, ComplaintPriority
from app.models.audit_log import AuditLog


def _generate_complaint_number():
    chars = string.ascii_uppercase + string.digits
    suffix = "".join(random.choices(chars, k=6))
    return f"VV-{datetime.now(timezone.utc).strftime('%Y%m')}-{suffix}"


class ComplaintService:

    @staticmethod
    def create_complaint(reporter_id: int, data: dict) -> Complaint:
        complaint = Complaint(
            complaint_number=_generate_complaint_number(),
            title=data["title"],
            description=data["description"],
            locality=data["locality"],
            landmark=data.get("landmark"),
            latitude=data.get("latitude"),
            longitude=data.get("longitude"),
            priority=ComplaintPriority(data.get("priority", "medium")),
            reporter_id=reporter_id,
        )
        db.session.add(complaint)
        db.session.commit()
        return complaint

    @staticmethod
    def get_citizen_complaints(reporter_id: int, page: int = 1, per_page: int = 20):
        return Complaint.query.filter_by(reporter_id=reporter_id).paginate(
            page=page, per_page=per_page, error_out=False
        )

    @staticmethod
    def get_operator_complaints(operator_id: int, page: int = 1, per_page: int = 20):
        return Complaint.query.filter_by(assigned_operator_id=operator_id).paginate(
            page=page, per_page=per_page, error_out=False
        )

    @staticmethod
    def get_all_complaints(page: int = 1, per_page: int = 20, status: str = None):
        query = Complaint.query
        if status:
            query = query.filter_by(status=ComplaintStatus(status))
        return query.order_by(Complaint.created_at.desc()).paginate(
            page=page, per_page=per_page, error_out=False
        )

    @staticmethod
    def update_complaint_status(
        complaint_id: int,
        new_status: str,
        updated_by_id: int,
        resolution_notes: str = None,
        estimated_restoration: datetime = None,
    ) -> Complaint:
        complaint = Complaint.query.get_or_404(complaint_id)
        old_status = complaint.status.value
        complaint.status = ComplaintStatus(new_status)
        if resolution_notes:
            complaint.resolution_notes = resolution_notes
        if estimated_restoration:
            complaint.estimated_restoration = estimated_restoration
        if new_status == "resolved":
            complaint.resolved_at = datetime.now(timezone.utc)
        db.session.commit()

        log = AuditLog(
            user_id=updated_by_id,
            action="COMPLAINT_STATUS_UPDATE",
            resource_type="complaint",
            resource_id=complaint_id,
            details={"from": old_status, "to": new_status},
        )
        db.session.add(log)
        db.session.commit()
        return complaint

    @staticmethod
    def assign_operator(complaint_id: int, operator_id: int, assigned_by_id: int) -> Complaint:
        complaint = Complaint.query.get_or_404(complaint_id)
        complaint.assigned_operator_id = operator_id
        complaint.status = ComplaintStatus.ASSIGNED
        db.session.commit()
        return complaint

    @staticmethod
    def get_stats() -> dict:
        total = Complaint.query.count()
        pending = Complaint.query.filter_by(status=ComplaintStatus.PENDING).count()
        in_progress = Complaint.query.filter_by(status=ComplaintStatus.IN_PROGRESS).count()
        resolved = Complaint.query.filter_by(status=ComplaintStatus.RESOLVED).count()
        active_outages = Complaint.query.filter(
            Complaint.status.in_([ComplaintStatus.PENDING, ComplaintStatus.IN_PROGRESS])
        ).count()
        return {
            "total": total,
            "pending": pending,
            "in_progress": in_progress,
            "resolved": resolved,
            "active_outages": active_outages,
        }
