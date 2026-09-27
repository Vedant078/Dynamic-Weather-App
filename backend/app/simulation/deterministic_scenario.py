from typing import Dict, Any, List
from app.models.schemas import RiskLevel, BatchStatus, MitigationAction
from app.repositories.batch_repository import batch_repo
from app.ml.model import model_manager


class DeterministicSimulator:
    """
    Implements the reproducible, step-by-step SIH demo scenario for Batch RMC-204
    as required by PRD.md Section 8.16 & Appendix C.
    """
    
    # 5 discrete deterministic states for demo progression
    STEPS = [
        {
            "step_index": 0,
            "phase_name": "DISPATCH & NOMINAL TRANSIT",
            "elapsed_minutes": 22.0,
            "eta_minutes": 32.0,
            "delay_min": 0.0,
            "distance_remaining_km": 16.4,
            "ambient_temp_c": 35.0,
            "concrete_temp_c": 32.4,
            "traffic_index": 0.40,
            "precipitation_prob": 10.0,
            "slump_mm": 106.0,
            "slump_retention_ratio": 0.964,
            "risk_level": RiskLevel.SAFE,
            "status": BatchStatus.IN_TRANSIT,
            "active_route_id": "route-a",
            "narrative": "Truck in transit on Route A. Concrete hydration and temperature within safe baseline envelope."
        },
        {
            "step_index": 1,
            "phase_name": "CORRIDOR TRAFFIC BUILDING",
            "elapsed_minutes": 34.0,
            "eta_minutes": 36.0,
            "delay_min": 7.0,
            "distance_remaining_km": 11.2,
            "ambient_temp_c": 37.8,
            "concrete_temp_c": 33.6,
            "traffic_index": 0.65,
            "precipitation_prob": 25.0,
            "slump_mm": 103.5,
            "slump_retention_ratio": 0.941,
            "risk_level": RiskLevel.WATCH,
            "status": BatchStatus.IN_TRANSIT,
            "active_route_id": "route-a",
            "narrative": "Traffic congestion building near Nana Chiloda. Transit time extending; monitoring slump retention."
        },
        {
            "step_index": 2,
            "phase_name": "HEAT EXPOSURE & CONGESTION SURGE",
            "elapsed_minutes": 46.0,
            "eta_minutes": 36.0,
            "delay_min": 14.0,
            "distance_remaining_km": 7.8,
            "ambient_temp_c": 40.2,
            "concrete_temp_c": 34.8,
            "traffic_index": 0.85,
            "precipitation_prob": 68.0,
            "slump_mm": 98.0,
            "slump_retention_ratio": 0.891,
            "risk_level": RiskLevel.HIGH_RISK,
            "status": BatchStatus.AT_RISK,
            "active_route_id": "route-a",
            "narrative": "CRITICAL RISK THRESHOLD BREACH: Projected transit (82 min) exceeds 78 min limit. Slump retention dropped to 89.1%. Rain cloud approaching route."
        },
        {
            "step_index": 3,
            "phase_name": "ALTERNATIVE ROUTE B APPLIED",
            "elapsed_minutes": 50.0,
            "eta_minutes": 16.0,
            "delay_min": 2.0,
            "distance_remaining_km": 9.4,
            "ambient_temp_c": 36.2,
            "concrete_temp_c": 34.2,
            "traffic_index": 0.35,
            "precipitation_prob": 12.0,
            "slump_mm": 102.0,
            "slump_retention_ratio": 0.927,
            "risk_level": RiskLevel.SAFE,
            "status": BatchStatus.REROUTED,
            "active_route_id": "route-b",
            "narrative": "Operator accepted Route B recommendation. Truck diverted to Airport Bypass. Transit normalized, slump retention protected at >92%."
        },
        {
            "step_index": 4,
            "phase_name": "SITE ARRIVAL & VERIFIED DELIVERY",
            "elapsed_minutes": 66.0,
            "eta_minutes": 0.0,
            "delay_min": 0.0,
            "distance_remaining_km": 0.0,
            "ambient_temp_c": 36.0,
            "concrete_temp_c": 34.0,
            "traffic_index": 0.20,
            "precipitation_prob": 0.0,
            "slump_mm": 101.5,
            "slump_retention_ratio": 0.923,
            "risk_level": RiskLevel.SAFE,
            "status": BatchStatus.DELIVERED,
            "active_route_id": "route-b",
            "narrative": "Batch arrived at Project Site 07. Slump verified at 101.5 mm. Delivery accepted. Avoided financial loss of ₹1.68 Lakhs recorded."
        }
    ]

    def __init__(self):
        self.current_step_idx = 0

    def get_current_step(self) -> Dict[str, Any]:
        return self.STEPS[self.current_step_idx]

    def set_step(self, step_idx: int) -> Dict[str, Any]:
        self.current_step_idx = max(0, min(step_idx, len(self.STEPS) - 1))
        step = self.STEPS[self.current_step_idx]
        
        # Sync with batch repository
        b204 = batch_repo.get_batch("batch-rmc-204")
        if b204:
            updates = {
                "elapsed_minutes": step["elapsed_minutes"],
                "eta_minutes": step["eta_minutes"],
                "distance_remaining_km": step["distance_remaining_km"],
                "ambient_temp_c": step["ambient_temp_c"],
                "concrete_temp_c": step["concrete_temp_c"],
                "traffic_index": step["traffic_index"],
                "precipitation_prob": step["precipitation_prob"],
                "current_slump_mm": step["slump_mm"],
                "slump_retention_ratio": step["slump_retention_ratio"],
                "status": step["status"],
                "active_route_id": step["active_route_id"]
            }
            
            # Predict risk using ML model manager
            pred = model_manager.predict_batch_risk({
                "ambient_temp_c": step["ambient_temp_c"],
                "concrete_temp_c": step["concrete_temp_c"],
                "traffic_index": step["traffic_index"],
                "expected_delay_min": step["delay_min"],
                "elapsed_minutes": step["elapsed_minutes"],
                "eta_minutes": step["eta_minutes"],
                "initial_slump_mm": 110.0,
                "target_slump_mm": 105.0,
                "precipitation_prob": step["precipitation_prob"]
            })
            
            updates.update({
                "risk_level": pred["decision"],
                "heat_risk": pred["heat_risk"],
                "travel_risk": pred["travel_risk"],
                "delivery_risk": pred["delivery_risk"],
                "composite_risk": pred["composite_risk"],
                "primary_driver": pred["primary_driver"],
                "risk_factors": pred["contributors"],
                "recommended_action": pred["recommended_action"]
            })
            
            batch_repo.update_batch("batch-rmc-204", updates)

        return {
            "current_step": self.current_step_idx,
            "total_steps": len(self.STEPS),
            "step_data": self.get_current_step()
        }

    def next_step(self) -> Dict[str, Any]:
        return self.set_step(self.current_step_idx + 1)

    def reset(self) -> Dict[str, Any]:
        return self.set_step(0)


simulator = DeterministicSimulator()
