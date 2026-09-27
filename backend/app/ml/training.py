import numpy as np
import pandas as pd
from typing import Tuple, Dict, Any
from sklearn.ensemble import GradientBoostingRegressor, RandomForestRegressor
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_absolute_error, r2_score
from app.ml.features import FEATURE_NAMES


def generate_synthetic_rmc_dataset(n_samples: int = 1200, random_seed: int = 42) -> pd.DataFrame:
    """
    Generates realistic, deterministic Ready-Mix Concrete batch transit dataset
    incorporating Indian ambient temperature, traffic patterns, and hydration kinetics.
    """
    np.random.seed(random_seed)
    
    ambient_temp = np.random.uniform(24.0, 46.0, n_samples)
    concrete_temp = ambient_temp * 0.35 + np.random.uniform(22.0, 28.0, n_samples)
    humidity = np.random.uniform(25.0, 85.0, n_samples)
    wind_speed = np.random.uniform(5.0, 32.0, n_samples)
    precipitation = np.random.choice([0.0, 0.0, 0.0, 2.5, 8.0, 18.0], size=n_samples, p=[0.75, 0.1, 0.05, 0.05, 0.03, 0.02])
    traffic_congestion = np.random.beta(a=2.5, b=2.5, size=n_samples)
    expected_delay = traffic_congestion * np.random.uniform(5.0, 35.0, n_samples)
    distance = np.random.uniform(10.0, 45.0, n_samples)
    batch_age = np.random.uniform(15.0, 95.0, n_samples)
    initial_slump = np.random.normal(110.0, 5.0, n_samples)
    target_slump = np.full(n_samples, 105.0)
    concrete_volume = np.random.choice([6.0, 7.0, 8.0], size=n_samples)
    
    heat_exposure = (ambient_temp / 45.0) * 0.5 + (concrete_temp / 40.0) * 0.5
    eta_deviation = expected_delay

    # Target calculation based on concrete technology principles:
    # Hydration rate roughly doubles every 10°C rise.
    # Transit delay accelerates hydration and evaporation slump loss.
    temp_factor = np.maximum(0.0, (concrete_temp - 25.0) / 15.0) * 0.06
    time_factor = (batch_age / 90.0) * 0.08
    delay_factor = (expected_delay / 40.0) * 0.04
    precip_factor = np.where(precipitation > 5.0, -0.02, 0.0) # Uncontrolled rain dilutes mix / alters slump unpredictably
    
    # Slump retention ratio: initial ~ 0.98, degrades down to ~ 0.78
    retention_ratio = 1.0 - (temp_factor + time_factor + delay_factor + precip_factor)
    # Add small empirical noise
    retention_ratio += np.random.normal(0.0, 0.015, n_samples)
    retention_ratio = np.clip(retention_ratio, 0.70, 0.99)
    
    slump_loss_mm = initial_slump * (1.0 - retention_ratio)
    predicted_slump_mm = initial_slump - slump_loss_mm
    
    df = pd.DataFrame({
        "ambient_temp_c": ambient_temp,
        "concrete_temp_c": concrete_temp,
        "relative_humidity": humidity,
        "wind_speed_kmh": wind_speed,
        "precipitation_mm": precipitation,
        "traffic_congestion": traffic_congestion,
        "expected_delay_min": expected_delay,
        "distance_km": distance,
        "batch_age_min": batch_age,
        "initial_slump_mm": initial_slump,
        "target_slump_mm": target_slump,
        "concrete_volume_m3": concrete_volume,
        "heat_exposure_index": heat_exposure,
        "eta_deviation_min": eta_deviation,
        "slump_retention_ratio": retention_ratio,
        "slump_loss_mm": slump_loss_mm,
        "final_slump_mm": predicted_slump_mm
    })
    
    return df


def train_rmc_models() -> Tuple[GradientBoostingRegressor, RandomForestRegressor, Dict[str, Any]]:
    """Trains GradientBoostingRegressor and RandomForestRegressor on RMC data."""
    df = generate_synthetic_rmc_dataset(n_samples=1500)
    
    X = df[FEATURE_NAMES]
    y = df["slump_retention_ratio"]
    
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    
    # Primary model: Gradient Boosting Regressor (PRD.md Section 5.2)
    gbr = GradientBoostingRegressor(
        n_estimators=100,
        learning_rate=0.08,
        max_depth=4,
        random_state=42
    )
    gbr.fit(X_train, y_train)
    
    # Baseline model: Random Forest Regressor (PRD.md Section 5.2)
    rf = RandomForestRegressor(
        n_estimators=100,
        max_depth=5,
        random_state=42
    )
    rf.fit(X_train, y_train)
    
    # Evaluation
    gbr_preds = gbr.predict(X_test)
    rf_preds = rf.predict(X_test)
    
    metrics = {
        "gbr_mae": float(mean_absolute_error(y_test, gbr_preds)),
        "gbr_r2": float(r2_score(y_test, gbr_preds)),
        "rf_mae": float(mean_absolute_error(y_test, rf_preds)),
        "rf_r2": float(r2_score(y_test, rf_preds)),
        "feature_importances": dict(zip(FEATURE_NAMES, [float(x) for x in gbr.feature_importances_]))
    }
    
    return gbr, rf, metrics
