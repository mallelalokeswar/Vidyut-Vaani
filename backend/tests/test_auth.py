"""
Authentication tests — login, registration, role mismatch, logout, token refresh.
"""
import json
import pytest
from tests.conftest import login_as


class TestRegistration:
    def test_register_citizen_success(self, client, db):
        resp = client.post(
            "/api/auth/register",
            json={
                "full_name": "New Citizen",
                "email": "newcitizen@test.com",
                "username": "newcitizen",
                "password": "Secure@1234",
            },
        )
        assert resp.status_code == 201
        data = resp.get_json()
        assert data["user"]["role"] == "citizen"

    def test_register_duplicate_email(self, client, citizen_user):
        resp = client.post(
            "/api/auth/register",
            json={
                "full_name": "Dup",
                "email": "test_citizen@test.com",
                "username": "dup_citizen",
                "password": "Secure@1234",
            },
        )
        assert resp.status_code == 409

    def test_register_weak_password(self, client, db):
        resp = client.post(
            "/api/auth/register",
            json={
                "full_name": "Weak Pass",
                "email": "weak@test.com",
                "username": "weakuser",
                "password": "1234",
            },
        )
        assert resp.status_code == 422
        assert "errors" in resp.get_json()

    def test_register_missing_fields(self, client, db):
        resp = client.post("/api/auth/register", json={"email": "nofull@test.com"})
        assert resp.status_code == 422


class TestLogin:
    def test_login_citizen_success(self, client, citizen_user):
        resp = login_as(client, "test_citizen", "Test@1234", "citizen")
        assert resp.status_code == 200
        data = resp.get_json()
        assert "access_token" in data
        assert "refresh_token" in data
        assert data["user"]["role"] == "citizen"

    def test_login_admin_success(self, client, admin_user):
        resp = login_as(client, "test_admin", "Test@1234", "admin")
        assert resp.status_code == 200

    def test_login_operator_success(self, client, operator_user):
        resp = login_as(client, "test_operator", "Test@1234", "operator")
        assert resp.status_code == 200

    def test_login_wrong_password(self, client, citizen_user):
        resp = login_as(client, "test_citizen", "WrongPass!", "citizen")
        assert resp.status_code == 401

    def test_login_nonexistent_user(self, client, db):
        resp = login_as(client, "nobody", "Test@1234", "citizen")
        assert resp.status_code == 401

    def test_login_role_mismatch(self, client, citizen_user):
        """Citizen credentials with admin role — must be rejected."""
        resp = login_as(client, "test_citizen", "Test@1234", "admin")
        assert resp.status_code == 403
        body = resp.get_json()
        assert "citizen" in body["error"].lower() or "role" in body["error"].lower()

    def test_login_invalid_role(self, client, citizen_user):
        resp = client.post(
            "/api/auth/login",
            json={"identifier": "test_citizen", "password": "Test@1234", "role": "superuser"},
        )
        assert resp.status_code == 400

    def test_login_missing_role(self, client, citizen_user):
        resp = client.post(
            "/api/auth/login",
            json={"identifier": "test_citizen", "password": "Test@1234"},
        )
        assert resp.status_code == 400


class TestProtectedRoutes:
    def _get_token(self, client, user, role):
        resp = login_as(client, user.username, "Test@1234", role)
        return resp.get_json()["access_token"]

    def test_citizen_cannot_access_admin_dashboard(self, client, citizen_user):
        token = self._get_token(client, citizen_user, "citizen")
        resp = client.get(
            "/api/admin/dashboard",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 403

    def test_citizen_cannot_access_operator_dashboard(self, client, citizen_user):
        token = self._get_token(client, citizen_user, "citizen")
        resp = client.get(
            "/api/operator/dashboard",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 403

    def test_admin_cannot_access_operator_dashboard(self, client, admin_user):
        token = self._get_token(client, admin_user, "admin")
        resp = client.get(
            "/api/operator/dashboard",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 403

    def test_unauthenticated_citizen_dashboard(self, client, db):
        resp = client.get("/api/citizen/dashboard")
        assert resp.status_code == 401

    def test_unauthenticated_admin_dashboard(self, client, db):
        resp = client.get("/api/admin/dashboard")
        assert resp.status_code == 401

    def test_citizen_accesses_own_dashboard(self, client, citizen_user):
        token = self._get_token(client, citizen_user, "citizen")
        resp = client.get(
            "/api/citizen/dashboard",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200

    def test_admin_accesses_own_dashboard(self, client, admin_user):
        token = self._get_token(client, admin_user, "admin")
        resp = client.get(
            "/api/admin/dashboard",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200

    def test_operator_accesses_own_dashboard(self, client, operator_user):
        token = self._get_token(client, operator_user, "operator")
        resp = client.get(
            "/api/operator/dashboard",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200


class TestLogout:
    def test_logout_revokes_token(self, client, citizen_user):
        login_resp = login_as(client, "test_citizen", "Test@1234", "citizen")
        access_token = login_resp.get_json()["access_token"]

        # Logout
        logout_resp = client.delete(
            "/api/auth/logout",
            headers={"Authorization": f"Bearer {access_token}"},
        )
        assert logout_resp.status_code == 200

        # Token should now be rejected
        after_resp = client.get(
            "/api/auth/me",
            headers={"Authorization": f"Bearer {access_token}"},
        )
        assert after_resp.status_code == 401


class TestTokenRefresh:
    def test_refresh_issues_new_access_token(self, client, citizen_user):
        login_resp = login_as(client, "test_citizen", "Test@1234", "citizen")
        refresh_token = login_resp.get_json()["refresh_token"]

        refresh_resp = client.post(
            "/api/auth/refresh",
            headers={"Authorization": f"Bearer {refresh_token}"},
        )
        assert refresh_resp.status_code == 200
        assert "access_token" in refresh_resp.get_json()

    def test_expired_access_token_is_rejected(self, app, client, citizen_user):
        from datetime import timedelta
        from flask_jwt_extended import create_access_token

        with app.app_context():
            expired_token = create_access_token(
                identity=str(citizen_user.id),
                additional_claims={"role": "citizen"},
                expires_delta=timedelta(seconds=-1),
            )

        resp = client.get(
            "/api/citizen/dashboard",
            headers={"Authorization": f"Bearer {expired_token}"},
        )
        assert resp.status_code == 401
        assert resp.get_json()["error"] == "Token expired"


class TestAdminUserCreation:
    def test_admin_can_create_operator(self, client, admin_user):
        login_resp = login_as(client, "test_admin", "Test@1234", "admin")
        token = login_resp.get_json()["access_token"]

        resp = client.post(
            "/api/admin/users",
            headers={"Authorization": f"Bearer {token}"},
            json={
                "full_name": "Field Operator Two",
                "email": "op2@vidyutvaani.in",
                "username": "operator2",
                "password": "Operator@1234",
                "role": "operator",
                "locality": "Sector 4",
            },
        )
        assert resp.status_code == 201
        data = resp.get_json()
        assert data["user"]["role"] == "operator"
        assert data["user"]["username"] == "operator2"

    def test_citizen_cannot_create_operator(self, client, citizen_user):
        login_resp = login_as(client, "test_citizen", "Test@1234", "citizen")
        token = login_resp.get_json()["access_token"]

        resp = client.post(
            "/api/admin/users",
            headers={"Authorization": f"Bearer {token}"},
            json={
                "full_name": "Unauthorized Op",
                "email": "unauth_op@test.com",
                "username": "unauth_op",
                "password": "Operator@1234",
                "role": "operator",
            },
        )
        assert resp.status_code == 403
