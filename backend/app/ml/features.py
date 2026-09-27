import numpy as np
from typing import Dict, Any, List


FEATURE_NAMES = [
    "ambient_temp_c",
    "concrete_temp_c",
    "relative_humidity",
    "wind_speed_kmh",
    "precipitation_mm",
    "traffic_congestion",
    "expected_delay_min",
    "distance_km",
    "batch_age_min",
    "initial_slump_mm",
    "target_slump_mm",
    "concrete_volume_m3",
    "heat_exposure_index",
    "eta_deviation_min",
]


def compute_heat_index(temp_c: float, humidity: float) -> float:
    """Calculates apparent heat index from ambient temp (°C) and relative humidity (%)."""
    # Simplified Rothfusz regression adapted for Celsius
    t = temp_c
    rh = humidity
    hi = 0.5 * (t + 16.8 + (1.2 * t * (rh / 100.0)))
    return round(float(hi), 2)


def extract_feature_vector(data: Dict[str, Any]) -> np.ndarray:
    """Extracts ordered feature vector matching FEATURE_NAMES."""
    ambient_temp = float(data.get("ambient_temp_c", 34.0))
    concrete_temp = float(data.get("concrete_temp_c", 32.0))
    humidity = float(data.get("relative_humidity", 50.0))
    wind = float(data.get("wind_speed_kmh", 12.0))
    precip = float(data.get("precipitation_mm", 0.0))
    traffic = float(data.get("traffic_congestion", data.get("traffic_index", 0.45)))
    delay = float(data.get("expected_delay_min", data.get("delay_min", 0.0)))
    distance = float(data.get("distance_km", 25.0))
    batch_age = float(data.get("batch_age_min", data.get("elapsed_minutes", 20.0)))
    initial_slump = float(data.get("initial_slump_mm", 110.0))
    target_slump = float(data.get("target_slump_mm", 105.0))
    volume = float(data.get("concrete_volume_m3", data.get("volume_m3", 6.0)))
    
    # Derived features
    heat_exposure = (ambient_temp / 45.0) * 0.5 + (concrete_temp / 40.0) * 0.5
    eta_deviation = delay

    return np.array([
        ambient_temp,
        concrete_temp,
        humidity,
        wind,
        precip,
        traffic,
        delay,
        distance,
        batch_age,
        initial_slump,
        target_slump,
        volume,
        heat_exposure,
        eta_deviation
    ], dtype=np.float32)
