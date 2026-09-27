from fastapi import APIRouter, HTTPException
from typing import List, Dict, Any
import uuid
from datetime import datetime, timezone

from app.models.schemas import (
    BatchDetail, BatchCreate, BatchStatus, RiskLevel,
    FleetKPI, ActionExecuteRequest, ActionExecuteResponse, MitigationAction
)
from app.repositories.batch_repository import batch_repo
from app.ml.model import model_manager


router = APIRouter(prefix="/rmc", tags=["RMC Batches"])


@router.get("/fleet/kpi", response_model=FleetKPI)
def get_fleet_kpis():
    """Returns top-level fleet operational KPI summary."""
    return batch_repo.get_fleet_kpi()


@router.get("/batches", response_model=List[BatchDetail])
def list_batches():
    """Lists all active and monitored concrete batches."""
    return batch_repo.get_all_batches()


@router.get("/batches/{batch_id}", response_model=BatchDetail)
def get_batch(batch_id: str):
    """Retrieves full telemetry, risk status, and details for a batch."""
    batch = batch_repo.get_batch(batch_id)
    if not batch:
        raise HTTPException(status_code=404, detail=f"Batch {batch_id} not found")
    return batch


@router.post("/batches", response_model=Dict[str, Any])
def create_batch(req: BatchCreate):
    """Creates and dispatches a new RMC concrete batch."""
    new_id = f"batch-{uuid.uuid4().hex[:6]}"
    batch_code = req.batch_code or f"RMC-{uuid.uuid4().hex[:4].upper()}"
    
    # Predict initial risk with fresh concrete parameters
    pred = model_manager.predict_batch_risk({
        "ambient_temp_c": 35.0,
        "concrete_temp_c": 32.0,
        "traffic_index": 0.35,
        "expected_delay_min": 0.0,
        "elapsed_minutes": 0.0,
        "eta_minutes": 48.0,
        "initial_slump_mm": req.initial_slump_mm,
        "target_slump_mm": req.target_slump_mm
    })

    new_batch = {
        "batch_id": new_id,
        "batch_code": batch_code,
        "plant_id": req.plant_id,
        "plant_name": req.plant_name,
        "project_id": req.project_id,
        "project_name": req.project_name,
        "volume_m3": req.volume_m3,
        "target_slump_mm": req.target_slump_mm,
        "initial_slump_mm": req.initial_slump_mm,
        "current_slump_mm": req.initial_slump_mm,
        "slump_retention_ratio": 1.0,
        "concrete_temp_c": 32.0,
        "ambient_temp_c": 35.0,
        "elapsed_minutes": 0.0,
        "eta_minutes": 48.0,
        "original_eta_minutes": 48.0,
        "distance_remaining_km": 28.5,
        "total_distance_km": 28.5,
        "traffic_index": 0.35,
        "precipitation_prob": 0.0,
        "status": BatchStatus.DISPATCHED,
        "risk_level": pred["decision"],
        "heat_risk": pred["heat_risk"],
        "travel_risk": pred["travel_risk"],
        "delivery_risk": pred["delivery_risk"],
        "composite_risk": pred["composite_risk"],
        "primary_driver": pred["primary_driver"],
        "risk_factors": pred["contributors"],
        "recommended_action": pred["recommended_action"],
        "active_route_id": "route-a",
        "created_at": datetime.now(timezone.utc).isoformat(),
        "dispatched_at": datetime.now(timezone.utc).isoformat()
    }
    
    batch_repo.batches[new_id] = new_batch
    return {"batch_id": new_id, "batch_code": batch_code, "status": "DISPATCHED"}


@router.post("/batches/{batch_id}/action", response_model=ActionExecuteResponse)
def execute_mitigation_action(batch_id: str, req: ActionExecuteRequest):
    """
    Executes an operational mitigation decision on an active batch:
    - CALCULATE_NEW_ROUTE / APPLY_ROUTE
    - ADD_RETARDER
    - RESCHEDULE_BATCH
    - OVERRIDE_PROCEED
    """
    batch = batch_repo.get_batch(batch_id)
    if not batch:
        raise HTTPException(status_code=404, detail=f"Batch {batch_id} not found")

    if req.action == MitigationAction.CALCULATE_NEW_ROUTE or req.action == "APPLY_ROUTE_B":
        # Diverts to Route B: saves 9 min, avoids bottleneck
        updates = {
            "status": BatchStatus.REROUTED,
            "active_route_id": "route-b",
            "eta_minutes": max(12.0, batch["eta_minutes"] - 9.0),
            "traffic_index": 0.35,
            "delivery_risk": 36.0,
            "travel_risk": 30.0,
            "composite_risk": 35.0,
            "risk_level": RiskLevel.SAFE,
            "primary_driver": "Alternative Route B active; traffic bottleneck bypassed",
            "risk_factors": ["Airport Bypass Expressway active", "Slump retention stabilized at >93%"],
            "recommended_action": None
        }
        batch_repo.update_batch(batch_id, updates)
        return ActionExecuteResponse(
            batch_id=batch_id,
            action_taken=MitigationAction.CALCULATE_NEW_ROUTE,
            new_status=BatchStatus.REROUTED,
            new_risk_level=RiskLevel.SAFE,
            message="Alternative Route B applied successfully. ETA reduced by 9 minutes; delivery risk normalized to SAFE.",
            updated_eta_minutes=updates["eta_minutes"],
            updated_delivery_risk=36.0
        )

    elif req.action == MitigationAction.ADD_RETARDER:
        # Chemical retarder extends slump retention by ~30 min
        updates = {
            "status": BatchStatus.RETARDER_ADDED,
            "slump_retention_ratio": min(0.98, batch["slump_retention_ratio"] + 0.05),
            "delivery_risk": max(25.0, batch["delivery_risk"] - 28.0),
            "risk_level": RiskLevel.WATCH,
            "primary_driver": "Hydration retarded via chemical admixture",
            "risk_factors": ["Retarder admixture added at transit mixer", "Hydration window extended by +30 min"]
        }
        batch_repo.update_batch(batch_id, updates)
        return ActionExecuteResponse(
            batch_id=batch_id,
            action_taken=MitigationAction.ADD_RETARDER,
            new_status=BatchStatus.RETARDER_ADDED,
            new_risk_level=RiskLevel.WATCH,
            message="Retarder admixture confirmed. Slump retention window extended.",
            updated_eta_minutes=batch["eta_minutes"],
            updated_delivery_risk=updates["delivery_risk"]
        )

    elif req.action == MitigationAction.OVERRIDE_PROCEED:
        if not req.override_confirmed:
            raise HTTPException(status_code=400, detail="Consequential override requires explicit confirmation.")
        updates = {
            "status": BatchStatus.IN_TRANSIT,
            "primary_driver": "Operator override logged; proceeding under warning",
            "risk_factors": batch["risk_factors"] + ["OPERATOR OVERRIDE LOGGED AT DISPATCH"]
        }
        batch_repo.update_batch(batch_id, updates)
        return ActionExecuteResponse(
            batch_id=batch_id,
            action_taken=MitigationAction.OVERRIDE_PROCEED,
            new_status=BatchStatus.IN_TRANSIT,
            new_risk_level=batch["risk_level"],
            message="Operator override logged. Proceeding with standard navigation under advisory.",
            updated_eta_minutes=batch["eta_minutes"],
            updated_delivery_risk=batch["delivery_risk"]
        )

    elif req.action == MitigationAction.RESCHEDULE_BATCH:
        updates = {
            "status": BatchStatus.CREATED,
            "risk_level": RiskLevel.SAFE,
            "primary_driver": "Batch rescheduled for cooler transit window",
            "recommended_action": None
        }
        batch_repo.update_batch(batch_id, updates)
        return ActionExecuteResponse(
            batch_id=batch_id,
            action_taken=MitigationAction.RESCHEDULE_BATCH,
            new_status=BatchStatus.CREATED,
            new_risk_level=RiskLevel.SAFE,
            message="Batch marked for rescheduling to cooler evening transit window.",
            updated_eta_minutes=0.0,
            updated_delivery_risk=20.0
        )

    raise HTTPException(status_code=400, detail=f"Unsupported action: {req.action}")
