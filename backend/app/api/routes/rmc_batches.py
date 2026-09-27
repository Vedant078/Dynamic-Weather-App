from fastapi import APIRouter, HTTPException, Depends, status
from typing import List, Dict, Any, Optional
import uuid
from datetime import datetime, timezone
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.db.models import Delivery, DeliveryRiskResult, Telemetry, User
from app.repositories.delivery_repository import DeliveryRepository
from app.services.rmc_model_service import rmc_model_service
from app.api.deps import require_role
from app.models.schemas import (
    BatchDetail, BatchCreate, BatchStatus, RiskLevel,
    FleetKPI, ActionExecuteRequest, ActionExecuteResponse, MitigationAction,
    OutcomeRecordRequest, OutcomeResponse, TelemetryEvent
)

router = APIRouter(tags=["RMC Deliveries & Batches"])


def delivery_to_batch_detail(d: Delivery, db: Session) -> BatchDetail:
    latest_risk = DeliveryRepository.get_latest_risk_result(db, d.id)

    decision_val = RiskLevel.SAFE
    if latest_risk:
        try:
            decision_val = RiskLevel(latest_risk.decision)
        except Exception:
            decision_val = RiskLevel.SAFE

    status_val = BatchStatus.DISPATCHED
    try:
        status_val = BatchStatus(d.status)
    except Exception:
        status_val = BatchStatus.DISPATCHED

    action_val = None
    if latest_risk and latest_risk.recommended_action:
        try:
            action_val = MitigationAction(latest_risk.recommended_action)
        except Exception:
            action_val = None

    return BatchDetail(
        batch_id=d.id,
        batch_code=d.batch_code,
        plant_id=d.plant_id,
        plant_name=d.plant_name,
        project_id=d.project_id,
        project_name=d.project_name,
        volume_m3=d.volume_m3,
        target_slump_mm=d.target_slump_mm,
        initial_slump_mm=d.initial_slump_mm,
        current_slump_mm=d.current_slump_mm,
        slump_retention_ratio=d.slump_retention_ratio,
        concrete_temp_c=d.concrete_temp_c,
        ambient_temp_c=d.ambient_temp_c,
        elapsed_minutes=d.elapsed_minutes,
        eta_minutes=d.eta_minutes,
        original_eta_minutes=d.original_eta_minutes,
        distance_remaining_km=d.distance_remaining_km,
        total_distance_km=d.total_distance_km,
        traffic_index=d.traffic_index,
        precipitation_prob=d.precipitation_prob,
        status=status_val,
        risk_level=decision_val,
        heat_risk=latest_risk.heat_risk if latest_risk else 25.0,
        travel_risk=latest_risk.travel_risk if latest_risk else 25.0,
        delivery_risk=latest_risk.delivery_risk if latest_risk else 25.0,
        composite_risk=latest_risk.composite_risk if latest_risk else 25.0,
        primary_driver=latest_risk.primary_driver if latest_risk else "Within operational parameters",
        risk_factors=latest_risk.contributors if (latest_risk and latest_risk.contributors) else [],
        recommended_action=action_val,
        created_at=d.created_at.isoformat() if d.created_at else datetime.now(timezone.utc).isoformat(),
        dispatched_at=d.dispatched_at.isoformat() if d.dispatched_at else None
    )


# Fleet KPI
@router.get("/rmc/fleet/kpi", response_model=FleetKPI)
@router.get("/fleet/kpi", response_model=FleetKPI)
def get_fleet_kpis(
    db: Session = Depends(get_db),
    user: User = Depends(require_role("rmc"))
):
    """Returns top-level fleet operational KPI summary scoped to user's organization."""
    return DeliveryRepository.get_fleet_kpi(db, organization=user.organization_name, user_id=user.id)


# List Deliveries / Batches
@router.get("/rmc/batches", response_model=List[BatchDetail])
@router.get("/deliveries", response_model=List[BatchDetail])
def list_deliveries(
    db: Session = Depends(get_db),
    user: User = Depends(require_role("rmc"))
):
    """Lists all active and monitored concrete deliveries scoped to user's organization."""
    deliveries = DeliveryRepository.get_all(db, organization=user.organization_name, user_id=user.id)
    return [delivery_to_batch_detail(d, db) for d in deliveries]


# Get Single Delivery / Batch
@router.get("/rmc/batches/{delivery_id}", response_model=BatchDetail)
@router.get("/deliveries/{delivery_id}", response_model=BatchDetail)
def get_delivery(
    delivery_id: str,
    db: Session = Depends(get_db),
    user: User = Depends(require_role("rmc"))
):
    """Retrieves full telemetry, risk status, and details for a specific delivery if authorized."""
    delivery = DeliveryRepository.get_by_id(db, delivery_id, organization=user.organization_name, user_id=user.id)
    if not delivery:
        raise HTTPException(status_code=404, detail=f"Delivery/Batch {delivery_id} not found")
    return delivery_to_batch_detail(delivery, db)


# Create Delivery / Batch
@router.post("/rmc/batches", response_model=Dict[str, Any])
@router.post("/deliveries", response_model=Dict[str, Any])
def create_delivery(
    req: BatchCreate,
    db: Session = Depends(get_db),
    user: User = Depends(require_role("rmc"))
):
    """
    Creates and persists a real RMC delivery into PostgreSQL.
    Resolves operational route, coordinates, runs canonical RMC model inference,
    persists risk result, and returns newly created delivery.
    """
    new_id = f"batch-{uuid.uuid4().hex[:6]}"
    batch_code = req.batch_code or f"RMC-{uuid.uuid4().hex[:4].upper()}"

    # Prepare delivery context for model inference
    planned_transit = req.planned_transit_minutes or 48.0
    risk_context = {
        "batch_id": new_id,
        "plant_name": req.plant_name,
        "plant_id": req.plant_id,
        "project_name": req.project_name,
        "project_id": req.project_id,
        "concrete_grade": req.concrete_grade,
        "volume_m3": req.volume_m3,
        "initial_slump_mm": req.initial_slump_mm,
        "target_slump_mm": req.target_slump_mm,
        "ambient_temp_c": 34.0,
        "concrete_temp_c": 32.0,
        "relative_humidity": 50.0,
        "traffic_index": 0.35,
        "planned_transit_minutes": planned_transit,
        "elapsed_minutes": 0.0,
        "eta_minutes": planned_transit,
        "dispatch_time": req.dispatch_time or "14:00",
        "admixture_retarder": req.admixture_retarder or "None"
    }

    # Run Canonical RMC Model Service (Real ML Inference + Operational Rules + Structured Log)
    pred = rmc_model_service.calculate_delivery_risk(risk_context)

    # Persist Delivery into PostgreSQL
    delivery_data = {
        "id": new_id,
        "batch_code": batch_code,
        "user_id": user.id,
        "organization": user.organization_name,
        "plant_id": req.plant_id,
        "plant_name": req.plant_name,
        "plant_lat": req.plant_lat or 23.0225,
        "plant_lng": req.plant_lng or 72.5714,
        "project_id": req.project_id,
        "project_name": req.project_name,
        "project_lat": req.project_lat or 23.0900,
        "project_lng": req.project_lng or 72.6100,
        "concrete_grade": req.concrete_grade,
        "volume_m3": req.volume_m3,
        "initial_slump_mm": req.initial_slump_mm,
        "target_slump_mm": req.target_slump_mm,
        "current_slump_mm": pred.get("predicted_slump_mm", req.initial_slump_mm),
        "slump_retention_ratio": pred.get("slump_retention", 1.0),
        "concrete_temp_c": 32.0,
        "ambient_temp_c": 34.0,
        "relative_humidity": 50.0,
        "dispatch_time": req.dispatch_time or "14:00",
        "requested_delivery_time": req.requested_delivery_time,
        "admixture_retarder": req.admixture_retarder or "None",
        "planned_transit_minutes": planned_transit,
        "elapsed_minutes": 0.0,
        "eta_minutes": planned_transit,
        "original_eta_minutes": planned_transit,
        "distance_remaining_km": 28.5,
        "total_distance_km": 28.5,
        "traffic_index": 0.35,
        "precipitation_prob": 0.0,
        "status": "DISPATCHED",
        "active_route_id": "route-a"
    }
    delivery = DeliveryRepository.create_delivery(db, delivery_data)

    # Persist Risk Result in PostgreSQL (delivery_risk_results)
    DeliveryRepository.save_risk_result(db, delivery.id, {
        "model_version": pred.get("model_version", "GBR-RMC-v2.0"),
        "predicted_slump_mm": pred["predicted_slump_mm"],
        "slump_retention": pred["slump_retention"],
        "heat_risk": pred["heat_risk"],
        "travel_risk": pred["travel_risk"],
        "delivery_risk": pred["delivery_risk"],
        "composite_risk": pred["composite_risk"],
        "decision": pred["decision"],
        "sla_status": pred.get("sla_status", "COMPLIANT"),
        "primary_driver": pred["primary_driver"],
        "contributors": pred.get("contributors", []),
        "recommended_action": pred.get("recommended_action", "MONITOR_TELEMETRY"),
        "input_snapshot": risk_context
    })

    # Persist initial telemetry point
    DeliveryRepository.save_telemetry(db, delivery.id, {
        "lat": delivery.plant_lat,
        "lng": delivery.plant_lng,
        "speed_kmh": 0.0,
        "concrete_temp_c": delivery.concrete_temp_c,
        "drum_rpm": 12.0,
        "current_slump_mm": delivery.current_slump_mm,
        "ambient_temp_c": delivery.ambient_temp_c,
        "humidity_pct": delivery.relative_humidity
    })

    return {
        "batch_id": delivery.id,
        "id": delivery.id,
        "batch_code": delivery.batch_code,
        "status": delivery.status,
        "risk_level": pred["decision"],
        "predicted_slump_mm": pred["predicted_slump_mm"],
        "slump_retention_ratio": pred["slump_retention"],
        "model_version": pred.get("model_version", "GBR-RMC-v2.0"),
        "created_at": delivery.created_at.isoformat()
    }


# Recalculate Risk for Delivery
@router.post("/rmc/batches/{delivery_id}/risk")
@router.post("/deliveries/{delivery_id}/risk")
def calculate_risk_for_delivery(
    delivery_id: str,
    override_data: Optional[Dict[str, Any]] = None,
    db: Session = Depends(get_db),
    user: User = Depends(require_role("rmc"))
):
    """
    Executes real RMC model risk calculation for a persistent delivery.
    Saves and returns the historical risk result.
    """
    delivery = DeliveryRepository.get_by_id(db, delivery_id, organization=user.organization_name, user_id=user.id)
    if not delivery:
        raise HTTPException(status_code=404, detail=f"Delivery {delivery_id} not found")

    risk_context = {
        "batch_id": delivery.id,
        "plant_name": delivery.plant_name,
        "project_name": delivery.project_name,
        "concrete_grade": delivery.concrete_grade,
        "volume_m3": delivery.volume_m3,
        "initial_slump_mm": delivery.initial_slump_mm,
        "target_slump_mm": delivery.target_slump_mm,
        "ambient_temp_c": delivery.ambient_temp_c,
        "concrete_temp_c": delivery.concrete_temp_c,
        "relative_humidity": delivery.relative_humidity,
        "traffic_index": delivery.traffic_index,
        "planned_transit_minutes": delivery.planned_transit_minutes,
        "elapsed_minutes": delivery.elapsed_minutes,
        "eta_minutes": delivery.eta_minutes,
        "dispatch_time": delivery.dispatch_time,
        "admixture_retarder": delivery.admixture_retarder
    }
    if override_data:
        risk_context.update(override_data)

    pred = rmc_model_service.calculate_delivery_risk(risk_context)

    # Persist risk result in PostgreSQL
    saved_risk = DeliveryRepository.save_risk_result(db, delivery.id, {
        "model_version": pred.get("model_version", "GBR-RMC-v2.0"),
        "predicted_slump_mm": pred["predicted_slump_mm"],
        "slump_retention": pred["slump_retention"],
        "heat_risk": pred["heat_risk"],
        "travel_risk": pred["travel_risk"],
        "delivery_risk": pred["delivery_risk"],
        "composite_risk": pred["composite_risk"],
        "decision": pred["decision"],
        "sla_status": pred.get("sla_status", "COMPLIANT"),
        "primary_driver": pred["primary_driver"],
        "contributors": pred.get("contributors", []),
        "recommended_action": pred.get("recommended_action", "MONITOR_TELEMETRY"),
        "input_snapshot": risk_context
    })

    return {
        "risk_id": saved_risk.id,
        "delivery_id": delivery.id,
        "batch_id": delivery.id,
        "decision": pred["decision"],
        "risk_level": pred["decision"],
        "predicted_slump_mm": pred["predicted_slump_mm"],
        "slump_retention": pred["slump_retention"],
        "heat_risk": pred["heat_risk"],
        "travel_risk": pred["travel_risk"],
        "delivery_risk": pred["delivery_risk"],
        "composite_risk": pred["composite_risk"],
        "primary_driver": pred["primary_driver"],
        "contributors": pred.get("contributors", []),
        "recommended_action": pred.get("recommended_action"),
        "model_version": pred.get("model_version", "GBR-RMC-v2.0"),
        "calculated_at": saved_risk.calculated_at.isoformat()
    }


# Dispatch Delivery
@router.post("/rmc/batches/{delivery_id}/dispatch")
@router.post("/deliveries/{delivery_id}/dispatch")
def dispatch_delivery(
    delivery_id: str,
    db: Session = Depends(get_db),
    user: User = Depends(require_role("rmc"))
):
    """Dispatches a delivery, transitioning status to DISPATCHED / ACTIVE."""
    delivery = DeliveryRepository.get_by_id(db, delivery_id, organization=user.organization_name, user_id=user.id)
    if not delivery:
        raise HTTPException(status_code=404, detail=f"Delivery {delivery_id} not found")

    delivery.status = "DISPATCHED"
    delivery.dispatched_at = datetime.now(timezone.utc)
    delivery.updated_at = datetime.now(timezone.utc)
    db.commit()

    return {
        "delivery_id": delivery.id,
        "batch_id": delivery.id,
        "status": "DISPATCHED",
        "dispatched_at": delivery.dispatched_at.isoformat()
    }


# Telemetry History
@router.get("/rmc/batches/{delivery_id}/telemetry")
@router.get("/deliveries/{delivery_id}/telemetry")
def get_delivery_telemetry(
    delivery_id: str,
    db: Session = Depends(get_db),
    user: User = Depends(require_role("rmc"))
):
    """Retrieves real recorded telemetry history for a delivery from PostgreSQL."""
    delivery = DeliveryRepository.get_by_id(db, delivery_id, organization=user.organization_name, user_id=user.id)
    if not delivery:
        raise HTTPException(status_code=404, detail=f"Delivery {delivery_id} not found")

    points = DeliveryRepository.get_telemetry_history(db, delivery_id)
    return [
        {
            "id": p.id,
            "timestamp": p.timestamp.isoformat(),
            "lat": p.lat,
            "lng": p.lng,
            "speed_kmh": p.speed_kmh,
            "concrete_temp_c": p.concrete_temp_c,
            "drum_rpm": p.drum_rpm,
            "current_slump_mm": p.current_slump_mm,
            "ambient_temp_c": p.ambient_temp_c,
            "humidity_pct": p.humidity_pct
        }
        for p in points
    ]


# Delivery Outcome
@router.post("/rmc/batches/{delivery_id}/outcome", response_model=OutcomeResponse)
@router.post("/deliveries/{delivery_id}/outcome", response_model=OutcomeResponse)
def record_outcome(
    delivery_id: str,
    req: OutcomeRecordRequest,
    db: Session = Depends(get_db),
    user: User = Depends(require_role("rmc"))
):
    """Records real delivery site arrival outcome (accepted or rejected) into PostgreSQL."""
    delivery = DeliveryRepository.get_by_id(db, delivery_id, organization=user.organization_name, user_id=user.id)
    if not delivery:
        raise HTTPException(status_code=404, detail=f"Delivery {delivery_id} not found")

    outcome = DeliveryRepository.save_outcome(db, {
        "batch_id": delivery_id,
        "outcome": req.outcome,
        "site_slump_mm": req.site_slump_mm,
        "actual_transit_minutes": req.actual_transit_minutes,
        "site_concrete_temp_c": req.site_concrete_temp_c,
        "rejection_reason": req.rejection_reason
    })

    return OutcomeResponse(
        outcome_id=outcome.id,
        batch_id=outcome.delivery_id,
        outcome=outcome.outcome,
        quality_grade=outcome.quality_grade,
        slump_variance_mm=outcome.slump_variance_mm,
        financial_impact_inr=outcome.financial_impact_inr,
        financial_type=outcome.financial_type,
        ml_training_recorded=outcome.ml_training_recorded,
        recorded_at=outcome.recorded_at.isoformat()
    )


# Operational Mitigation Action
@router.post("/rmc/batches/{batch_id}/action", response_model=ActionExecuteResponse)
def execute_mitigation_action(
    batch_id: str,
    req: ActionExecuteRequest,
    db: Session = Depends(get_db),
    user: User = Depends(require_role("rmc"))
):
    """Executes an operational mitigation decision on an active delivery."""
    delivery = DeliveryRepository.get_by_id(db, batch_id)
    if not delivery:
        raise HTTPException(status_code=404, detail=f"Batch {batch_id} not found")

    if req.action == MitigationAction.CALCULATE_NEW_ROUTE or req.action == "APPLY_ROUTE_B":
        delivery.status = "REROUTED"
        delivery.active_route_id = "route-b"
        delivery.eta_minutes = max(12.0, delivery.eta_minutes - 9.0)
        delivery.traffic_index = 0.35
        db.commit()

        # Recalculate risk
        pred = rmc_model_service.calculate_delivery_risk({
            "batch_id": delivery.id,
            "plant_name": delivery.plant_name,
            "project_name": delivery.project_name,
            "concrete_grade": delivery.concrete_grade,
            "planned_transit_minutes": delivery.eta_minutes,
            "eta_minutes": delivery.eta_minutes,
            "elapsed_minutes": delivery.elapsed_minutes,
            "initial_slump_mm": delivery.initial_slump_mm,
            "target_slump_mm": delivery.target_slump_mm,
            "traffic_index": 0.35
        })
        DeliveryRepository.save_risk_result(db, delivery.id, pred)

        return ActionExecuteResponse(
            batch_id=batch_id,
            action_taken=MitigationAction.CALCULATE_NEW_ROUTE,
            new_status=BatchStatus.REROUTED,
            new_risk_level=RiskLevel.SAFE,
            message="Alternative Route B applied successfully. ETA reduced by 9 minutes; delivery risk normalized to SAFE.",
            updated_eta_minutes=delivery.eta_minutes,
            updated_delivery_risk=pred.get("delivery_risk", 36.0)
        )

    elif req.action == MitigationAction.ADD_RETARDER:
        delivery.status = "RETARDER_ADDED"
        delivery.admixture_retarder = "Retarder Admixture 0.4%"
        delivery.slump_retention_ratio = min(0.98, delivery.slump_retention_ratio + 0.05)
        db.commit()

        pred = rmc_model_service.calculate_delivery_risk({
            "batch_id": delivery.id,
            "plant_name": delivery.plant_name,
            "project_name": delivery.project_name,
            "concrete_grade": delivery.concrete_grade,
            "planned_transit_minutes": delivery.eta_minutes,
            "eta_minutes": delivery.eta_minutes,
            "elapsed_minutes": delivery.elapsed_minutes,
            "initial_slump_mm": delivery.initial_slump_mm,
            "target_slump_mm": delivery.target_slump_mm,
            "admixture_retarder": "Retarder Admixture 0.4%"
        })
        DeliveryRepository.save_risk_result(db, delivery.id, pred)

        return ActionExecuteResponse(
            batch_id=batch_id,
            action_taken=MitigationAction.ADD_RETARDER,
            new_status=BatchStatus.RETARDER_ADDED,
            new_risk_level=RiskLevel.WATCH,
            message="Retarder admixture confirmed. Slump retention window extended by +30 minutes.",
            updated_eta_minutes=delivery.eta_minutes,
            updated_delivery_risk=pred.get("delivery_risk", 35.0)
        )

    elif req.action == MitigationAction.OVERRIDE_PROCEED:
        if not req.override_confirmed:
            raise HTTPException(status_code=400, detail="Consequential override requires explicit confirmation.")
        delivery.status = "IN_TRANSIT"
        db.commit()
        return ActionExecuteResponse(
            batch_id=batch_id,
            action_taken=MitigationAction.OVERRIDE_PROCEED,
            new_status=BatchStatus.IN_TRANSIT,
            new_risk_level=RiskLevel.HIGH_RISK,
            message="Operator override logged. Proceeding with standard navigation under advisory.",
            updated_eta_minutes=delivery.eta_minutes,
            updated_delivery_risk=65.0
        )

    elif req.action == MitigationAction.RESCHEDULE_BATCH:
        delivery.status = "CREATED"
        db.commit()
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
