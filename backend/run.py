"""
Application entry point.
"""
import os
from app import create_app, db
from app.models.user import User, UserRole, AccountStatus
from app import bcrypt

app = create_app(os.getenv("FLASK_ENV", "development"))


@app.cli.command("seed-admin")
def seed_admin():
    """Create the initial admin account (run once after migrations)."""
    with app.app_context():
        if User.query.filter_by(username="admin").first():
            print("Admin already exists.")
            return
        hashed = bcrypt.generate_password_hash("Admin@1234").decode("utf-8")
        admin = User(
            full_name="System Administrator",
            email="admin@vidyutvaani.in",
            username="admin",
            password_hash=hashed,
            role=UserRole.ADMIN,
            status=AccountStatus.ACTIVE,
        )
        db.session.add(admin)
        db.session.commit()
        print("Admin user created: username=admin, password=Admin@1234")


@app.cli.command("seed-operator")
def seed_operator():
    """Create a sample field operator account."""
    with app.app_context():
        if User.query.filter_by(username="operator1").first():
            print("Operator already exists.")
            return
        hashed = bcrypt.generate_password_hash("Operator@1234").decode("utf-8")
        op = User(
            full_name="Field Operator One",
            email="operator1@vidyutvaani.in",
            username="operator1",
            password_hash=hashed,
            role=UserRole.OPERATOR,
            status=AccountStatus.ACTIVE,
        )
        db.session.add(op)
        db.session.commit()
        print("Operator created: username=operator1, password=Operator@1234")


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
