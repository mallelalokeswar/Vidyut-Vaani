"""
Admin routes — user management, complaint oversight, scheme management, stats.
"""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import get_jwt_identity
from app.utils.decorators import admin_required
from app.utils.validators import (
    paginated_response,
    validate_email,
    validate_username,
    validate_password_strength,
)
from app.services.complaint_service import ComplaintService
from app import db, bcrypt

admin_bp = Blueprint("admin", __name__)


@admin_bp.route("/dashboard", methods=["GET"])
@admin_required
def dashboard():
    from app.models.user import User
    complaint_stats = ComplaintService.get_stats()
    total_users = User.query.count()
    return jsonify(
        {
            "total_users": total_users,
            "complaints": complaint_stats,
        }
    ), 200


@admin_bp.route("/users", methods=["GET"])
@admin_required
def list_users():
    from app.models.user import User
    page = request.args.get("page", 1, type=int)
    per_page = request.args.get("per_page", 20, type=int)
    role_filter = request.args.get("role")
    query = User.query
    if role_filter:
        query = query.filter_by(role=role_filter)
    pagination = query.order_by(User.created_at.desc()).paginate(
        page=page, per_page=per_page, error_out=False
    )
    return jsonify(paginated_response(pagination, "users")), 200


@admin_bp.route("/users", methods=["POST"])
@admin_required
def create_user():
    """Admin endpoint to create a new Field Operator, Admin, or Citizen account."""
    from app.models.user import User, UserRole, AccountStatus
    from app.models.audit_log import AuditLog

    admin_id = int(get_jwt_identity())
    data = request.get_json(silent=True) or {}

    full_name = (data.get("full_name") or "").strip()
    email = (data.get("email") or "").strip().lower()
    username = (data.get("username") or "").strip().lower()
    password = data.get("password") or ""
    role_str = (data.get("role") or "operator").strip().lower()

    errors = []
    if not full_name:
        errors.append("Full name is required.")
    if not validate_email(email):
        errors.append("A valid email address is required.")
    if not validate_username(username):
        errors.append("Username must be 3-30 alphanumeric characters or underscores.")
    errors.extend(validate_password_strength(password))
    try:
        role_enum = UserRole(role_str)
    except ValueError:
        errors.append(f"Invalid role '{role_str}'.")

    if errors:
        return jsonify({"error": " ".join(errors), "errors": errors}), 422

    if User.query.filter_by(email=email).first():
        return jsonify({"error": "An account with this email already exists."}), 409
    if User.query.filter_by(username=username).first():
        return jsonify({"error": "This username is already taken."}), 409

    hashed = bcrypt.generate_password_hash(password).decode("utf-8")
    user = User(
        full_name=full_name,
        email=email,
        username=username,
        password_hash=hashed,
        role=role_enum,
        status=AccountStatus.ACTIVE,
        phone=data.get("phone"),
        locality=data.get("locality"),
    )
    db.session.add(user)
    db.session.commit()

    log = AuditLog(
        user_id=admin_id,
        action="USER_CREATED",
        resource_type="user",
        resource_id=user.id,
        details={"username": user.username, "role": user.role.value},
    )
    db.session.add(log)
    db.session.commit()

    return jsonify({"message": "User created.", "user": user.to_dict()}), 201


@admin_bp.route("/users/<int:user_id>", methods=["GET"])
@admin_required
def get_user(user_id):
    from app.models.user import User
    user = User.query.get_or_404(user_id)
    return jsonify({"user": user.to_dict()}), 200


@admin_bp.route("/users/<int:user_id>/status", methods=["PATCH"])
@admin_required
def update_user_status(user_id):
    from app.models.user import User, AccountStatus
    from app.models.audit_log import AuditLog
    admin_id = int(get_jwt_identity())
    data = request.get_json(silent=True) or {}
    new_status = data.get("status")
    try:
        status_enum = AccountStatus(new_status)
    except (ValueError, KeyError):
        return jsonify({"error": f"Invalid status '{new_status}'."}), 400
    user = User.query.get_or_404(user_id)
    old_status = user.status.value
    user.status = status_enum
    db.session.commit()
    log = AuditLog(
        user_id=admin_id,
        action="USER_STATUS_UPDATE",
        resource_type="user",
        resource_id=user_id,
        details={"from": old_status, "to": new_status},
    )
    db.session.add(log)
    db.session.commit()
    return jsonify({"message": "User status updated.", "user": user.to_dict()}), 200


@admin_bp.route("/complaints", methods=["GET"])
@admin_required
def list_complaints():
    page = request.args.get("page", 1, type=int)
    per_page = request.args.get("per_page", 20, type=int)
    status = request.args.get("status")
    pagination = ComplaintService.get_all_complaints(page=page, per_page=per_page, status=status)
    return jsonify(paginated_response(pagination, "complaints")), 200


@admin_bp.route("/complaints/<int:complaint_id>/assign", methods=["PATCH"])
@admin_required
def assign_complaint(complaint_id):
    admin_id = int(get_jwt_identity())
    data = request.get_json(silent=True) or {}
    operator_id = data.get("operator_id")
    if not operator_id:
        return jsonify({"error": "operator_id is required."}), 400
    complaint = ComplaintService.assign_operator(complaint_id, operator_id, admin_id)
    return jsonify({"message": "Complaint assigned.", "complaint": complaint.to_dict()}), 200


@admin_bp.route("/schemes", methods=["GET"])
@admin_required
def list_schemes():
    from app.models.scheme import Scheme
    schemes = Scheme.query.all()
    return jsonify({"schemes": [s.to_dict() for s in schemes]}), 200


@admin_bp.route("/schemes", methods=["POST"])
@admin_required
def create_scheme():
    from app.models.scheme import Scheme
    admin_id = int(get_jwt_identity())
    data = request.get_json(silent=True) or {}
    if not data.get("name") or not data.get("description"):
        return jsonify({"error": "name and description are required."}), 422
    scheme = Scheme(
        name=data["name"],
        description=data["description"],
        eligibility_criteria=data.get("eligibility_criteria"),
        benefits=data.get("benefits"),
        application_process=data.get("application_process"),
        created_by_id=admin_id,
    )
    db.session.add(scheme)
    db.session.commit()
    return jsonify({"message": "Scheme created.", "scheme": scheme.to_dict()}), 201


@admin_bp.route("/audit-logs", methods=["GET"])
@admin_required
def audit_logs():
    from app.models.audit_log import AuditLog
    page = request.args.get("page", 1, type=int)
    per_page = request.args.get("per_page", 50, type=int)
    pagination = AuditLog.query.order_by(AuditLog.created_at.desc()).paginate(
        page=page, per_page=per_page, error_out=False
    )
    return jsonify(paginated_response(pagination, "logs")), 200
