"""
Centralized Ready-Mix Concrete (RMC) Delivery Risk Engine.
Implements the multi-factor operational decision model specified in PRD.md Section 3.2-3.4,
Section 4.3-4.5, Section 5, and the operational decision thresholds.

ONE SOURCE OF TRUTH:
- Multi-factor evaluation across Heat, Travel, and Delivery/Slump dimensions.
- Diurnal time-of-day exposure window (Dispatch Time + Expected Transit = Arrival Time).
- RMC mix grade hydration kinetics sensitivity (M20 through M45).
- Worst material factor decision logic with conservative operational escalation.
- Strict anti-false-green safeguards.
- Clear, grounded explainability and targeted recommendations.
"""

from typing import Dict, Any, List, Optional, Tuple
import math
from datetime import datetime, timedelta
from app.config import settings
from app.models.schemas import RiskLevel, MitigationAction


# RMC Mix Grade Hydration Sensitivity Factors
# Higher grades (M40, M45) have higher cement content, higher hydration heat,
# and faster slump decay under transit temperatures.
CONCRETE_GRADE_FACTORS = {
    "M20": {"hydration_rate": 0.85, "heat_sensitivity": 0.85, "base_water_binder": 0.55},
    "M25": {"hydration_rate": 0.92, "heat_sensitivity": 0.90, "base_water_binder": 0.50},
    "M30": {"hydration_rate": 1.00, "heat_sensitivity": 1.00, "base_water_binder": 0.45},
    "M35": {"hydration_rate": 1.08, "heat_sensitivity": 1.08, "base_water_binder": 0.42},
    "M40": {"hydration_rate": 1.22, "heat_sensitivity": 1.20, "base_water_binder": 0.38},
    "M45": {"hydration_rate": 1.35, "heat_sensitivity": 1.32, "base_water_binder": 0.35},
}

DEFAULT_GRADE = "M35"


def parse_time_to_minutes(time_str: str) -> int:
    """Parses 'HH:MM' string into minutes since midnight."""
    try:
        parts = time_str.strip().split(":")
        hours = int(parts[0])
        minutes = int(parts[1]) if len(parts) > 1 else 0
        return (hours % 24) * 60 + (minutes % 60)
    except Exception:
        return 14 * 60  # Default to 14:00 (midday)


def format_minutes_to_time(total_min: int) -> str:
    """Formats minutes since midnight into 'HH:MM' string."""
    normalized = int(total_min) % (24 * 60)
    hours = normalized // 60
    minutes = normalized % 60
    return f"{hours:02d}:{minutes:02d}"


def calculate_diurnal_heat_exposure(dispatch_time_str: str, transit_minutes: float) -> Tuple[float, float, str]:
    """
    Computes diurnal exposure offset (°C) and expected arrival time.
    Midday peak solar heating in Indian conditions occurs between 11:30 and 16:30.
    Morning / late evening are cooler; night is baseline.
    Returns: (effective_temp_offset_c, solar_exposure_index, arrival_time_str)
    """
    dispatch_min = parse_time_to_minutes(dispatch_time_str)
    arrival_min = dispatch_min + int(transit_minutes)
    arrival_time_str = format_minutes_to_time(arrival_min)

    # Sample midday overlap in 15-minute slices across the transit window
    step = 15
    slices = max(1, int(transit_minutes // step))
    offsets = []
    solar_weights = []

    for i in range(slices):
        cur_min = (dispatch_min + i * step) % (24 * 60)
        cur_hour = cur_min / 60.0

        if 11.5 <= cur_hour <= 16.5:
            # Peak midday heat & high solar radiation (+2.5°C)
            offsets.append(2.5)
            solar_weights.append(1.30)
        elif (10.0 <= cur_hour < 11.5) or (16.5 < cur_hour <= 18.0):
            # Elevated shoulder period (+1.0°C)
            offsets.append(1.0)
            solar_weights.append(1.05)
        elif 6.0 <= cur_hour < 10.0:
            # Moderate morning (-1.5°C)
            offsets.append(-1.5)
            solar_weights.append(0.80)
        elif 18.0 < cur_hour <= 21.0:
            # Evening transition (-1.5°C)
            offsets.append(-1.5)
            solar_weights.append(0.70)
        else:
            # Night transit (21:00 - 06:00) (-3.5°C)
            offsets.append(-3.5)
            solar_weights.append(0.50)

    avg_offset = sum(offsets) / len(offsets)
    avg_solar_factor = sum(solar_weights) / len(solar_weights)
    solar_exposure_index = round(avg_solar_factor * (transit_minutes / 60.0), 2)

    return avg_offset, solar_exposure_index, arrival_time_str



def validate_input(data: Dict[str, Any]) -> Tuple[bool, List[str]]:
    """Validates delivery order input parameters for completeness and sanity."""
    errors = []

    # Check plant and project
    plant = str(data.get("plant_name") or data.get("plant_id") or "").strip()
    if not plant:
        errors.append("Dispatch plant origin must be specified")

    project = str(data.get("project_name") or data.get("project_id") or "").strip()
    if not project:
        errors.append("Destination project site must be specified")

    # Check transit time
    eta = float(data.get("eta_minutes", 0.0))
    elapsed = float(data.get("elapsed_minutes", 0.0))
    planned_transit = data.get("planned_transit_minutes")
    total_transit = float(planned_transit) if planned_transit is not None else (elapsed + eta)
    if total_transit <= 0.0:
        errors.append("Expected transit duration must be greater than zero")

    # Check slump
    initial_slump = float(data.get("initial_slump_mm", 110.0))
    if initial_slump <= 0.0:
        errors.append("Initial slump must be a positive value (typical 80-160 mm)")

    # Check volume
    volume = float(data.get("volume_m3", data.get("concrete_volume_m3", 6.0)))
    if volume <= 0.0:
        errors.append("Batch volume must be greater than zero")

    # Check ambient & concrete temperatures if provided
    amb_temp = float(data.get("ambient_temp_c", 34.0))
    conc_temp = float(data.get("concrete_temp_c", 32.0))
    if amb_temp < -10.0 or amb_temp > 60.0:
        errors.append(f"Ambient temperature ({amb_temp}°C) is outside physical operational range")
    if conc_temp < 5.0 or conc_temp > 55.0:
        errors.append(f"Concrete temperature ({conc_temp}°C) is outside physical operational range")

    return (len(errors) == 0, errors)


def calculate_delivery_risk(data: Dict[str, Any], ml_model_retention: Optional[float] = None) -> Dict[str, Any]:
    """
    Centralized Delivery Risk Calculation:
    1. Input validation & sanity
    2. Delivery exposure window (dispatch + transit = arrival)
    3. Concrete mix grade hydration kinetics
    4. Slump retention prediction (GBR ML prediction if available, else Physics-informed model)
    5. 3 Core Risk Dimensions (Heat, Travel, Delivery)
    6. Worst material factor evaluation & operational escalation
    7. Safeguards against false-green classifications
    8. Fact-based explainability & actionable recommendations
    """
    is_valid, validation_errors = validate_input(data)
    if not is_valid:
        return {
            "batch_id": str(data.get("batch_id", "RMC-DRAFT")),
            "predicted_slump_mm": 0.0,
            "slump_retention": 0.0,
            "heat_risk": 50.0,
            "travel_risk": 75.0,
            "delivery_risk": 75.0,
            "composite_risk": 70.0,
            "decision": RiskLevel.RISK_UNAVAILABLE,
            "risk_level": RiskLevel.RISK_UNAVAILABLE,
            "status_label": "RISK_UNAVAILABLE / DATA INSUFFICIENT",
            "is_approved": False,
            "primary_driver": f"Missing critical telemetry: {'; '.join(validation_errors)}",
            "contributors": validation_errors,
            "recommended_action": MitigationAction.RESCHEDULE_BATCH,
            "heat_risk_level": RiskLevel.RISK_UNAVAILABLE,
            "travel_risk_level": RiskLevel.RISK_UNAVAILABLE,
            "delivery_risk_level": RiskLevel.RISK_UNAVAILABLE,
            "planned_transit_minutes": 0.0,
            "expected_arrival_time": "--:--",
            "sla_status": "DATA_INSUFFICIENT",
            "worst_material_factor": "DATA INSUFFICIENT: Incomplete input telemetry",
            "is_data_insufficient": True,
            "model_version": "RMC-CORE-v2.0"
        }

    # Extract operational and telemetry parameters
    batch_id = str(data.get("batch_id", "RMC-DRAFT"))
    concrete_grade = str(data.get("concrete_grade", data.get("mix_type", DEFAULT_GRADE))).upper().strip()
    if concrete_grade not in CONCRETE_GRADE_FACTORS:
        concrete_grade = DEFAULT_GRADE
    grade_props = CONCRETE_GRADE_FACTORS[concrete_grade]

    initial_slump = float(data.get("initial_slump_mm", 110.0))
    target_slump = float(data.get("target_slump_mm", 105.0))
    ambient_temp = float(data.get("ambient_temp_c", 34.0))
    concrete_temp = float(data.get("concrete_temp_c", 32.0))
    humidity = float(data.get("relative_humidity", data.get("humidity_pct", 50.0)))
    traffic_idx = float(data.get("traffic_index", data.get("traffic_congestion", 0.45)))
    delay_min = float(data.get("expected_delay_min", data.get("delay_min", 0.0)))
    elapsed_min = float(data.get("elapsed_minutes", 0.0))
    eta_min = float(data.get("eta_minutes", 50.0))
    precip_prob = float(data.get("precipitation_prob", 0.0))
    dispatch_time_str = str(data.get("dispatch_time", data.get("desired_delivery_time", "14:00")))
    admixture = str(data.get("admixture_retarder", data.get("retarder_admixture", "None"))).strip()

    has_retarder = (admixture != "None" and admixture != "" and "none" not in admixture.lower())
    retarder_strength = 0.070 if "0.6" in admixture else (0.045 if has_retarder else 0.0)

    # Transit duration modeling
    planned_transit = data.get("planned_transit_minutes")
    if planned_transit is not None and float(planned_transit) > 0.0:
        base_transit_min = float(planned_transit)
        total_transit_min = base_transit_min + delay_min
    else:
        total_transit_min = elapsed_min + eta_min + delay_min
        base_transit_min = max(0.0, total_transit_min - delay_min)

    # Time-based delivery window exposure
    diurnal_offset, solar_exposure_idx, arrival_time_str = calculate_diurnal_heat_exposure(
        dispatch_time_str, total_transit_min
    )
    effective_ambient_temp = round(ambient_temp + diurnal_offset, 1)

    # Slump Kinetics Model (ML Prediction + Physics-Informed Domain Kinetics)
    grade_sens = grade_props["hydration_rate"]
    if ml_model_retention is not None:
        # ML model provided prediction: adjust for mix grade & chemical retarder
        base_ret = float(ml_model_retention)
        adjusted_decay = (1.0 - base_ret) * grade_sens
        if has_retarder:
            adjusted_decay = max(0.015, adjusted_decay - retarder_strength)
        retention_ratio = round(float(min(0.99, max(0.68, 1.0 - adjusted_decay))), 3)
    else:
        # Slump loss accelerates under:
        # 1. Total transit duration
        # 2. Concrete temperature above 30°C
        # 3. High ambient temperature & peak solar exposure
        # 4. Low relative humidity (rapid surface evaporation)
        # 5. High cementitious grade sensitivity (M40, M45)
        decay_time = total_transit_min * 0.00115 * grade_sens
        decay_conc_temp = max(0.0, concrete_temp - 30.0) * 0.0042 * grade_sens
        decay_amb_temp = max(0.0, effective_ambient_temp - 33.0) * 0.0028
        decay_humidity = max(0.0, 52.0 - humidity) * 0.0006

        raw_decay = decay_time + decay_conc_temp + decay_amb_temp + decay_humidity
        if has_retarder:
            raw_decay = max(0.015, raw_decay - retarder_strength)

        retention_ratio = round(float(min(0.99, max(0.68, 1.0 - raw_decay))), 3)

    predicted_slump = round(initial_slump * retention_ratio, 1)


    # =========================================================================
    # CORE DIMENSION 1: HEAT RISK (0 - 100)
    # =========================================================================
    # Driven by effective ambient temp across window, concrete temp, and transit exposure.
    # High temp during long transit substantially accelerates hydration.
    heat_score = (
        ((effective_ambient_temp - 28.0) / 16.0) * 45.0 +
        ((concrete_temp - 26.0) / 12.0) * 40.0 +
        (solar_exposure_idx / 2.0) * 15.0
    )
    if has_retarder:
        heat_score -= 16.0  # Retarder provides thermal hydration buffering

    heat_risk = round(float(min(98.0, max(10.0, heat_score))), 1)

    if heat_risk >= 80.0:
        heat_risk_level = RiskLevel.CRITICAL
    elif heat_risk >= 65.0:
        heat_risk_level = RiskLevel.HIGH_RISK
    elif heat_risk >= 45.0:
        heat_risk_level = RiskLevel.WATCH
    else:
        heat_risk_level = RiskLevel.SAFE

    # SAFEGUARD: Severe heat exposure cannot be SAFE
    if (effective_ambient_temp >= 40.0 or concrete_temp >= 35.0) and total_transit_min > 45.0:
        if heat_risk_level == RiskLevel.SAFE:
            heat_risk_level = RiskLevel.WATCH
            heat_risk = max(heat_risk, 48.0)

    # =========================================================================
    # CORE DIMENSION 2: TRAVEL RISK (0 - 100)
    # =========================================================================
    # Driven by planned transit vs PRD SLA (78 min), traffic congestion, and delay min.
    # Must evaluate the entire planned journey!
    sla_minutes = settings.SAFE_TRANSIT_MAX_MINUTES  # 78 min

    traffic_component = traffic_idx * 50.0
    delay_component = (delay_min / 25.0) * 35.0
    time_component = max(0.0, (total_transit_min - 60.0) / 20.0) * 30.0

    travel_score = traffic_component + delay_component + time_component
    travel_risk = round(float(min(98.0, max(12.0, travel_score))), 1)

    # TRAVEL SLA RULES:
    if total_transit_min > 85.0 or delay_min > 20.0:
        travel_risk_level = RiskLevel.CRITICAL
        travel_risk = max(travel_risk, 84.0)
        sla_status = "CRITICAL_BREACH"
    elif total_transit_min > sla_minutes or delay_min > 8.0:
        travel_risk_level = RiskLevel.HIGH_RISK
        travel_risk = max(travel_risk, 70.0)
        sla_status = "BREACH"
    elif total_transit_min > 65.0 or delay_min > 4.0 or traffic_idx > 0.60:
        travel_risk_level = RiskLevel.WATCH
        travel_risk = max(travel_risk, 48.0)
        sla_status = "APPROACHING_LIMIT"
    else:
        travel_risk_level = RiskLevel.SAFE
        sla_status = "COMPLIANT"

    # SAFEGUARD: If transit > SLA, travelRisk CANNOT be SAFE!
    if total_transit_min > sla_minutes and travel_risk_level == RiskLevel.SAFE:
        travel_risk_level = RiskLevel.HIGH_RISK
        travel_risk = max(travel_risk, 70.0)

    # =========================================================================
    # CORE DIMENSION 3: DELIVERY / SLUMP RISK (0 - 100)
    # =========================================================================
    # Driven by slump retention ratio deficit (<92% SLA), target slump gap, precipitation
    safe_slump_min = settings.SAFE_SLUMP_RETENTION_MIN_RATIO  # 0.92 (92%)

    slump_deficit = max(0.0, (safe_slump_min - retention_ratio) / 0.15) * 60.0
    time_slump_overage = max(0.0, (total_transit_min - sla_minutes) / 20.0) * 30.0
    precip_penalty = (precip_prob / 100.0) * 15.0

    delivery_score = slump_deficit + time_slump_overage + precip_penalty
    delivery_risk = round(float(min(98.0, max(10.0, delivery_score + 18.0))), 1)

    # DELIVERY SLA RULES:
    if retention_ratio < 0.85 or (predicted_slump < (target_slump - 15.0)):
        delivery_risk_level = RiskLevel.CRITICAL
        delivery_risk = max(delivery_risk, 86.0)
    elif retention_ratio < safe_slump_min or (predicted_slump < (target_slump - 8.0)):
        delivery_risk_level = RiskLevel.HIGH_RISK
        delivery_risk = max(delivery_risk, 72.0)
    elif retention_ratio < 0.94 or (total_transit_min > 70.0):
        delivery_risk_level = RiskLevel.WATCH
        delivery_risk = max(delivery_risk, 48.0)
    else:
        delivery_risk_level = RiskLevel.SAFE

    # SAFEGUARD: If predicted slump retention < 92%, deliveryRisk CANNOT be SAFE!
    if retention_ratio < safe_slump_min and delivery_risk_level == RiskLevel.SAFE:
        delivery_risk_level = RiskLevel.HIGH_RISK
        delivery_risk = max(delivery_risk, 72.0)


    # =========================================================================
    # OVERALL RISK DECISION: WORST MATERIAL FACTOR MODEL (Section 5)
    # =========================================================================
    # Implement conservative operational decision logic:
    # overallRisk = highest material risk factor with operational escalation.
    risk_rank = {
        RiskLevel.SAFE: 1,
        RiskLevel.WATCH: 2,
        RiskLevel.HIGH_RISK: 3,
        RiskLevel.CRITICAL: 4
    }

    dimension_levels = [heat_risk_level, travel_risk_level, delivery_risk_level]
    max_rank = max(risk_rank[lvl] for lvl in dimension_levels)

    watch_count = sum(1 for lvl in dimension_levels if lvl == RiskLevel.WATCH)
    high_count = sum(1 for lvl in dimension_levels if lvl == RiskLevel.HIGH_RISK)
    critical_count = sum(1 for lvl in dimension_levels if lvl == RiskLevel.CRITICAL)

    if max_rank == 4 or critical_count >= 1:
        decision = RiskLevel.CRITICAL
    elif max_rank == 3 or high_count >= 1:
        # If there are multiple HIGH risks or a HIGH + multiple WATCH, stays HIGH or escalates to CRITICAL
        if high_count >= 2 and total_transit_min > 85.0:
            decision = RiskLevel.CRITICAL
        else:
            decision = RiskLevel.HIGH_RISK
    elif watch_count >= 2:
        # Multi-factor compounding: two WATCH factors elevate to HIGH RISK
        decision = RiskLevel.HIGH_RISK
    elif max_rank == 2 or watch_count == 1:
        decision = RiskLevel.WATCH
    else:
        decision = RiskLevel.SAFE

    # PRD PATH A STRICT CHECK:
    # Transit <= 78 min AND Slump retention >= 92% AND ETA is on time (delay <= 5m)
    # AND no other severe risk.
    is_path_a_eligible = (
        total_transit_min <= sla_minutes and
        retention_ratio >= safe_slump_min and
        delay_min <= 5.0 and
        heat_risk_level in [RiskLevel.SAFE, RiskLevel.WATCH] and
        travel_risk_level == RiskLevel.SAFE and
        delivery_risk_level == RiskLevel.SAFE
    )

    if not is_path_a_eligible and decision == RiskLevel.SAFE:
        # Strict anti-false-green safeguard
        decision = RiskLevel.WATCH if (total_transit_min <= sla_minutes and retention_ratio >= 0.90) else RiskLevel.HIGH_RISK

    is_approved = (decision == RiskLevel.SAFE)

    # Composite risk score calculation (Weighted + worst factor floor)
    weighted_score = (
        settings.WEIGHT_HEAT_RISK * heat_risk +
        settings.WEIGHT_TRAVEL_RISK * travel_risk +
        settings.WEIGHT_DELIVERY_RISK * delivery_risk
    )
    # Ensure composite score reflects elevated risk level
    if decision == RiskLevel.CRITICAL:
        composite_risk = round(float(max(weighted_score, 82.0)), 1)
    elif decision == RiskLevel.HIGH_RISK:
        composite_risk = round(float(max(weighted_score, 68.0)), 1)
    elif decision == RiskLevel.WATCH:
        composite_risk = round(float(min(64.9, max(weighted_score, 45.0))), 1)
    else:
        composite_risk = round(float(min(38.0, weighted_score)), 1)

    # Grounded Explainability & Top Contributors (WHY)
    contributors = []
    worst_factors = []

    # Travel factors
    if total_transit_min > sla_minutes:
        diff = int(total_transit_min - sla_minutes)
        contributors.append(f"Predicted transit ({int(total_transit_min)} min) breaches {int(sla_minutes)} min operational SLA (+{diff} min)")
        worst_factors.append("Travel SLA breach")
    elif total_transit_min > 65.0:
        contributors.append(f"Planned transit ({int(total_transit_min)} min) approaches {int(sla_minutes)} min limit")

    if delay_min > 0:
        contributors.append(f"+{int(delay_min)} min traffic bottleneck delay along corridor")
        if delay_min > 8.0:
            worst_factors.append(f"Severe corridor traffic (+{int(delay_min)} min)")

    # Heat factors
    if effective_ambient_temp >= 38.0:
        contributors.append(f"{effective_ambient_temp}°C effective ambient temperature in {dispatch_time_str}–{arrival_time_str} midday window")
        worst_factors.append("Extreme ambient heat exposure")
    elif effective_ambient_temp >= 35.0:
        contributors.append(f"{effective_ambient_temp}°C elevated corridor temperature during transit window")

    if concrete_temp >= 33.5:
        contributors.append(f"{concrete_temp}°C concrete batch temperature accelerates hydration")
        if concrete_temp >= 34.5:
            worst_factors.append("High concrete mix temperature")

    # Delivery & Slump factors
    retention_loss_pct = round((1.0 - retention_ratio) * 100.0, 1)
    if retention_ratio < safe_slump_min:
        contributors.append(f"Slump retention drops to {round(retention_ratio * 100.0, 1)}% (below {int(safe_slump_min * 100)}% minimum SLA threshold)")
        worst_factors.append(f"Slump loss ({retention_loss_pct}% loss)")
    else:
        contributors.append(f"Predicted slump retention: {round(retention_ratio * 100.0, 1)}% ({predicted_slump} mm vs {target_slump} mm target)")

    # Grade specific factors
    if concrete_grade in ["M40", "M45"]:
        contributors.append(f"{concrete_grade} high-strength mix exhibits accelerated hydration kinetics under heat")

    if has_retarder:
        contributors.append(f"Chemical retarder ({admixture}) applied; hydration window extended by +25 min")

    if precip_prob > 25.0:
        contributors.append(f"{int(precip_prob)}% precipitation probability along route corridor")

    # Primary driver & Status label
    if decision == RiskLevel.SAFE:
        status_label = "DELIVERY ON TRACK"
        primary_driver = "Within operational tolerance (Transit <= 78m, Slump >= 92%)"
        recommended_action = None
        worst_material_factor = "None (All dimensions compliant)"
    elif decision == RiskLevel.WATCH:
        status_label = "MONITOR CLOSELY"
        primary_driver = worst_factors[0] if worst_factors else "Conditions approaching operational limits"
        recommended_action = None
        worst_material_factor = worst_factors[0] if worst_factors else "Corridor temperature/traffic margin"
    elif decision == RiskLevel.HIGH_RISK:
        status_label = "HIGH DELIVERY RISK"
        primary_driver = worst_factors[0] if worst_factors else "Operational threshold violation"
        worst_material_factor = worst_factors[0] if worst_factors else "Excessive transit / slump deterioration"
        # Select best targeted action
        if total_transit_min > sla_minutes or delay_min > 8.0:
            recommended_action = MitigationAction.CALCULATE_NEW_ROUTE
        elif heat_risk_level == RiskLevel.HIGH_RISK and not has_retarder:
            recommended_action = MitigationAction.ADD_RETARDER
        else:
            recommended_action = MitigationAction.RESCHEDULE_BATCH
    else:  # CRITICAL
        status_label = "CRITICAL TRANSIT FAILURE IMMINENT"
        primary_driver = f"Severe exposure: {', '.join(worst_factors[:2]) if worst_factors else 'Critical quality and SLA breach'}"
        worst_material_factor = worst_factors[0] if worst_factors else "Probable batch rejection"
        recommended_action = MitigationAction.CALCULATE_NEW_ROUTE

    return {
        "batch_id": batch_id,
        "predicted_slump_mm": predicted_slump,
        "slump_retention": retention_ratio,
        "heat_risk": heat_risk,
        "travel_risk": travel_risk,
        "delivery_risk": delivery_risk,
        "composite_risk": composite_risk,
        "decision": decision,
        "status_label": status_label,
        "is_approved": is_approved,
        "primary_driver": primary_driver,
        "contributors": contributors,
        "recommended_action": recommended_action,
        "heat_risk_level": heat_risk_level,
        "travel_risk_level": travel_risk_level,
        "delivery_risk_level": delivery_risk_level,
        "planned_transit_minutes": round(total_transit_min, 1),
        "expected_arrival_time": arrival_time_str,
        "sla_status": sla_status,
        "worst_material_factor": worst_material_factor,
        "is_data_insufficient": False,
        "model_version": "RMC-CORE-v2.0"
    }
