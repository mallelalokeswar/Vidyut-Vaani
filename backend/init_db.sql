"""
Database init SQL — run before Flask-Migrate if Postgres role doesn't exist.
"""
-- Create role and database (run as postgres superuser)
-- psql -U postgres -f init_db.sql

CREATE ROLE vidyut_user WITH LOGIN PASSWORD 'vidyut_pass';
CREATE DATABASE vidyut_vaani OWNER vidyut_user;
CREATE DATABASE vidyut_vaani_test OWNER vidyut_user;
GRANT ALL PRIVILEGES ON DATABASE vidyut_vaani TO vidyut_user;
GRANT ALL PRIVILEGES ON DATABASE vidyut_vaani_test TO vidyut_user;
