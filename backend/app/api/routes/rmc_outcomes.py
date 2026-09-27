from fastapi import APIRouter, HTTPException
from typing import List, Dict, Any
from app.models.schemas import OutcomeRecordRequest, OutcomeResponse, BatchStatus
from app.repositories.batch_repository import batch_repo


router = APIRouter(prefix="/rmc", tags=["RMC Outcomes"])


@router.post("/batches/{batch_id}/outcome", response_model=OutcomeResponse)
def record_batch_outcome(batch_id: str, req: OutcomeRecordRequest):
    """
    Records post-delivery concrete slump verification, acceptance/rejection,
    calculates financial impact, updates batch status, and pipes features into
    the ML retraining feedback loop.
    """
    batch = batch_repo.get_batch(batch_id)
    if not batch:
        raise HTTPException(status_code=404, detail=f"Batch {batch_id} not found")

    initial_slump = batch.get("initial_slump_mm", 110.0)
    variance_mm = round(req.site_slump_mm - initial_slump, 1)
    
    # Financial calculation (PRD.md Section 3.3 & Appendix C)
    if req.outcome == "rejected":
        # Full volume loss
        fin_impact = batch.get("volume_m3", 6.0) * 40166.67
        fin_type = "MATERIAL_LOSS"
        quality_grade = "REJECTED_UNUSABLE"
        new_status = BatchStatus.REJECTED
    elif req.outcome == "accepted_with_warning":
        fin_impact = 4200.0  # Minor admixture / testing cost
        fin_type = "NOMINAL_COST"
        quality_grade = "ACCEPTABLE_SUB_OPTIMAL"
        new_status = BatchStatus.DELIVERED
    else:
        # Avoided loss through proactive decision
        fin_impact = 168000.0
        fin_type = "AVOIDED_LOSS"
        quality_grade = "HIGH_SPEC_DELIVERY"
        new_status = BatchStatus.DELIVERED

    # Update batch
    batch_repo.update_batch(batch_id, {
        "status": new_status,
        "current_slump_mm": req.site_slump_mm,
        "slump_retention_ratio": round(req.site_slump_mm / initial_slump, 3),
        "concrete_temp_c": req.site_concrete_temp_c,
        "elapsed_minutes": req.actual_transit_minutes,
        "eta_minutes": 0.0,
        "distance_remaining_km": 0.0
    })

    recorded = batch_repo.record_outcome({
        "batch_id": batch_id,
        "outcome": req.outcome,
        "site_slump_mm": req.site_slump_mm,
        "actual_transit_minutes": req.actual_transit_minutes,
        "site_concrete_temp_c": req.site_concrete_temp_c,
        "rejection_reason": req.rejection_reason,
        "root_cause": req.root_cause,
        "financial_impact_inr": fin_impact,
        "financial_type": fin_type,
        "quality_grade": quality_grade
    })

    return OutcomeResponse(
        outcome_id=recorded["outcome_id"],
        batch_id=batch_id,
        outcome=req.outcome,
        quality_grade=quality_grade,
        slump_variance_mm=variance_mm,
        financial_impact_inr=fin_impact,
        financial_type=fin_type,
        ml_training_recorded=True,
        recorded_at=recorded["recorded_at"]
    )


@router.get("/outcomes", response_model=List[Dict[str, Any]])
def list_outcomes():
    """Lists recent verified delivery outcomes."""
    return batch_repo.outcomes


@router.get("/ml/feedback-dataset", response_model=List[Dict[str, Any]])
def get_ml_feedback_dataset():
    """
    Exposes ground-truth delivery records prepared for continuous model retraining
    (PRD.md Section 4.7 ML Model Retraining Loop).
    """
    return batch_repo.ml_feedback_dataset
