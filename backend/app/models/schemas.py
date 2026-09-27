from typing import List, Optional, Dict, Any
from enum import Enum
from pydantic import BaseModel, Field
from datetime import datetime


class RiskLevel(str, Enum):
    SAFE = "SAFE"
    WATCH = "WATCH"
    HIGH_RISK = "HIGH_RISK"
    CRITICAL = "CRITICAL"
    RISK_UNAVAILABLE = "RISK_UNAVAILABLE"


class BatchStatus(str, Enum):
    CREATED = "CREATED"
    DISPATCHED = "DISPATCHED"
    IN_TRANSIT = "IN_TRANSIT"
    AT_RISK = "AT_RISK"
    REROUTED = "REROUTED"
    RETARDER_ADDED = "RETARDER_ADDED"
    DELIVERED = "DELIVERED"
    REJECTED = "REJECTED"


class MitigationAction(str, Enum):
    ADD_RETARDER = "ADD_RETARDER"
    RESCHEDULE_BATCH = "RESCHEDULE_BATCH"
    CALCULATE_NEW_ROUTE = "CALCULATE_NEW_ROUTE"
    OVERRIDE_PROCEED = "OVERRIDE_PROCEED"


# Persona Schemas
class Persona(BaseModel):
    id: str
    name: str
    tagline: str
    description: str
    primary_metrics: List[str]
    badge_label: Optional[str] = None


class PersonaListResponse(BaseModel):
    personas: List[Persona]


# Batch Schemas
class BatchCreate(BaseModel):
    plant_id: str = "plant-001"
    plant_name: str = "Ahmedabad Central Plant"
    plant_lat: Optional[float] = 23.0225
    plant_lng: Optional[float] = 72.5714
    project_id: str = "project-007"
    project_name: str = "Project Site 07"
    project_lat: Optional[float] = 23.0900
    project_lng: Optional[float] = 72.6100
    concrete_grade: str = "M35"
    volume_m3: float = 6.0
    target_slump_mm: float = 105.0
    initial_slump_mm: float = 110.0
    batch_code: Optional[str] = None
    dispatch_time: Optional[str] = "14:00"
    requested_delivery_time: Optional[str] = "15:00"
    admixture_retarder: Optional[str] = "None"
    planned_transit_minutes: Optional[float] = 48.0


class BatchDetail(BaseModel):
    batch_id: str
    batch_code: str
    plant_id: str
    plant_name: str
    project_id: str
    project_name: str
    volume_m3: float
    target_slump_mm: float
    initial_slump_mm: float
    current_slump_mm: float
    slump_retention_ratio: float
    concrete_temp_c: float
    ambient_temp_c: float
    elapsed_minutes: float
    eta_minutes: float
    original_eta_minutes: float
    distance_remaining_km: float
    total_distance_km: float
    traffic_index: float
    precipitation_prob: float
    status: BatchStatus
    risk_level: RiskLevel
    heat_risk: float
    travel_risk: float
    delivery_risk: float
    composite_risk: float
    primary_driver: str
    risk_factors: List[str]
    recommended_action: Optional[MitigationAction] = None
    created_at: str
    dispatched_at: Optional[str] = None


# Telemetry
class TelemetryEvent(BaseModel):
    timestamp: str
    batch_id: str
    latitude: float
    longitude: float
    ambient_temp_c: float
    concrete_temp_c: float
    slump_mm: float
    slump_retention_ratio: float
    elapsed_minutes: float
    eta_minutes: float
    distance_remaining_km: float
    traffic_index: float
    precipitation_mm: float
    heat_risk: float
    travel_risk: float
    delivery_risk: float
    composite_risk: float
    risk_level: RiskLevel


# Risk Prediction
class RiskPredictRequest(BaseModel):
    batch_id: str = "RMC-DRAFT"
    ambient_temp_c: float = 34.0
    concrete_temp_c: float = 32.0
    traffic_index: float = 0.45
    eta_minutes: float = 50.0
    elapsed_minutes: float = 0.0
    initial_slump_mm: float = 110.0
    target_slump_mm: float = 105.0
    precipitation_prob: float = 0.0
    distance_km: float = 28.5
    # Operational parameters required by PRD
    concrete_grade: Optional[str] = "M35"
    volume_m3: Optional[float] = 6.0
    dispatch_time: Optional[str] = "14:00"
    planned_transit_minutes: Optional[float] = None
    expected_delay_min: Optional[float] = None
    relative_humidity: Optional[float] = 50.0
    admixture_retarder: Optional[str] = "None"
    plant_id: Optional[str] = None
    plant_name: Optional[str] = None
    project_id: Optional[str] = None
    project_name: Optional[str] = None
    route_id: Optional[str] = None


class RiskPredictResponse(BaseModel):
    batch_id: str
    predicted_slump_mm: float
    slump_retention: float
    heat_risk: float
    travel_risk: float
    delivery_risk: float
    composite_risk: float
    decision: RiskLevel
    status_label: str
    is_approved: bool
    primary_driver: str
    contributors: List[str]
    model_version: str = "RMC-CORE-v2.0"
    recommended_action: Optional[MitigationAction] = None
    # Enhanced multi-dimensional telemetry
    heat_risk_level: Optional[RiskLevel] = None
    travel_risk_level: Optional[RiskLevel] = None
    delivery_risk_level: Optional[RiskLevel] = None
    planned_transit_minutes: Optional[float] = None
    expected_arrival_time: Optional[str] = None
    sla_status: Optional[str] = "COMPLIANT"
    worst_material_factor: Optional[str] = None
    is_data_insufficient: bool = False



# Route Schemas
class Waypoint(BaseModel):
    lat: float
    lng: float
    name: Optional[str] = None


class RouteSegment(BaseModel):
    start_point: Waypoint
    end_point: Waypoint
    distance_km: float
    duration_min: float
    traffic_congestion: float  # 0 to 1
    ambient_temp_c: float
    risk_level: RiskLevel


class RouteOption(BaseModel):
    route_id: str
    route_name: str
    is_recommended: bool
    eta_minutes: float
    distance_km: float
    delivery_risk: float
    heat_risk: float
    travel_risk: float
    traffic_level: str
    weather_summary: str
    trade_off_explanation: str
    waypoints: List[Waypoint]


class RouteAnalyzeRequest(BaseModel):
    batch_id: str
    origin: Waypoint
    destination: Waypoint


class RouteAnalyzeResponse(BaseModel):
    recommended_route_id: str
    eta_minutes: float
    delivery_risk: float
    recommendation_reason: str
    alternatives: List[RouteOption]


# Mitigation Actions
class ActionExecuteRequest(BaseModel):
    batch_id: str
    action: MitigationAction
    operator_notes: Optional[str] = None
    override_confirmed: bool = False
    chosen_route_id: Optional[str] = None


class ActionExecuteResponse(BaseModel):
    batch_id: str
    action_taken: MitigationAction
    new_status: BatchStatus
    new_risk_level: RiskLevel
    message: str
    updated_eta_minutes: float
    updated_delivery_risk: float


# Delivery Outcome
class OutcomeRecordRequest(BaseModel):
    batch_id: str
    outcome: str  # "accepted", "accepted_with_warning", "rejected"
    site_slump_mm: float
    actual_transit_minutes: float
    site_concrete_temp_c: float
    rejection_reason: Optional[str] = None
    root_cause: Optional[str] = None
    notes: Optional[str] = None


class OutcomeResponse(BaseModel):
    outcome_id: str
    batch_id: str
    outcome: str
    quality_grade: str
    slump_variance_mm: float
    financial_impact_inr: float
    financial_type: str  # "AVOIDED_LOSS", "MATERIAL_LOSS", "NOMINAL_COST"
    ml_training_recorded: bool
    recorded_at: str


# Fleet Summary KPI
class FleetKPI(BaseModel):
    active_deliveries: int
    high_risk_batches: int
    on_time_count: int
    watch_count: int
    avg_transit_minutes: float
    at_risk_volume_m3: float
    potential_loss_inr: float
    loss_avoided_inr: float
    freshness_seconds: int = 4


# Authentication & RBAC Schemas
class RoleSchema(BaseModel):
    id: str
    name: str
    description: Optional[str] = None


class UserResponse(BaseModel):
    id: str
    name: str
    email: str
    organization: Optional[str] = None
    roles: List[RoleSchema] = []
    is_active: bool = True
    created_at: Optional[str] = None


class UserRegisterRequest(BaseModel):
    name: str
    email: str
    password: str
    organization: Optional[str] = None
    role_id: Optional[str] = None
    role_ids: Optional[List[str]] = None


class UserLoginRequest(BaseModel):
    email: str
    password: str


class AuthResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse


class WorkspaceSummary(BaseModel):
    id: str
    name: str
    tagline: str
    description: str
    is_flagship: bool = False
    key_capability: Optional[str] = None
    capabilities: List[str] = []
    active_deliveries: int = 0
    attention_count: int = 0
    is_authorized: bool = True

