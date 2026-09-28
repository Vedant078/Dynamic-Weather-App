import uuid
import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_locations_crud_and_tenant_isolation():
    # 1. Register User A
    user_a_email = f"loc_user_a_{uuid.uuid4().hex[:6]}@example.com"
    org_a = f"Alpha-Concrete-{uuid.uuid4().hex[:6]}"
    reg_a = client.post("/auth/register", json={
        "email": user_a_email,
        "password": "Password123!",
        "name": "User Alpha",
        "organization": org_a
    })
    assert reg_a.status_code == 201
    tok_a = reg_a.json()["access_token"]
    headers_a = {"Authorization": f"Bearer {tok_a}"}

    # User A starts with 0 locations
    res = client.get("/locations", headers=headers_a)
    assert res.status_code == 200
    assert len(res.json()) == 0

    # User A creates Plant Alpha
    create_plant = client.post("/locations", json={
        "name": "Alpha Naroda Batching Plant",
        "type": "PLANT",
        "address": "Phase IV GIDC, Naroda",
        "latitude": 23.0680,
        "longitude": 72.6520
    }, headers=headers_a)
    assert create_plant.status_code == 201
    plant_a = create_plant.json()
    plant_a_id = plant_a["id"]
    assert plant_a["name"] == "Alpha Naroda Batching Plant"
    assert plant_a["type"] == "PLANT"
    assert plant_a["latitude"] == 23.0680
    assert plant_a["longitude"] == 72.6520

    # User A creates Project Site Alpha
    create_site = client.post("/locations", json={
        "name": "Alpha GIFT City Tower 10",
        "type": "PROJECT_SITE",
        "address": "Zone 2, GIFT City",
        "latitude": 23.1650,
        "longitude": 72.6890
    }, headers=headers_a)
    assert create_site.status_code == 201
    site_a_id = create_site.json()["id"]

    # User A lists locations (both are returned)
    locs_a = client.get("/locations", headers=headers_a).json()
    assert len(locs_a) == 2
    assert {l["id"] for l in locs_a} == {plant_a_id, site_a_id}

    # Filter by type
    plants_a = client.get("/locations?type=PLANT", headers=headers_a).json()
    assert len(plants_a) == 1
    assert plants_a[0]["id"] == plant_a_id

    # 2. Register User B in different organization
    user_b_email = f"loc_user_b_{uuid.uuid4().hex[:6]}@example.com"
    org_b = f"Beta-Infra-{uuid.uuid4().hex[:6]}"
    reg_b = client.post("/auth/register", json={
        "email": user_b_email,
        "password": "Password123!",
        "name": "User Beta",
        "organization": org_b
    })
    assert reg_b.status_code == 201
    tok_b = reg_b.json()["access_token"]
    headers_b = {"Authorization": f"Bearer {tok_b}"}

    # User B has 0 locations (does NOT see User A's locations)
    locs_b = client.get("/locations", headers=headers_b).json()
    assert len(locs_b) == 0

    # IDOR check: User B tries to view, edit, or delete User A's plant -> 404
    assert client.get(f"/locations/{plant_a_id}", headers=headers_b).status_code == 404
    assert client.put(f"/locations/{plant_a_id}", json={"name": "Hacked"}, headers=headers_b).status_code == 404
    assert client.delete(f"/locations/{plant_a_id}", headers=headers_b).status_code == 404

    # 3. User A updates Plant Alpha
    update_res = client.put(f"/locations/{plant_a_id}", json={
        "name": "Alpha Central Batching Plant (Upgraded)",
        "address": "Updated Address Naroda"
    }, headers=headers_a)
    assert update_res.status_code == 200
    assert update_res.json()["name"] == "Alpha Central Batching Plant (Upgraded)"

    # 4. User A deletes Project Site Alpha
    del_res = client.delete(f"/locations/{site_a_id}", headers=headers_a)
    assert del_res.status_code == 200
    assert client.get(f"/locations/{site_a_id}", headers=headers_a).status_code == 404
    assert len(client.get("/locations", headers=headers_a).json()) == 1


def test_demo_user_has_seeded_locations():
    # Login as demo user
    login = client.post("/auth/login", json={
        "email": "rmc.demo@mausam.local",
        "password": "RmcManager2026!"
    })
    assert login.status_code == 200
    tok = login.json()["access_token"]
    headers = {"Authorization": f"Bearer {tok}"}

    res = client.get("/locations", headers=headers)
    assert res.status_code == 200
    locs = res.json()
    assert len(locs) >= 4
    names = [l["name"] for l in locs]
    assert any("Naroda" in n for n in names)
    assert any("GIFT" in n for n in names)
