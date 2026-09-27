from fastapi import APIRouter
from app.models.schemas import PersonaListResponse, Persona


router = APIRouter(prefix="/personas", tags=["Personas"])

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


@router.get("", response_model=PersonaListResponse)
def get_personas():
    """Returns the list of 7 personas supported by MAUSAM."""
    return PersonaListResponse(personas=ALL_PERSONAS)
