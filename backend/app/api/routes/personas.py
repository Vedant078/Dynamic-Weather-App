from typing import List, Optional
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.db.models import User
from app.api.deps import get_current_user_optional
from app.repositories.delivery_repository import DeliveryRepository
from app.models.schemas import PersonaListResponse, Persona, WorkspaceSummary


router = APIRouter(tags=["Personas & Workspaces"])

ALL_PERSONAS = [
    Persona(
        id="rmc",
        name="RMC Logistics Manager",
        tagline="Ready-Mix Concrete Transit Loss Prevention",
        description="Predict concrete slump loss, evaluate route heat/traffic exposure, and prevent rejected batches with real-time operational mitigations.",
        primary_metrics=["Slump Retention", "Transit Window", "Concrete Temp", "Delivery Risk"],
        badge_label="Flagship Engine"
    ),
    Persona(
        id="health",
        name="Health-Conscious Users",
        tagline="Air Quality & Heat Vulnerability Intelligence",
        description="Monitor hyper-local AQI, particulate matter (PM2.5/PM10), UV radiation, and heat stress exposure windows.",
        primary_metrics=["AQI Index", "PM 2.5", "UV Index", "Heat Exposure Risk"]
    ),
    Persona(
        id="fitness",
        name="Outdoor Fitness Enthusiasts",
        tagline="Optimal Training Window Predictor",
        description="Calculate safe running and cycling hours based on wet-bulb globe temperature, wind shear, and sudden precipitation.",
        primary_metrics=["Safe Running Window", "Heat Strain", "Wind Speed", "Precipitation Probability"]
    ),
    Persona(
        id="beach",
        name="Beachgoers & Surfers",
        tagline="Coastal & Marine Safety Telemetry",
        description="Track high/low tide schedules, wave swell height, water surface temperature, and offshore rip-current warnings.",
        primary_metrics=["Tide Status", "Swell Height", "Water Temp", "Wind Direction"]
    ),
    Persona(
        id="traveler",
        name="Travelers & Commuters",
        tagline="Corridor Weather & Highway Delay Alerts",
        description="Anticipate microclimate squalls, monsoon waterlogging, fog visibility drops, and airport flight delays along your journey.",
        primary_metrics=["Corridor Visibility", "Rainfall Accumulation", "Flight Weather Impact", "Route Delay"]
    ),
    Persona(
        id="family",
        name="Parents & Families",
        tagline="Family Safety & School Commute Guard",
        description="Receive proactive alerts for sudden severe thunderstorms, extreme afternoon heat spikes, and safe pickup hours.",
        primary_metrics=["Commute Risk", "Sudden Rain Alert", "Afternoon Heat Peak", "Air Quality Status"]
    ),
    Persona(
        id="agriculture",
        name="Agriculture & Gardeners",
        tagline="Crop Hydration & Microclimate Guidance",
        description="Evaluate root-zone soil moisture, dew point condensation, unseasonal frost probability, and irrigation advisories.",
        primary_metrics=["Soil Moisture %", "Frost Probability", "Evapotranspiration Rate", "Rainfall Forecast"]
    )
]


@router.get("/personas", response_model=PersonaListResponse)
def get_personas():
    """Returns the list of 7 personas supported by MAUSAM."""
    return PersonaListResponse(personas=ALL_PERSONAS)


@router.get("/workspaces", response_model=List[WorkspaceSummary])
@router.get("/personas/workspaces", response_model=List[WorkspaceSummary])
@router.get("/me/workspaces", response_model=List[WorkspaceSummary])
def get_workspaces(
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user_optional)
):
    """
    Returns RBAC-authorized workspace definitions.
    For RMC, includes real database-scoped operational summaries (active deliveries, alerts).
    For consumer personas, returns concise workspace metadata and capabilities.
    """
    active_deliveries = 0
    attention_count = 0
    user_roles = set()

    if current_user:
        user_roles = {r.id.lower() for r in current_user.roles}
        kpi = DeliveryRepository.get_fleet_kpi(
            db,
            organization=current_user.organization_name,
            user_id=current_user.id
        )
        active_deliveries = kpi.active_deliveries
        attention_count = kpi.high_risk_batches

    workspaces = [
        WorkspaceSummary(
            id="rmc",
            name="RMC Logistics Manager",
            tagline="Ready-Mix Concrete Operations & Transit Loss Prevention",
            description="Monitor transit conditions, concrete quality risk and delivery decisions.",
            is_flagship=True,
            capabilities=["Dynamic Slump Risk", "Route Intelligence", "Transit Loss Prevention"],
            active_deliveries=active_deliveries,
            attention_count=attention_count,
            is_authorized=True if not user_roles or "rmc" in user_roles or "rmc_logistics_manager" in user_roles else False
        ),
        WorkspaceSummary(
            id="health",
            name="Health-Conscious Users",
            tagline="Air Quality & Heat Vulnerability",
            description="Hyper-local AQI, particulate matter, UV radiation, and heat stress exposure windows.",
            is_flagship=False,
            key_capability="AQI • Heat • Pollen",
            capabilities=["AQI Monitoring", "Heat Strain Warnings", "Pollen Radar"],
            is_authorized=True if not user_roles or "health" in user_roles else False
        ),
        WorkspaceSummary(
            id="fitness",
            name="Outdoor Fitness Enthusiasts",
            tagline="Optimal Training Window Predictor",
            description="Safe running and cycling hours based on wet-bulb globe temperature and sudden precipitation.",
            is_flagship=False,
            key_capability="Safe Windows • Heat Alerts • Wind",
            capabilities=["Running Window Predictor", "Heat Alerts", "Headwind Vectors"],
            is_authorized=True if not user_roles or "fitness" in user_roles else False
        ),
        WorkspaceSummary(
            id="beach",
            name="Beachgoers & Surfers",
            tagline="Coastal & Marine Safety Telemetry",
            description="Marine swell conditions, tide timetables, rip-current warnings and coastal water safety telemetry.",
            is_flagship=False,
            key_capability="Tide Swell • Water Temp • Rip Currents",
            capabilities=["Tide Schedule", "Wave Swell Height", "Water Temp"],
            is_authorized=True if not user_roles or "beach" in user_roles else False
        ),
        WorkspaceSummary(
            id="traveler",
            name="Travelers & Commuters",
            tagline="Corridor Weather & Highway Delay Alerts",
            description="Microclimate squalls, monsoon waterlogging, fog visibility drops, and corridor highway delays.",
            is_flagship=False,
            key_capability="Highway Visibility • Delay Alerts",
            capabilities=["Corridor Visibility", "Rainfall Accumulation", "Route Delay"],
            is_authorized=True if not user_roles or "traveler" in user_roles else False
        ),
        WorkspaceSummary(
            id="family",
            name="Parents & Families",
            tagline="Family Safety & School Commute Guard",
            description="Proactive alerts for sudden severe thunderstorms, extreme afternoon heat spikes, and safe pickup hours.",
            is_flagship=False,
            key_capability="School Commute • Storm Warnings",
            capabilities=["Commute Risk Guard", "Sudden Rain Alerts", "UV Advisory"],
            is_authorized=True if not user_roles or "family" in user_roles else False
        ),
        WorkspaceSummary(
            id="agriculture",
            name="Agriculture & Gardeners",
            tagline="Crop Hydration & Microclimate Guidance",
            description="Root-zone soil moisture, dew point condensation, unseasonal frost probability, and irrigation advisories.",
            is_flagship=False,
            key_capability="Soil Moisture • Frost • Crop Windows",
            capabilities=["Soil Moisture Index", "Frost Risk", "Evapotranspiration Rate"],
            is_authorized=True if not user_roles or "agriculture" in user_roles else False
        ),
    ]

    return workspaces

