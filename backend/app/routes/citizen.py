"""
Citizen-facing routes.
"""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.services.complaint_service import ComplaintService
from app.utils.decorators import citizen_required
from app.utils.validators import paginated_response

citizen_bp = Blueprint("citizen", __name__)


@citizen_bp.route("/dashboard", methods=["GET"])
@citizen_required
def dashboard():
    """Return summary data for the citizen dashboard."""
    user_id = int(get_jwt_identity())
    pagination = ComplaintService.get_citizen_complaints(user_id, page=1, per_page=5)
    stats = {
        "my_complaints": pagination.total,
        "pending": sum(
            1 for c in pagination.items if c.status.value == "pending"
        ),
        "resolved": sum(
            1 for c in pagination.items if c.status.value == "resolved"
        ),
    }
    return jsonify(
        {
            "summary": stats,
            "recent_complaints": [c.to_dict() for c in pagination.items],
        }
    ), 200


@citizen_bp.route("/complaints", methods=["GET"])
@citizen_required
def list_complaints():
    user_id = int(get_jwt_identity())
    page = request.args.get("page", 1, type=int)
    per_page = request.args.get("per_page", 20, type=int)
    pagination = ComplaintService.get_citizen_complaints(user_id, page=page, per_page=per_page)
    return jsonify(paginated_response(pagination, "complaints")), 200


@citizen_bp.route("/complaints", methods=["POST"])
@citizen_required
def create_complaint():
    user_id = int(get_jwt_identity())
    data = request.get_json(silent=True) or {}
    errors = []
    if not data.get("title", "").strip():
        errors.append("Complaint title is required.")
    if not data.get("description", "").strip():
        errors.append("Description is required.")
    if not data.get("locality", "").strip():
        errors.append("Locality is required.")
    if errors:
        return jsonify({"errors": errors}), 422
    complaint = ComplaintService.create_complaint(user_id, data)
    return jsonify({"message": "Complaint submitted.", "complaint": complaint.to_dict()}), 201


@citizen_bp.route("/complaints/<int:complaint_id>", methods=["GET"])
@citizen_required
def get_complaint(complaint_id):
    user_id = int(get_jwt_identity())
    from app.models.complaint import Complaint
    complaint = Complaint.query.get_or_404(complaint_id)
    if complaint.reporter_id != user_id:
        return jsonify({"error": "Forbidden"}), 403
    return jsonify({"complaint": complaint.to_dict()}), 200


@citizen_bp.route("/schemes", methods=["GET"])
@citizen_required
def list_schemes():
    """Return active electricity subsidy schemes for citizens."""
    from app.models.scheme import Scheme
    schemes = Scheme.query.filter_by(is_active=True).order_by(Scheme.created_at.desc()).all()
    return jsonify({"schemes": [s.to_dict() for s in schemes]}), 200
