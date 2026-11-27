"""
Pytest configuration and shared fixtures.
"""
import pytest
from app import create_app, db as _db
from app.models.user import User, UserRole, AccountStatus
from app import bcrypt


@pytest.fixture(scope="session")
def app():
    application = create_app("testing")
    with application.app_context():
        _db.create_all()
        yield application
        _db.drop_all()


@pytest.fixture(scope="function")
def db(app):
    """Provide a clean database per test."""
    with app.app_context():
        yield _db
        _db.session.remove()
        # Truncate all tables between tests
        for table in reversed(_db.metadata.sorted_tables):
            _db.session.execute(table.delete())
        _db.session.commit()


@pytest.fixture
def client(app):
    return app.test_client()


def _make_user(db, role: UserRole, username: str, password: str = "Test@1234"):
    hashed = bcrypt.generate_password_hash(password).decode("utf-8")
    user = User(
        full_name=f"Test {role.value.title()}",
        email=f"{username}@test.com",
        username=username,
        password_hash=hashed,
        role=role,
        status=AccountStatus.ACTIVE,
    )
    db.session.add(user)
    db.session.commit()
    return user


@pytest.fixture
def citizen_user(db):
    return _make_user(db, UserRole.CITIZEN, "test_citizen")


@pytest.fixture
def admin_user(db):
    return _make_user(db, UserRole.ADMIN, "test_admin")


@pytest.fixture
def operator_user(db):
    return _make_user(db, UserRole.OPERATOR, "test_operator")


def login_as(client, identifier, password, role):
    return client.post(
        "/api/auth/login",
        json={"identifier": identifier, "password": password, "role": role},
    )
