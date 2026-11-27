"""
Field operator routes.
"""
from datetime import datetime
from flask import Blueprint, request, jsonify
from flask_jwt_extended import get_jwt_identity
from app.utils.decorators import operator_required
from app.utils.validators import paginated_response
from app.services.complaint_service import ComplaintService

operator_bp = Blueprint("operator", __name__)

ALLOWED_STATUSES = {"in_progress", "resolved", "closed"}


@operator_bp.route("/dashboard", methods=["GET"])
@operator_required
def dashboard():
    user_id = int(get_jwt_identity())
    pagination = ComplaintService.get_operator_complaints(user_id, page=1, per_page=5)
    return jsonify(
        {
            "assigned_complaints": pagination.total,
            "recent": [c.to_dict() for c in pagination.items],
        }
    ), 200


@operator_bp.route("/complaints", methods=["GET"])
@operator_required
def list_complaints():
    user_id = int(get_jwt_identity())
    page = request.args.get("page", 1, type=int)
    per_page = request.args.get("per_page", 20, type=int)
    pagination = ComplaintService.get_operator_complaints(user_id, page=page, per_page=per_page)
    return jsonify(paginated_response(pagination, "complaints")), 200


@operator_bp.route("/complaints/<int:complaint_id>/status", methods=["PATCH"])
@operator_required
def update_status(complaint_id):
    from app.models.complaint import Complaint
    user_id = int(get_jwt_identity())
    data = request.get_json(silent=True) or {}
    new_status = data.get("status", "")
    if new_status not in ALLOWED_STATUSES:
        return jsonify({"error": f"Operators may only set status to: {', '.join(ALLOWED_STATUSES)}."}), 400

    # Ensure operator owns this complaint
    complaint = Complaint.query.get_or_404(complaint_id)
    if complaint.assigned_operator_id != user_id:
        return jsonify({"error": "You are not assigned to this complaint."}), 403

    est_restoration = None
    if data.get("estimated_restoration"):
        try:
            est_restoration = datetime.fromisoformat(data["estimated_restoration"])
        except ValueError:
            return jsonify({"error": "Invalid estimated_restoration ISO datetime."}), 400

    updated = ComplaintService.update_complaint_status(
        complaint_id=complaint_id,
        new_status=new_status,
        updated_by_id=user_id,
        resolution_notes=data.get("resolution_notes"),
        estimated_restoration=est_restoration,
    )
    return jsonify({"message": "Status updated.", "complaint": updated.to_dict()}), 200
