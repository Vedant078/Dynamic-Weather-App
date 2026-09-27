import pytest
from app.ml.model import model_manager
from app.services.rmc_risk_engine import calculate_delivery_risk
from app.models.schemas import RiskLevel, MitigationAction, BatchStatus
from app.repositories.batch_repository import batch_repo
from app.simulation.deterministic_scenario import simulator


# =============================================================================
# MANDATORY TEST 1: SAFE PATH (PRD Section 3.4 & Prompt Test 1)
# =============================================================================
def test_validation_case_1_safe_path():
    """
    TEST 1 — SAFE:
    Transit = 60 min (<= 78 min)
    Slump retention >= 92% (e.g. 96%)
    ETA = on time (delay <= 5 min)
    Moderate weather (32°C ambient, 30°C concrete)
    Expected: SAFE (is_approved = True)
    """
    input_data = {
        "plant_name": "Ahmedabad Plant 01",
        "project_name": "Project Site 07",
        "ambient_temp_c": 32.0,
        "concrete_temp_c": 30.0,
        "traffic_index": 0.25,
        "expected_delay_min": 0.0,
        "elapsed_minutes": 25.0,
        "eta_minutes": 35.0,  # Total transit = 60 min <= 78 min
        "initial_slump_mm": 110.0,
        "target_slump_mm": 105.0,
        "precipitation_prob": 0.0,
        "concrete_grade": "M30",
        "dispatch_time": "08:30"
    }
    res = model_manager.predict_batch_risk(input_data)
    
    assert res["is_approved"] is True
    assert res["decision"] == RiskLevel.SAFE
    assert res["slump_retention"] >= 0.92
    assert res["travel_risk_level"] == RiskLevel.SAFE
    assert res["delivery_risk_level"] == RiskLevel.SAFE
    assert res["status_label"] == "DELIVERY ON TRACK"


# =============================================================================
# MANDATORY TEST 2: SLA BREACH (Prompt Test 2)
# =============================================================================
def test_validation_case_2_sla_breach():
    """
    TEST 2 — SLA BREACH:
    Transit = 95 min (SLA = 78 min)
    Slump retention = 95%
    Expected:
    Travel Risk = HIGH (or CRITICAL)
    Overall Risk != SAFE (Must be HIGH_RISK or CRITICAL)
    """
    input_data = {
        "plant_name": "Ahmedabad Plant 01",
        "project_name": "Gift City Tower B",
        "ambient_temp_c": 32.0,
        "concrete_temp_c": 30.0,
        "traffic_index": 0.65,
        "expected_delay_min": 15.0,
        "planned_transit_minutes": 80.0,  # Total transit = 80 + 15 = 95 min > 78 min!
        "initial_slump_mm": 120.0,
        "target_slump_mm": 100.0,
        "concrete_grade": "M30"
    }
    # Pass explicit 95% retention to isolate transit SLA effect
    res = calculate_delivery_risk(input_data, ml_model_retention=0.95)
    
    assert res["travel_risk_level"] in [RiskLevel.HIGH_RISK, RiskLevel.CRITICAL]
    assert res["travel_risk"] >= 68.0
    assert res["decision"] != RiskLevel.SAFE
    assert res["decision"] in [RiskLevel.HIGH_RISK, RiskLevel.CRITICAL]
    assert res["is_approved"] is False
    assert res["sla_status"] in ["BREACH", "CRITICAL_BREACH"]


# =============================================================================
# MANDATORY TEST 3: SLUMP FAILURE (Prompt Test 3)
# =============================================================================
def test_validation_case_3_slump_failure():
    """
    TEST 3 — SLUMP FAILURE:
    Transit = 70 min (<= 78 min)
    Predicted slump retention = 88% (< 92% SLA threshold)
    Expected:
    Delivery Risk = HIGH
    Overall Risk != SAFE
    """
    input_data = {
        "plant_name": "Ahmedabad Plant 01",
        "project_name": "Metro Pier 142",
        "ambient_temp_c": 34.0,
        "concrete_temp_c": 32.0,
        "traffic_index": 0.35,
        "expected_delay_min": 0.0,
        "planned_transit_minutes": 70.0,
        "initial_slump_mm": 110.0,
        "target_slump_mm": 105.0,
        "concrete_grade": "M35"
    }
    # Pass 88% retention to test decision logic
    res = calculate_delivery_risk(input_data, ml_model_retention=0.88)
    
    assert res["delivery_risk_level"] in [RiskLevel.HIGH_RISK, RiskLevel.CRITICAL]
    assert res["delivery_risk"] >= 68.0
    assert res["decision"] != RiskLevel.SAFE
    assert res["decision"] in [RiskLevel.HIGH_RISK, RiskLevel.CRITICAL]
    assert res["is_approved"] is False


# =============================================================================
# MANDATORY TEST 4: HEAT EXPOSURE (Prompt Test 4)
# =============================================================================
def test_validation_case_4_heat_exposure():
    """
    TEST 4 — HEAT EXPOSURE:
    High temperature (ambient 42°C, concrete 36°C)
    Long transit (75 min) in peak midday heat (14:00)
    Expected:
    Heat Risk elevated (HIGH_RISK or CRITICAL)
    Overall Risk reflects exposure (!= SAFE)
    """
    input_data = {
        "plant_name": "Ahmedabad Plant 01",
        "project_name": "Riverfront Phase 2",
        "ambient_temp_c": 42.0,
        "concrete_temp_c": 36.0,
        "traffic_index": 0.30,
        "expected_delay_min": 0.0,
        "planned_transit_minutes": 75.0,
        "dispatch_time": "14:00",  # Midday peak heat
        "initial_slump_mm": 115.0,
        "target_slump_mm": 105.0,
        "concrete_grade": "M40"
    }
    res = model_manager.predict_batch_risk(input_data)
    
    assert res["heat_risk_level"] in [RiskLevel.HIGH_RISK, RiskLevel.CRITICAL]
    assert res["heat_risk"] >= 65.0
    assert res["decision"] != RiskLevel.SAFE
    assert res["is_approved"] is False


# =============================================================================
# MANDATORY TEST 5: MULTI-FACTOR HIGH / CRITICAL RISK (Prompt Test 5)
# =============================================================================
def test_validation_case_5_multi_factor():
    """
    TEST 5 — MULTI-FACTOR:
    High heat (41.5°C ambient, 36.2°C concrete)
    Traffic delay (+18 min)
    Transit > SLA (85 min > 78 min)
    Slump retention < threshold
    Expected:
    CRITICAL or HIGH RISK according to PRD thresholds
    Absolutely NOT SAFE.
    """
    input_data = {
        "plant_name": "Ahmedabad Plant 01",
        "project_name": "Gift City Expansion",
        "ambient_temp_c": 41.5,
        "concrete_temp_c": 36.2,
        "traffic_index": 0.82,
        "expected_delay_min": 18.0,
        "elapsed_minutes": 55.0,
        "eta_minutes": 30.0,  # Total transit = 85 min > 78 min
        "initial_slump_mm": 110.0,
        "target_slump_mm": 105.0,
        "precipitation_prob": 60.0,
        "concrete_grade": "M45",
        "dispatch_time": "14:15"
    }
    res = model_manager.predict_batch_risk(input_data)
    
    assert res["is_approved"] is False
    assert res["decision"] in [RiskLevel.HIGH_RISK, RiskLevel.CRITICAL]
    assert len(res["contributors"]) >= 2
    assert res["recommended_action"] == MitigationAction.CALCULATE_NEW_ROUTE
    assert res["worst_material_factor"] is not None


# =============================================================================
# MANDATORY TEST 6: MITIGATION APPLICATION (Prompt Test 6)
# =============================================================================
def test_validation_case_6_mitigation():
    """
    TEST 6 — MITIGATION:
    Initial condition: HIGH RISK on Route A (transit 85 min, delay 17 min, high heat).
    Apply Route B mitigation (expressway bypass: transit 60 min, delay 2 min) + 0.4% retarder.
    Expected:
    Risk recalculates.
    Transit drops <= 78 min, slump retention protected >= 92%.
    Risk decreases to SAFE or WATCH.
    """
    # 1. Initial High Risk state
    high_risk_input = {
        "plant_name": "Ahmedabad Plant 01",
        "project_name": "Gift City Tower B",
        "ambient_temp_c": 38.0,
        "concrete_temp_c": 34.0,
        "traffic_index": 0.78,
        "expected_delay_min": 17.0,
        "planned_transit_minutes": 68.0,  # Total = 85 min > 78 min
        "initial_slump_mm": 115.0,
        "target_slump_mm": 105.0,
        "admixture_retarder": "None",
        "concrete_grade": "M35"
    }
    initial_res = model_manager.predict_batch_risk(high_risk_input)
    assert initial_res["decision"] in [RiskLevel.HIGH_RISK, RiskLevel.CRITICAL]

    # 2. Mitigated state: Apply Route B bypass (transit 60m, delay 2m) + Retarder admixture
    mitigated_input = {
        **high_risk_input,
        "traffic_index": 0.32,
        "expected_delay_min": 2.0,
        "planned_transit_minutes": 58.0,  # Total = 60 min <= 78 min
        "admixture_retarder": "0.4% by wt",
        "concrete_temp_c": 33.0
    }
    mitigated_res = model_manager.predict_batch_risk(mitigated_input)
    
    assert mitigated_res["decision"] in [RiskLevel.SAFE, RiskLevel.WATCH]
    assert mitigated_res["composite_risk"] < initial_res["composite_risk"]
    assert mitigated_res["slump_retention"] > initial_res["slump_retention"]
    assert mitigated_res["planned_transit_minutes"] <= 78.0


# =============================================================================
# TEST 7: CONCRETE GRADE SENSITIVITY (Prompt Section 8)
# =============================================================================
def test_concrete_grade_sensitivity():
    """
    Higher grade mixes (M45) generate higher hydration heat and have higher
    cementitious content, leading to accelerated slump loss compared to M20.
    """
    base_params = {
        "plant_name": "Ahmedabad Plant 01",
        "project_name": "Riverfront Phase 2",
        "ambient_temp_c": 37.0,
        "concrete_temp_c": 33.0,
        "traffic_index": 0.40,
        "expected_delay_min": 4.0,
        "planned_transit_minutes": 65.0,
        "initial_slump_mm": 120.0,
        "target_slump_mm": 100.0
    }
    
    m20_res = calculate_delivery_risk({**base_params, "concrete_grade": "M20"})
    m45_res = calculate_delivery_risk({**base_params, "concrete_grade": "M45"})
    
    # M45 must show lower slump retention (higher decay) than M20
    assert m45_res["slump_retention"] < m20_res["slump_retention"]
    assert m45_res["delivery_risk"] >= m20_res["delivery_risk"]


# =============================================================================
# TEST 8: TIME-BASED DELIVERY WINDOW (Prompt Section 7)
# =============================================================================
def test_time_based_delivery_window_exposure():
    """
    Delivery window across peak midday heat (14:00 - 15:15) must experience
    higher heat exposure than early morning window (07:00 - 08:15).
    """
    base_params = {
        "plant_name": "Ahmedabad Plant 01",
        "project_name": "Gift City",
        "ambient_temp_c": 36.0,
        "concrete_temp_c": 32.0,
        "traffic_index": 0.35,
        "expected_delay_min": 0.0,
        "planned_transit_minutes": 65.0,
        "initial_slump_mm": 115.0,
        "target_slump_mm": 105.0,
        "concrete_grade": "M35"
    }
    
    morning_res = calculate_delivery_risk({**base_params, "dispatch_time": "07:00"})
    midday_res = calculate_delivery_risk({**base_params, "dispatch_time": "14:00"})
    
    assert midday_res["heat_risk"] > morning_res["heat_risk"]
    assert midday_res["expected_arrival_time"] == "15:05"
    assert morning_res["expected_arrival_time"] == "08:05"


# =============================================================================
# TEST 9: EDGE CASES & MISSING DATA (Prompt Section 22)
# =============================================================================
def test_edge_cases_never_silently_safe():
    """
    If required data is missing or invalid:
    Never silently classify as SAFE. Must flag DATA INSUFFICIENT.
    """
    # 1. Missing plant origin
    missing_plant = calculate_delivery_risk({
        "plant_name": "",
        "project_name": "Site 01",
        "planned_transit_minutes": 45.0
    })
    assert missing_plant["decision"] != RiskLevel.SAFE
    assert missing_plant["is_data_insufficient"] is True
    assert "DATA INSUFFICIENT" in missing_plant["status_label"]

    # 2. Zero transit time
    zero_transit = calculate_delivery_risk({
        "plant_name": "Plant 01",
        "project_name": "Site 01",
        "planned_transit_minutes": 0.0,
        "elapsed_minutes": 0.0,
        "eta_minutes": 0.0
    })
    assert zero_transit["decision"] != RiskLevel.SAFE
    assert zero_transit["is_data_insufficient"] is True

    # 3. Missing destination project
    missing_dest = calculate_delivery_risk({
        "plant_name": "Plant 01",
        "project_name": "",
        "planned_transit_minutes": 50.0
    })
    assert missing_dest["decision"] != RiskLevel.SAFE
    assert missing_dest["is_data_insufficient"] is True


# =============================================================================
# DEMO SIMULATION & ML FEEDBACK TESTS
# =============================================================================
def test_deterministic_simulation_progression():
    """
    Verifies that the 5-step deterministic demo simulation transitions:
    Step 0: SAFE
    Step 1: WATCH
    Step 2: HIGH_RISK
    Step 3: Route B Applied -> SAFE
    Step 4: DELIVERED -> SAFE
    """
    # Step 0
    s0 = simulator.set_step(0)
    assert s0["step_data"]["risk_level"] == RiskLevel.SAFE
    
    # Step 1
    s1 = simulator.set_step(1)
    assert s1["step_data"]["risk_level"] == RiskLevel.WATCH
    
    # Step 2
    s2 = simulator.set_step(2)
    assert s2["step_data"]["risk_level"] == RiskLevel.HIGH_RISK
    
    # Step 3
    s3 = simulator.set_step(3)
    assert s3["step_data"]["status"] == BatchStatus.REROUTED
    assert s3["step_data"]["risk_level"] == RiskLevel.SAFE
    
    # Step 4
    s4 = simulator.set_step(4)
    assert s4["step_data"]["status"] == BatchStatus.DELIVERED


def test_delivery_outcome_and_ml_feedback():
    """
    Tests outcome recording, avoided loss calculation, and appending
    to the ML retraining feedback loop dataset.
    """
    outcome_req = {
        "batch_id": "batch-rmc-204",
        "outcome": "accepted",
        "site_slump_mm": 102.0,
        "actual_transit_minutes": 66.0,
        "site_concrete_temp_c": 33.8,
        "financial_impact_inr": 168000.0,
        "financial_type": "AVOIDED_LOSS"
    }
    initial_dataset_len = len(batch_repo.ml_feedback_dataset)
    res = batch_repo.record_outcome(outcome_req)
    
    assert "outcome_id" in res
    assert len(batch_repo.ml_feedback_dataset) == initial_dataset_len + 1
    latest_record = batch_repo.ml_feedback_dataset[-1]
    assert latest_record["batch_id"] == "batch-rmc-204"
    assert latest_record["outcome_class"] == "accepted"
