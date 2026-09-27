from fastapi import APIRouter, Query
from typing import Dict, Any, List
from app.ml.features import compute_heat_index


router = APIRouter(prefix="/weather", tags=["Weather Intelligence"])


@router.get("/current")
def get_current_weather(
    city: str = Query("Ahmedabad", description="City name"),
    lat: float = Query(23.0225, description="Latitude"),
    lng: float = Query(72.5714, description="Longitude"),
    time_of_day: str = Query("14:00", description="Time of day HH:MM")
) -> Dict[str, Any]:
    """
    Returns canonical environmental telemetry tailored for concrete logistics
    and secondary persona weather intelligence.
    """
    from app.services.weather_service import canonical_weather_service
    telemetry = canonical_weather_service.get_weather(location=city, time_of_day=time_of_day)
    
    return {
        "location": {
            "city": city,
            "region": "Gujarat, India",
            "lat": lat,
            "lng": lng
        },
        "current": {
            "temperature_c": telemetry["ambient_temp_c"],
            "apparent_temperature_c": telemetry["apparent_temp_c"],
            "relative_humidity_pct": telemetry["humidity_pct"],
            "wind_speed_kmh": telemetry["wind_speed_kmh"],
            "wind_direction_deg": 240,
            "wind_direction_cardinal": telemetry["wind_direction"],
            "precipitation_mm": 0.0,
            "precipitation_probability_pct": telemetry["precipitation_probability_pct"],
            "uv_index": telemetry["uv_index"],
            "uv_category": "Very High" if telemetry["uv_index"] > 7 else "Moderate",
            "aqi": telemetry["air_quality_index"],
            "aqi_category": "Moderate / Sensitive Groups",
            "pm2_5": 58.2,
            "pollen_index": 4.1,
            "soil_moisture_m3m3": 0.22,
            "tide_height_m": 1.8,
            "water_temp_c": 28.5,
            "weather_condition": telemetry["weather_condition"],
            "weather_code": 2,
            "freshness": telemetry["freshness"]
        },
        "operational_advisory": {
            "rmc_heat_alert": "Elevated midday heat. Transit hydration accelerating." if telemetry["ambient_temp_c"] >= 38.0 else "Normal temperature range.",
            "recommended_dispatch_window": "Early Morning (05:00 - 08:30) or Late Evening (18:00 - 22:00)",
            "safe_pour_duration_min": 75 if telemetry["ambient_temp_c"] >= 38.0 else 90
        }
    }


@router.get("/hourly")
def get_hourly_forecast(city: str = "Ahmedabad") -> List[Dict[str, Any]]:
    """Returns 8-hour operational transit risk window outlook."""
    hours = ["14:00", "15:00", "16:00", "17:00", "18:00", "19:00", "20:00", "21:00"]
    temps = [36.4, 38.2, 40.2, 39.5, 37.0, 35.2, 33.8, 32.5]
    precips = [10, 25, 68, 45, 20, 10, 5, 0]
    risks = ["SAFE", "WATCH", "HIGH_RISK", "WATCH", "SAFE", "SAFE", "SAFE", "SAFE"]
    
    return [
        {
            "time": hours[i],
            "temp_c": temps[i],
            "precipitation_prob_pct": precips[i],
            "risk_tier": risks[i],
            "is_preferred_window": risks[i] == "SAFE"
        }
        for i in range(len(hours))
    ]
