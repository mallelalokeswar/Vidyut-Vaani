"""
VidyuthVaani Flask Application Factory
"""
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from flask_jwt_extended import JWTManager
from flask_cors import CORS
from flask_bcrypt import Bcrypt

db = SQLAlchemy()
migrate = Migrate()
jwt = JWTManager()
bcrypt = Bcrypt()


def create_app(config_name: str = "development") -> Flask:
    """Create and configure the Flask application."""
    app = Flask(__name__)

    # Load configuration
    from app.config import config_map
    app.config.from_object(config_map[config_name])
    if config_name == "production" and not app.config.get("SQLALCHEMY_DATABASE_URI"):
        raise ValueError("DATABASE_URL environment variable is required in production.")

    # Initialize extensions
    db.init_app(app)
    migrate.init_app(app, db)
    jwt.init_app(app)
    bcrypt.init_app(app)
    CORS(app, resources={r"/api/*": {"origins": "*"}}, supports_credentials=True)

    # Register JWT token-revocation check
    from app.services.auth_service import AuthService

    @jwt.token_in_blocklist_loader
    def check_if_token_revoked(jwt_header, jwt_payload):
        return AuthService.is_token_revoked(jwt_header, jwt_payload)

    # Register models so migrations can detect them
    from app.models import user, complaint, scheme, audit_log, token_blocklist  # noqa: F401

    # Register blueprints
    from app.routes.auth import auth_bp
    from app.routes.citizen import citizen_bp
    from app.routes.admin import admin_bp
    from app.routes.operator import operator_bp
    from app.routes.health import health_bp

    app.register_blueprint(health_bp, url_prefix="/api/health")
    app.register_blueprint(auth_bp, url_prefix="/api/auth")
    app.register_blueprint(citizen_bp, url_prefix="/api/citizen")
    app.register_blueprint(admin_bp, url_prefix="/api/admin")
    app.register_blueprint(operator_bp, url_prefix="/api/operator")

    # JWT error handlers
    @jwt.invalid_token_loader
    def invalid_token_callback(error):
        return {"error": "Invalid token", "message": str(error)}, 401

    @jwt.expired_token_loader
    def expired_token_callback(jwt_header, jwt_data):
        return {"error": "Token expired", "message": "Please log in again."}, 401

    @jwt.unauthorized_loader
    def missing_token_callback(error):
        return {"error": "Unauthorized", "message": "Authentication token required."}, 401

    @jwt.revoked_token_loader
    def revoked_token_callback(jwt_header, jwt_data):
        return {"error": "Token revoked", "message": "Token has been revoked."}, 401

    return app
