import uuid
from datetime import datetime, timezone
from sqlalchemy import (
    Column, String, Boolean, DateTime, Float, Integer, ForeignKey, Text, JSON, Table
)
from sqlalchemy.orm import relationship
from app.db.session import Base


def utc_now():
    return datetime.now(timezone.utc)


def gen_uuid():
    return str(uuid.uuid4())


# Association table for User <-> Role (Many-to-Many)
user_roles = Table(
    "user_roles",
    Base.metadata,
    Column("user_id", String, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True),
    Column("role_id", String, ForeignKey("roles.id", ondelete="CASCADE"), primary_key=True),
    Column("assigned_at", DateTime(timezone=True), default=utc_now)
)


class Role(Base):
    __tablename__ = "roles"

    id = Column(String, primary_key=True)  # e.g. "rmc", "health", etc.
    name = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utc_now)

    users = relationship("User", secondary=user_roles, back_populates="roles")


class User(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True, default=gen_uuid)
    email = Column(String, unique=True, index=True, nullable=False)
    password_hash = Column(String, nullable=False)
    full_name = Column(String, nullable=False)
    organization_name = Column(String, nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime(timezone=True), default=utc_now)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)
    last_login_at = Column(DateTime(timezone=True), nullable=True)

    roles = relationship("Role", secondary=user_roles, back_populates="users", lazy="joined")
    deliveries = relationship("Delivery", back_populates="user", cascade="all, delete-orphan")


class Delivery(Base):
    __tablename__ = "deliveries"

    id = Column(String, primary_key=True, default=lambda: f"batch-{uuid.uuid4().hex[:6]}")
    batch_code = Column(String, nullable=False, index=True)
    user_id = Column(String, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    organization = Column(String, nullable=True)

    # Origin Plant
    plant_id = Column(String, nullable=False)
    plant_name = Column(String, nullable=False)
    plant_lat = Column(Float, nullable=False, default=23.0225)
    plant_lng = Column(Float, nullable=False, default=72.5714)

    # Destination Project
    project_id = Column(String, nullable=False)
    project_name = Column(String, nullable=False)
    project_lat = Column(Float, nullable=False, default=23.0900)
    project_lng = Column(Float, nullable=False, default=72.6100)

    # Concrete Specs
    concrete_grade = Column(String, nullable=False, default="M35")  # M20 - M45
    volume_m3 = Column(Float, nullable=False, default=6.0)
    initial_slump_mm = Column(Float, nullable=False, default=110.0)
    target_slump_mm = Column(Float, nullable=False, default=105.0)
    current_slump_mm = Column(Float, nullable=False, default=110.0)
    slump_retention_ratio = Column(Float, nullable=False, default=1.0)
    concrete_temp_c = Column(Float, nullable=False, default=32.0)
    ambient_temp_c = Column(Float, nullable=False, default=34.0)
    relative_humidity = Column(Float, nullable=False, default=50.0)

    # Route & Transit
    dispatch_time = Column(String, nullable=False, default="14:00")
    requested_delivery_time = Column(String, nullable=True)
    admixture_retarder = Column(String, nullable=True, default="None")
    planned_transit_minutes = Column(Float, nullable=False, default=48.0)
    elapsed_minutes = Column(Float, nullable=False, default=0.0)
    eta_minutes = Column(Float, nullable=False, default=48.0)
    original_eta_minutes = Column(Float, nullable=False, default=48.0)
    distance_remaining_km = Column(Float, nullable=False, default=28.5)
    total_distance_km = Column(Float, nullable=False, default=28.5)
    traffic_index = Column(Float, nullable=False, default=0.35)
    precipitation_prob = Column(Float, nullable=False, default=0.0)

    # Operational status
    status = Column(String, nullable=False, default="DISPATCHED")  # DISPATCHED, IN_TRANSIT, DELIVERED, REJECTED
    active_route_id = Column(String, nullable=False, default="route-a")
    created_at = Column(DateTime(timezone=True), default=utc_now)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)
    dispatched_at = Column(DateTime(timezone=True), default=utc_now)

    user = relationship("User", back_populates="deliveries")
    risk_results = relationship("DeliveryRiskResult", back_populates="delivery", cascade="all, delete-orphan", order_by="desc(DeliveryRiskResult.calculated_at)")
    telemetry_points = relationship("Telemetry", back_populates="delivery", cascade="all, delete-orphan", order_by="desc(Telemetry.timestamp)")
    outcome = relationship("DeliveryOutcome", back_populates="delivery", uselist=False, cascade="all, delete-orphan")


class DeliveryRiskResult(Base):
    __tablename__ = "delivery_risk_results"

    id = Column(String, primary_key=True, default=gen_uuid)
    delivery_id = Column(String, ForeignKey("deliveries.id", ondelete="CASCADE"), nullable=False, index=True)
    model_version = Column(String, nullable=False)
    calculated_at = Column(DateTime(timezone=True), default=utc_now)

    # Core predictions & calculations
    predicted_slump_mm = Column(Float, nullable=False)
    slump_retention_ratio = Column(Float, nullable=False)
    heat_risk = Column(Float, nullable=False)
    travel_risk = Column(Float, nullable=False)
    delivery_risk = Column(Float, nullable=False)
    composite_risk = Column(Float, nullable=False)
    decision = Column(String, nullable=False)  # SAFE, WATCH, HIGH_RISK, CRITICAL
    sla_status = Column(String, nullable=False)  # COMPLIANT, APPROACHING_LIMIT, BREACH, CRITICAL_BREACH, DATA_INSUFFICIENT
    primary_driver = Column(Text, nullable=False)
    contributors = Column(JSON, nullable=True)  # List of explainable factors
    recommended_action = Column(String, nullable=True)
    input_snapshot = Column(JSON, nullable=True)  # Exact snapshot of features at inference time

    delivery = relationship("Delivery", back_populates="risk_results")


class Telemetry(Base):
    __tablename__ = "telemetry"

    id = Column(String, primary_key=True, default=gen_uuid)
    delivery_id = Column(String, ForeignKey("deliveries.id", ondelete="CASCADE"), nullable=False, index=True)
    timestamp = Column(DateTime(timezone=True), default=utc_now)
    lat = Column(Float, nullable=False)
    lng = Column(Float, nullable=False)
    speed_kmh = Column(Float, nullable=False, default=35.0)
    concrete_temp_c = Column(Float, nullable=False, default=32.0)
    drum_rpm = Column(Float, nullable=False, default=12.0)
    current_slump_mm = Column(Float, nullable=False, default=105.0)
    ambient_temp_c = Column(Float, nullable=False, default=34.0)
    humidity_pct = Column(Float, nullable=False, default=50.0)

    delivery = relationship("Delivery", back_populates="telemetry_points")


class DeliveryOutcome(Base):
    __tablename__ = "delivery_outcomes"

    id = Column(String, primary_key=True, default=gen_uuid)
    delivery_id = Column(String, ForeignKey("deliveries.id", ondelete="CASCADE"), nullable=False, unique=True, index=True)
    outcome = Column(String, nullable=False)  # "accepted", "rejected"
    quality_grade = Column(String, nullable=False)
    site_slump_mm = Column(Float, nullable=False)
    slump_variance_mm = Column(Float, nullable=False)
    actual_transit_minutes = Column(Float, nullable=False)
    site_concrete_temp_c = Column(Float, nullable=False)
    financial_impact_inr = Column(Float, nullable=False)
    financial_type = Column(String, nullable=False)  # "AVOIDED_LOSS", "MATERIAL_LOSS"
    rejection_reason = Column(Text, nullable=True)
    ml_training_recorded = Column(Boolean, default=True)
    recorded_at = Column(DateTime(timezone=True), default=utc_now)

    delivery = relationship("Delivery", back_populates="outcome")
