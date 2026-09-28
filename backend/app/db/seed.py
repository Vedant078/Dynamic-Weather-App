import logging
from datetime import datetime, timezone
from app.db.session import SessionLocal
from app.db.models import User, Role, Delivery, DeliveryRiskResult, Telemetry, Location
from app.repositories.user_repository import UserRepository, STANDARD_ROLES
from app.config import settings
from app.ml.model import model_manager

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("seed")


def seed_database():
    db = SessionLocal()
    try:
        # 1. Seed Roles
        logger.info("Seeding standard roles...")
        UserRepository.seed_standard_roles(db)

        # 2. Seed Development RMC User
        demo_email = settings.SEED_DEV_USER_EMAIL.strip().lower()
        standard_role_ids = [r["id"] for r in STANDARD_ROLES]
        existing_user = UserRepository.get_by_email(db, demo_email)
        if not existing_user:
            logger.info(f"Creating development user: {demo_email}")
            user = UserRepository.create_user(
                db=db,
                email=demo_email,
                password=settings.SEED_DEV_USER_PASSWORD,
                full_name="RMC Operations Dispatcher",
                organization_name="Mausam RMC Demo",
                role_ids=standard_role_ids
            )
        else:
            user = existing_user
            logger.info(f"Development user already exists: {demo_email}")
            for rid in standard_role_ids:
                r_obj = db.query(Role).filter(Role.id == rid).first()
                if r_obj and r_obj not in user.roles:
                    user.roles.append(r_obj)
            db.commit()

        # Seed Demo Locations for demo user
        loc_count = db.query(Location).filter(Location.user_id == user.id).count()
        if loc_count == 0:
            logger.info("Seeding demo operational locations...")
            demo_locs = [
                Location(
                    user_id=user.id,
                    organization=user.organization_name,
                    name="Ahmedabad Central Batching Plant (Naroda)",
                    type="PLANT",
                    address="GIDC Naroda Industrial Estate, Ahmedabad",
                    latitude=23.0650,
                    longitude=72.6500,
                ),
                Location(
                    user_id=user.id,
                    organization=user.organization_name,
                    name="Ahmedabad Sanand Batching Plant 02",
                    type="PLANT",
                    address="Sanand GIDC II, Ahmedabad West",
                    latitude=22.9850,
                    longitude=72.3780,
                ),
                Location(
                    user_id=user.id,
                    organization=user.organization_name,
                    name="Gandhinagar Infocity Batching Plant 03",
                    type="PLANT",
                    address="Koba-Gandhinagar Expressway, Sector 26",
                    latitude=23.1950,
                    longitude=72.6350,
                ),
                Location(
                    user_id=user.id,
                    organization=user.organization_name,
                    name="GIFT City Tower B Expansion",
                    type="PROJECT_SITE",
                    address="Block 14, Zone 1, GIFT City, Gandhinagar",
                    latitude=23.1600,
                    longitude=72.6850,
                ),
                Location(
                    user_id=user.id,
                    organization=user.organization_name,
                    name="Metro Pier 142 - Thaltej Corridor",
                    type="PROJECT_SITE",
                    address="Drive-In Road / SG Highway Junction, Thaltej",
                    latitude=23.0510,
                    longitude=72.5180,
                ),
                Location(
                    user_id=user.id,
                    organization=user.organization_name,
                    name="Sabarmati Riverfront Phase 2",
                    type="PROJECT_SITE",
                    address="West Promenade, Riverfront North, Ahmedabad",
                    latitude=23.0320,
                    longitude=72.5740,
                ),
                Location(
                    user_id=user.id,
                    organization=user.organization_name,
                    name="SP Ring Road Logistics Hub",
                    type="DESTINATION",
                    address="Sardar Patel Ring Road Junction 7",
                    latitude=23.1150,
                    longitude=72.5480,
                ),
            ]
            db.add_all(demo_locs)
            db.commit()

        # 3. Seed Realistic RMC Deliveries if none exist
        delivery_count = db.query(Delivery).count()
        if delivery_count == 0:
            logger.info("Seeding initial RMC operational deliveries...")
            
            # Seed 1: Active M35 batch along Ahmedabad - Gift City corridor
            batch_1 = Delivery(
                id="batch-ahd-204",
                batch_code="DEMO-RMC-001",
                user_id=user.id,
                organization=user.organization_name,
                plant_id="plant-001",
                plant_name="Ahmedabad Central Batching Plant (Naroda)",
                plant_lat=23.0650,
                plant_lng=72.6500,
                project_id="proj-gift-07",
                project_name="GIFT City Tower B Expansion",
                project_lat=23.1600,
                project_lng=72.6850,
                concrete_grade="M35",
                volume_m3=6.0,
                initial_slump_mm=110.0,
                target_slump_mm=105.0,
                current_slump_mm=106.0,
                slump_retention_ratio=0.964,
                concrete_temp_c=32.0,
                ambient_temp_c=34.5,
                relative_humidity=48.0,
                dispatch_time="14:00",
                requested_delivery_time="15:00",
                admixture_retarder="MasterPozzolith 0.4%",
                planned_transit_minutes=52.0,
                elapsed_minutes=18.0,
                eta_minutes=34.0,
                original_eta_minutes=52.0,
                distance_remaining_km=18.4,
                total_distance_km=28.5,
                traffic_index=0.38,
                precipitation_prob=5.0,
                status="DISPATCHED",
                active_route_id="route-a",
                created_at=datetime.now(timezone.utc),
                dispatched_at=datetime.now(timezone.utc)
            )
            db.add(batch_1)

            # Seed 2: High-grade M40 batch approaching SLA threshold
            batch_2 = Delivery(
                id="batch-ahd-205",
                batch_code="DEMO-RMC-002",
                user_id=user.id,
                organization=user.organization_name,
                plant_id="plant-002",
                plant_name="Sanand Industrial Mixing Plant",
                plant_lat=22.9900,
                plant_lng=72.3800,
                project_id="proj-metro-03",
                project_name="Metro Rail Pillar Section 4A",
                project_lat=23.0300,
                project_lng=72.5800,
                concrete_grade="M40",
                volume_m3=7.0,
                initial_slump_mm=120.0,
                target_slump_mm=110.0,
                current_slump_mm=108.0,
                slump_retention_ratio=0.900,
                concrete_temp_c=34.0,
                ambient_temp_c=38.0,
                relative_humidity=42.0,
                dispatch_time="13:30",
                requested_delivery_time="15:00",
                admixture_retarder="None",
                planned_transit_minutes=82.0,
                elapsed_minutes=42.0,
                eta_minutes=40.0,
                original_eta_minutes=65.0,
                distance_remaining_km=16.2,
                total_distance_km=34.0,
                traffic_index=0.72,
                precipitation_prob=10.0,
                status="IN_TRANSIT",
                active_route_id="route-b",
                created_at=datetime.now(timezone.utc),
                dispatched_at=datetime.now(timezone.utc)
            )
            db.add(batch_2)

            db.commit()

            # Execute real model inference for each seeded delivery and persist risk result
            for b in [batch_1, batch_2]:
                risk_data = {
                    "batch_id": b.id,
                    "plant_name": b.plant_name,
                    "project_name": b.project_name,
                    "concrete_grade": b.concrete_grade,
                    "initial_slump_mm": b.initial_slump_mm,
                    "target_slump_mm": b.target_slump_mm,
                    "ambient_temp_c": b.ambient_temp_c,
                    "concrete_temp_c": b.concrete_temp_c,
                    "relative_humidity": b.relative_humidity,
                    "traffic_index": b.traffic_index,
                    "planned_transit_minutes": b.planned_transit_minutes,
                    "elapsed_minutes": b.elapsed_minutes,
                    "eta_minutes": b.eta_minutes,
                    "dispatch_time": b.dispatch_time,
                    "admixture_retarder": b.admixture_retarder
                }
                pred = model_manager.predict_batch_risk(risk_data)
                
                risk_res = DeliveryRiskResult(
                    delivery_id=b.id,
                    model_version=pred.get("model_version", "GBR-RMC-v2.0"),
                    predicted_slump_mm=pred["predicted_slump_mm"],
                    slump_retention_ratio=pred["slump_retention"],
                    heat_risk=pred["heat_risk"],
                    travel_risk=pred["travel_risk"],
                    delivery_risk=pred["delivery_risk"],
                    composite_risk=pred["composite_risk"],
                    decision=pred["decision"],
                    sla_status=pred.get("sla_status", "COMPLIANT"),
                    primary_driver=pred["primary_driver"],
                    contributors=pred.get("contributors", []),
                    recommended_action=pred.get("recommended_action"),
                    input_snapshot=risk_data
                )
                db.add(risk_res)

                # Add initial telemetry point
                t_point = Telemetry(
                    delivery_id=b.id,
                    lat=b.plant_lat,
                    lng=b.plant_lng,
                    speed_kmh=38.0,
                    concrete_temp_c=b.concrete_temp_c,
                    drum_rpm=12.0,
                    current_slump_mm=b.current_slump_mm,
                    ambient_temp_c=b.ambient_temp_c,
                    humidity_pct=b.relative_humidity
                )
                db.add(t_point)

            db.commit()
            logger.info("Successfully seeded RMC deliveries with real model inferences!")
        
        logger.info("Database seeding completed successfully.")

    finally:
        db.close()


if __name__ == "__main__":
    seed_database()
