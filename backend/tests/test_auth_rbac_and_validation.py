import pytest
import uuid
from fastapi.testclient import TestClient
from app.main import app
from app.db.session import SessionLocal
from app.db.models import User, Role
from app.repositories.user_repository import UserRepository
from app.models.schemas import RiskLevel

client = TestClient(app)


@pytest.fixture(scope="module")
def db_session():
    db = SessionLocal()
    UserRepository.seed_standard_roles(db)
    yield db
    db.close()


def test_auth_registration_and_validation():
    # 1. Invalid email
    res = client.post("/auth/register", json={
        "name": "Test User",
        "email": "not-an-email",
        "password": "Password123!"
    })
    assert res.status_code == 400
    assert "Invalid email" in res.json()["detail"]

    # 2. Too short password
    res = client.post("/auth/register", json={
        "name": "Test User",
        "email": "valid@mausam.in",
        "password": "123"
    })
    assert res.status_code == 400
    assert "at least 6 characters" in res.json()["detail"]

    # 3. Successful registration
    unique_email = f"user_{uuid.uuid4().hex[:6]}@mausam.in"
    res = client.post("/auth/register", json={
        "name": "Operations Lead",
        "email": unique_email,
        "password": "SecurePassword123!",
        "organization": "Infra Concrete Corp",
        "role_id": "rmc"
    })
    assert res.status_code == 201
    data = res.json()
    assert "access_token" in data
    assert data["user"]["email"] == unique_email
    assert any(r["id"] == "rmc" for r in data["user"]["roles"])

    # 4. Duplicate email rejection
    res_dup = client.post("/auth/register", json={
        "name": "Operations Lead",
        "email": unique_email,
        "password": "SecurePassword123!"
    })
    assert res_dup.status_code == 400
    assert "already exists" in res_dup.json()["detail"]


def test_auth_login_and_session():
    unique_email = f"logintest_{uuid.uuid4().hex[:6]}@mausam.in"
    reg_res = client.post("/auth/register", json={
        "name": "Dispatcher Guy",
        "email": unique_email,
        "password": "MySecretPassword2026!",
        "role_id": "rmc"
    })
    assert reg_res.status_code == 201

    # Invalid password login
    res_bad = client.post("/auth/login", json={
        "email": unique_email,
        "password": "WrongPassword!"
    })
    assert res_bad.status_code == 401

    # Nonexistent user login
    res_none = client.post("/auth/login", json={
        "email": "doesnotexist@mausam.in",
        "password": "SomePassword!"
    })
    assert res_none.status_code == 401

    # Valid login
    res_good = client.post("/auth/login", json={
        "email": unique_email,
        "password": "MySecretPassword2026!"
    })
    assert res_good.status_code == 200
    data = res_good.json()
    token = data["access_token"]
    assert token is not None

    # Authenticated /auth/me
    headers = {"Authorization": f"Bearer {token}"}
    me_res = client.get("/auth/me", headers=headers)
    assert me_res.status_code == 200
    assert me_res.json()["email"] == unique_email

    # Logout
    logout_res = client.post("/auth/logout", headers=headers)
    assert logout_res.status_code == 200
    assert logout_res.json()["status"] == "success"


def test_rbac_protection():
    # 1. Unauthenticated request to /deliveries
    res_unauth = client.get("/deliveries")
    assert res_unauth.status_code == 401

    # 2. Register user with ONLY "health" role (NOT rmc)
    health_email = f"health_{uuid.uuid4().hex[:6]}@mausam.in"
    reg_res = client.post("/auth/register", json={
        "name": "Health User",
        "email": health_email,
        "password": "HealthPassword123!",
        "role_id": "health"
    })
    health_token = reg_res.json()["access_token"]
    health_headers = {"Authorization": f"Bearer {health_token}"}

    # 3. Health user calling protected RMC endpoint must be rejected with 403 Forbidden
    res_forbidden = client.get("/deliveries", headers=health_headers)
    assert res_forbidden.status_code == 403
    assert "requires the 'rmc' role" in res_forbidden.json()["detail"]

    # 4. Register user with "rmc" role
    rmc_email = f"rmc_{uuid.uuid4().hex[:6]}@mausam.in"
    reg_rmc = client.post("/auth/register", json={
        "name": "RMC Manager",
        "email": rmc_email,
        "password": "RmcPassword123!",
        "role_id": "rmc"
    })
    rmc_token = reg_rmc.json()["access_token"]
    rmc_headers = {"Authorization": f"Bearer {rmc_token}"}

    # 5. RMC user accessing /deliveries is authorized
    res_auth = client.get("/deliveries", headers=rmc_headers)
    assert res_auth.status_code == 200


def test_delivery_creation_and_risk_persistence():
    # Login as seeded user
    res_login = client.post("/auth/login", json={
        "email": "rmc.demo@mausam.local",
        "password": "RmcManager2026!"
    })
    token = res_login.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Create real delivery
    deliv_code = f"TEST-{uuid.uuid4().hex[:4].upper()}"
    create_payload = {
        "batch_code": deliv_code,
        "plant_name": "Ahmedabad Central Batching Plant",
        "project_name": "GIFT City Tower B",
        "concrete_grade": "M35",
        "volume_m3": 6.0,
        "initial_slump_mm": 110.0,
        "target_slump_mm": 105.0,
        "planned_transit_minutes": 50.0
    }
    create_res = client.post("/deliveries", json=create_payload, headers=headers)
    assert create_res.status_code == 200
    deliv_data = create_res.json()
    batch_id = deliv_data["batch_id"]
    assert deliv_data["batch_code"] == deliv_code
    assert deliv_data["model_version"] == "GBR-RMC-v2.0"

    # Verify persisted delivery detail
    get_res = client.get(f"/deliveries/{batch_id}", headers=headers)
    assert get_res.status_code == 200
    assert get_res.json()["batch_code"] == deliv_code

    # Dispatch delivery
    dispatch_res = client.post(f"/deliveries/{batch_id}/dispatch", headers=headers)
    assert dispatch_res.status_code == 200
    assert dispatch_res.json()["status"] == "DISPATCHED"

    # Telemetry history
    telem_res = client.get(f"/deliveries/{batch_id}/telemetry", headers=headers)
    assert telem_res.status_code == 200
    assert len(telem_res.json()) >= 1

    # Record Outcome
    outcome_payload = {
        "batch_id": batch_id,
        "outcome": "accepted",
        "site_slump_mm": 104.0,
        "actual_transit_minutes": 48.0,
        "site_concrete_temp_c": 31.5
    }
    outcome_res = client.post(f"/deliveries/{batch_id}/outcome", json=outcome_payload, headers=headers)
    assert outcome_res.status_code == 200
    assert outcome_res.json()["outcome"] == "accepted"


def test_deterministic_rmc_scenarios_suite():
    # Admin model validation endpoint
    val_res = client.post("/admin/model-validation")
    assert val_res.status_code == 200
    val_data = val_res.json()
    assert val_data["suite_status"] == "ALL_PASSED"
    assert val_data["passed_count"] == 6
    assert val_data["failed_count"] == 0

    scenarios = {s["scenario_id"]: s for s in val_data["scenarios"]}

    # Scenario A: Safe
    assert scenarios["scenario_a_safe"]["actual"] == "SAFE"
    assert scenarios["scenario_a_safe"]["status"] == "PASS"

    # Scenario B: Long transit SLA breach (95m > 78m SLA)
    assert scenarios["scenario_b_long_transit"]["actual"] in ["HIGH_RISK", "CRITICAL"]
    assert scenarios["scenario_b_long_transit"]["actual"] != "SAFE"
    assert scenarios["scenario_b_long_transit"]["status"] == "PASS"

    # Scenario C: Low slump retention (88% < 92% SLA)
    assert scenarios["scenario_c_low_slump"]["actual"] in ["HIGH_RISK", "CRITICAL"]
    assert scenarios["scenario_c_low_slump"]["actual"] != "SAFE"
    assert scenarios["scenario_c_low_slump"]["status"] == "PASS"

    # Scenario D: High heat + long transit
    assert scenarios["scenario_d_high_heat_long_transit"]["actual"] in ["HIGH_RISK", "CRITICAL"]
    assert scenarios["scenario_d_high_heat_long_transit"]["actual"] != "SAFE"
    assert scenarios["scenario_d_high_heat_long_transit"]["status"] == "PASS"

    # Scenario E: Multi-factor risk
    assert scenarios["scenario_e_multi_factor"]["actual"] in ["HIGH_RISK", "CRITICAL"]
    assert scenarios["scenario_e_multi_factor"]["actual"] != "SAFE"
    assert scenarios["scenario_e_multi_factor"]["status"] == "PASS"

    # Scenario F: Missing critical data
    assert scenarios["scenario_f_missing_data"]["actual"] == "RISK_UNAVAILABLE"
    assert scenarios["scenario_f_missing_data"]["actual"] != "SAFE"
    assert scenarios["scenario_f_missing_data"]["status"] == "PASS"


def test_new_account_data_isolation():
    """
    Verifies Section 1.8 Acceptance Tests:
    TEST A: Org A vs Org B isolation; User B starts with 0 deliveries.
    TEST B: User A creates delivery -> User A sees it, User B does not.
    TEST C: User B manually requests Delivery A -> 404 Not Found.
    TEST D: New account dashboard KPIs -> 0 active, 0 risk, 0 loss avoided.
    """
    org_a = f"Org-Alpha-{uuid.uuid4().hex[:4]}"
    org_b = f"Org-Beta-{uuid.uuid4().hex[:4]}"

    reg_a = client.post("/auth/register", json={
        "name": "User Alpha",
        "email": f"alpha-{uuid.uuid4().hex[:4]}@mausam.local",
        "password": "Password123!",
        "organization": org_a,
        "role_id": "rmc"
    })
    assert reg_a.status_code == 201
    token_a = reg_a.json()["access_token"]
    headers_a = {"Authorization": f"Bearer {token_a}"}

    reg_b = client.post("/auth/register", json={
        "name": "User Beta",
        "email": f"beta-{uuid.uuid4().hex[:4]}@mausam.local",
        "password": "Password123!",
        "organization": org_b,
        "role_id": "rmc"
    })
    assert reg_b.status_code == 201
    token_b = reg_b.json()["access_token"]
    headers_b = {"Authorization": f"Bearer {token_b}"}

    # TEST A & D: User B (brand new) sees 0 deliveries and 0 KPIs
    delivs_b_initial = client.get("/deliveries", headers=headers_b)
    assert delivs_b_initial.status_code == 200
    assert len(delivs_b_initial.json()) == 0

    kpis_b = client.get("/fleet/kpi", headers=headers_b)
    assert kpis_b.status_code == 200
    kpi_data = kpis_b.json()
    assert kpi_data["active_deliveries"] == 0
    assert kpi_data["high_risk_batches"] == 0
    assert kpi_data["loss_avoided_inr"] == 0.0

    # TEST B: User A creates a delivery
    deliv_code = f"ALPHA-{uuid.uuid4().hex[:4].upper()}"
    deliv_payload = {
        "batch_code": deliv_code,
        "plant_name": "Alpha Naroda Hub",
        "project_name": "Alpha Riverfront Tower",
        "concrete_grade": "M35",
        "volume_m3": 6.0,
        "initial_slump_mm": 110.0,
        "target_slump_mm": 105.0
    }
    create_a = client.post("/deliveries", json=deliv_payload, headers=headers_a)
    assert create_a.status_code == 200
    batch_a_id = create_a.json()["batch_id"]

    # User A sees Delivery A
    delivs_a = client.get("/deliveries", headers=headers_a)
    assert delivs_a.status_code == 200
    assert len(delivs_a.json()) == 1
    assert delivs_a.json()[0]["batch_id"] == batch_a_id

    # User B still does NOT see Delivery A
    delivs_b = client.get("/deliveries", headers=headers_b)
    assert delivs_b.status_code == 200
    assert len(delivs_b.json()) == 0

    # TEST C: User B requests Delivery A -> 404
    get_unauth = client.get(f"/deliveries/{batch_a_id}", headers=headers_b)
    assert get_unauth.status_code == 404


def test_rbac_workspaces_endpoint_and_isolation():
    """
    Verifies Section 4, 5, 14, 15:
    1. Returns all 7 PRD personas/workspaces.
    2. RMC is flagship with Dynamic Slump Risk & Transit Loss Prevention.
    3. New user gets active_deliveries = 0 on RMC workspace.
    4. Account with delivery gets scoped active_deliveries = 1, while other accounts see 0.
    """
    # 1. Unauthenticated / public call
    pub_res = client.get("/workspaces")
    assert pub_res.status_code == 200
    pub_workspaces = pub_res.json()
    assert len(pub_workspaces) == 7

    workspace_ids = [w["id"] for w in pub_workspaces]
    assert workspace_ids == ["rmc", "health", "fitness", "beach", "traveler", "family", "agriculture"]

    rmc_pub = next(w for w in pub_workspaces if w["id"] == "rmc")
    assert rmc_pub["is_flagship"] is True
    assert rmc_pub["active_deliveries"] == 0

    # 2. Register New User 1
    u1_email = f"user1_{uuid.uuid4().hex[:6]}@example.com"
    org1 = f"Org-Alpha-{uuid.uuid4().hex[:6]}"
    reg1 = client.post("/auth/register", json={
        "email": u1_email,
        "password": "Password123!",
        "name": "Test User 1",
        "organization": org1
    })
    assert reg1.status_code == 201
    tok1 = reg1.json()["access_token"]
    headers1 = {"Authorization": f"Bearer {tok1}"}

    # User 1 has 0 deliveries initially
    ws1 = client.get("/workspaces", headers=headers1)
    assert ws1.status_code == 200
    ws1_data = ws1.json()
    assert len(ws1_data) == 7
    rmc1 = next(w for w in ws1_data if w["id"] == "rmc")
    assert rmc1["active_deliveries"] == 0
    assert rmc1["attention_count"] == 0
    assert rmc1["is_authorized"] is True

    # 3. User 1 creates an active delivery
    deliv = client.post("/deliveries", json={
        "batch_code": f"RMC-WS-{uuid.uuid4().hex[:4].upper()}",
        "plant_id": "plant_a",
        "plant_name": "Plant A",
        "project_id": "proj_gift",
        "project_name": "GIFT City",
        "concrete_grade": "M35",
        "volume_m3": 6.0,
        "initial_slump_mm": 120.0,
        "target_slump_mm": 110.0,
        "slump_retention_requirement_pct": 92.0,
        "concrete_temp_c": 30.0,
        "ambient_temp_c": 32.0,
        "humidity_pct": 60.0,
        "admixture_retarder": "Standard",
        "selected_route_id": "route_1",
        "planned_transit_minutes": 45.0,
        "expected_delay_min": 5.0
    }, headers=headers1)
    assert deliv.status_code == 200

    # Now User 1 workspaces shows active_deliveries == 1
    ws1_after = client.get("/workspaces", headers=headers1)
    assert ws1_after.status_code == 200
    rmc1_after = next(w for w in ws1_after.json() if w["id"] == "rmc")
    assert rmc1_after["active_deliveries"] == 1

    # 4. Register New User 2 in separate organization
    u2_email = f"user2_{uuid.uuid4().hex[:6]}@example.com"
    org2 = f"Org-Beta-{uuid.uuid4().hex[:6]}"
    reg2 = client.post("/auth/register", json={
        "email": u2_email,
        "password": "Password123!",
        "name": "Test User 2",
        "organization": org2
    })
    assert reg2.status_code == 201
    tok2 = reg2.json()["access_token"]
    headers2 = {"Authorization": f"Bearer {tok2}"}

    # User 2 workspaces MUST show active_deliveries == 0 (strict data isolation)
    ws2 = client.get("/workspaces", headers=headers2)
    assert ws2.status_code == 200
    rmc2 = next(w for w in ws2.json() if w["id"] == "rmc")
    assert rmc2["active_deliveries"] == 0
    assert rmc2["attention_count"] == 0

