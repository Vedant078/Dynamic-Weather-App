from typing import Dict, List, Optional, Any
from datetime import datetime, timezone
import uuid
from app.models.schemas import (
    BatchDetail, BatchStatus, RiskLevel, MitigationAction,
    RouteOption, Waypoint, OutcomeResponse
)


class InMemoryBatchRepository:
    def __init__(self):
        self.batches: Dict[str, Dict[str, Any]] = {}
        self.routes: Dict[str, List[Dict[str, Any]]] = {}
        self.outcomes: List[Dict[str, Any]] = []
        self.ml_feedback_dataset: List[Dict[str, Any]] = []
        self._seed_initial_data()

    def _seed_initial_data(self):
        # Primary Demo Batch: RMC-204 (Ahmedabad to Gift City corridor)
        b204_id = "batch-rmc-204"
        self.batches[b204_id] = {
            "batch_id": b204_id,
            "batch_code": "RMC-204",
            "plant_id": "plant-001",
            "plant_name": "Ahmedabad Plant 01 (Naroda)",
            "project_id": "project-007",
            "project_name": "Project Site 07 (Gift City Expansion)",
            "volume_m3": 6.0,
            "target_slump_mm": 105.0,
            "initial_slump_mm": 110.0,
            "current_slump_mm": 106.0,
            "slump_retention_ratio": 0.964,
            "concrete_temp_c": 32.4,
            "ambient_temp_c": 35.0,
            "elapsed_minutes": 22.0,
            "eta_minutes": 32.0,
            "original_eta_minutes": 32.0,
            "distance_remaining_km": 16.4,
            "total_distance_km": 28.5,
            "traffic_index": 0.45,
            "precipitation_prob": 15.0,
            "status": BatchStatus.IN_TRANSIT,
            "risk_level": RiskLevel.SAFE,
            "heat_risk": 34.0,
            "travel_risk": 28.0,
            "delivery_risk": 32.0,
            "composite_risk": 31.4,
            "primary_driver": "Transit on schedule within safe slump envelope",
            "risk_factors": [
                "Ambient temperature 35.0°C within tolerance",
                "Slump retention currently 96.4%",
                "Route A moving normally"
            ],
            "recommended_action": None,
            "active_route_id": "route-a",
            "created_at": "2026-09-25T14:00:00Z",
            "dispatched_at": "2026-09-25T14:10:00Z"
        }

        # Secondary active batch: RMC-201 (Watch state)
        b201_id = "batch-rmc-201"
        self.batches[b201_id] = {
            "batch_id": b201_id,
            "batch_code": "RMC-201",
            "plant_id": "plant-001",
            "plant_name": "Ahmedabad Plant 01 (Naroda)",
            "project_id": "project-003",
            "project_name": "Project Site 03 (Sabarmati Riverfront)",
            "volume_m3": 7.0,
            "target_slump_mm": 110.0,
            "initial_slump_mm": 115.0,
            "current_slump_mm": 105.0,
            "slump_retention_ratio": 0.913,
            "concrete_temp_c": 35.2,
            "ambient_temp_c": 38.5,
            "elapsed_minutes": 48.0,
            "eta_minutes": 26.0,
            "original_eta_minutes": 18.0,
            "distance_remaining_km": 8.2,
            "total_distance_km": 22.0,
            "traffic_index": 0.68,
            "precipitation_prob": 5.0,
            "status": BatchStatus.AT_RISK,
            "risk_level": RiskLevel.WATCH,
            "heat_risk": 64.0,
            "travel_risk": 58.0,
            "delivery_risk": 55.0,
            "composite_risk": 58.6,
            "primary_driver": "Approaching safe slump threshold (91.3%)",
            "risk_factors": [
                "+8 min congestion delay on Ashram Road",
                "Concrete temp elevated at 35.2°C"
            ],
            "recommended_action": None,
            "active_route_id": "route-201-default",
            "created_at": "2026-09-25T13:30:00Z",
            "dispatched_at": "2026-09-25T13:42:00Z"
        }

        # Secondary active batch: RMC-208 (On Track)
        b208_id = "batch-rmc-208"
        self.batches[b208_id] = {
            "batch_id": b208_id,
            "batch_code": "RMC-208",
            "plant_id": "plant-002",
            "plant_name": "Ahmedabad Plant 02 (Sanand)",
            "project_id": "project-012",
            "project_name": "Project Site 12 (Ring Road Logistics Hub)",
            "volume_m3": 6.0,
            "target_slump_mm": 100.0,
            "initial_slump_mm": 110.0,
            "current_slump_mm": 107.0,
            "slump_retention_ratio": 0.972,
            "concrete_temp_c": 31.8,
            "ambient_temp_c": 34.0,
            "elapsed_minutes": 14.0,
            "eta_minutes": 22.0,
            "original_eta_minutes": 22.0,
            "distance_remaining_km": 14.8,
            "total_distance_km": 19.5,
            "traffic_index": 0.28,
            "precipitation_prob": 0.0,
            "status": BatchStatus.IN_TRANSIT,
            "risk_level": RiskLevel.SAFE,
            "heat_risk": 28.0,
            "travel_risk": 22.0,
            "delivery_risk": 25.0,
            "composite_risk": 25.0,
            "primary_driver": "Optimal transit corridor, low temperature",
            "risk_factors": ["Nominal transit parameters"],
            "recommended_action": None,
            "active_route_id": "route-208-default",
            "created_at": "2026-09-25T14:15:00Z",
            "dispatched_at": "2026-09-25T14:25:00Z"
        }

        # Route Alternatives for RMC-204 (PRD.md Section 8.6 & 4.8)
        self.routes[b204_id] = [
            {
                "route_id": "route-a",
                "route_name": "Route A (SP Ring Road via Chiloda)",
                "is_recommended": False,
                "eta_minutes": 61.0,  # increases to 82 min under traffic
                "distance_km": 28.2,
                "delivery_risk": 78.0,
                "heat_risk": 74.0,
                "travel_risk": 82.0,
                "traffic_level": "Severe Congestion (+14m delay)",
                "weather_summary": "40.2°C ambient, 68% rain cell approaching",
                "trade_off_explanation": "Shortest distance but corridor bottleneck adds 14 min delay and causes slump retention to drop below 90%.",
                "waypoints": [
                    {"lat": 23.0225, "lng": 72.5714, "name": "Naroda Plant"},
                    {"lat": 23.0550, "lng": 72.5950, "name": "Nana Chiloda Circle (Delay Zone)"},
                    {"lat": 23.0900, "lng": 72.6100, "name": "Gift City Site 07"}
                ]
            },
            {
                "route_id": "route-b",
                "route_name": "Route B (Airport Bypass Expressway - Recommended)",
                "is_recommended": True,
                "eta_minutes": 52.0,  # 9 minutes faster transit under congestion
                "distance_km": 30.8,
                "delivery_risk": 36.0,
                "heat_risk": 42.0,
                "travel_risk": 30.0,
                "traffic_level": "Free Flow (Bypass corridor)",
                "weather_summary": "35.5°C ambient, dry segment",
                "trade_off_explanation": "+2.6 km longer distance, but saves 9 minutes of transit and preserves slump retention at 94.2%.",
                "waypoints": [
                    {"lat": 23.0225, "lng": 72.5714, "name": "Naroda Plant"},
                    {"lat": 23.0680, "lng": 72.6350, "name": "Airport Expressway Corridor"},
                    {"lat": 23.0900, "lng": 72.6100, "name": "Gift City Site 07"}
                ]
            },
            {
                "route_id": "route-c",
                "route_name": "Route C (Old Highway via Gandhinagar)",
                "is_recommended": False,
                "eta_minutes": 68.0,
                "distance_km": 33.5,
                "delivery_risk": 85.0,
                "heat_risk": 78.0,
                "travel_risk": 89.0,
                "traffic_level": "Urban Traffic & Surface Signals",
                "weather_summary": "39.8°C, heavy humidity",
                "trade_off_explanation": "Excessive transit exposure exceeds 78 min safe window.",
                "waypoints": [
                    {"lat": 23.0225, "lng": 72.5714, "name": "Naroda Plant"},
                    {"lat": 23.0450, "lng": 72.5500, "name": "Old Highway Junction"},
                    {"lat": 23.0900, "lng": 72.6100, "name": "Gift City Site 07"}
                ]
            }
        ]

    def get_all_batches(self) -> List[Dict[str, Any]]:
        return list(self.batches.values())

    def get_batch(self, batch_id: str) -> Optional[Dict[str, Any]]:
        return self.batches.get(batch_id)

    def update_batch(self, batch_id: str, updates: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        if batch_id in self.batches:
            self.batches[batch_id].update(updates)
            return self.batches[batch_id]
        return None

    def get_routes_for_batch(self, batch_id: str) -> List[Dict[str, Any]]:
        return self.routes.get(batch_id, [])

    def record_outcome(self, outcome_data: Dict[str, Any]) -> Dict[str, Any]:
        outcome_id = f"outcome-{uuid.uuid4().hex[:8]}"
        outcome_data["outcome_id"] = outcome_id
        outcome_data["recorded_at"] = datetime.now(timezone.utc).isoformat()
        self.outcomes.append(outcome_data)
        
        # ML feedback loop: append to training dataset
        batch_id = outcome_data.get("batch_id")
        batch = self.get_batch(batch_id)
        if batch:
            ml_record = {
                "outcome_id": outcome_id,
                "batch_id": batch_id,
                "ambient_temp_c": batch.get("ambient_temp_c"),
                "concrete_temp_c": batch.get("concrete_temp_c"),
                "traffic_congestion": batch.get("traffic_index"),
                "actual_transit_min": outcome_data.get("actual_transit_minutes"),
                "initial_slump_mm": batch.get("initial_slump_mm"),
                "target_slump_mm": batch.get("target_slump_mm"),
                "site_slump_mm": outcome_data.get("site_slump_mm"),
                "slump_retention_ratio": outcome_data.get("site_slump_mm") / batch.get("initial_slump_mm", 110.0),
                "outcome_class": outcome_data.get("outcome"),
                "financial_loss_inr": outcome_data.get("financial_impact_inr", 0.0),
                "recorded_at": outcome_data["recorded_at"]
            }
            self.ml_feedback_dataset.append(ml_record)

        return outcome_data

    def get_fleet_kpi(self) -> Dict[str, Any]:
        batches = list(self.batches.values())
        active = [b for b in batches if b["status"] not in [BatchStatus.DELIVERED, BatchStatus.REJECTED]]
        high_risk = [b for b in active if b["risk_level"] in [RiskLevel.HIGH_RISK, RiskLevel.CRITICAL]]
        watch = [b for b in active if b["risk_level"] == RiskLevel.WATCH]
        on_time = [b for b in active if b["risk_level"] == RiskLevel.SAFE]
        
        avg_transit = sum(b.get("elapsed_minutes", 0) for b in active) / max(1, len(active))
        at_risk_vol = sum(b.get("volume_m3", 6.0) for b in high_risk)
        potential_loss = at_risk_vol * 40166.67
        
        return {
            "active_deliveries": len(active),
            "high_risk_batches": len(high_risk),
            "on_time_count": len(on_time),
            "watch_count": len(watch),
            "avg_transit_minutes": round(avg_transit, 1),
            "at_risk_volume_m3": round(at_risk_vol, 1),
            "potential_loss_inr": round(potential_loss, 2),
            "loss_avoided_inr": 168000.0,
            "freshness_seconds": 4
        }


batch_repo = InMemoryBatchRepository()
