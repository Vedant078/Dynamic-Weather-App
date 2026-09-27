from fastapi import APIRouter
from app.models.schemas import RiskPredictRequest, RiskPredictResponse
from app.services.rmc_model_service import rmc_model_service


router = APIRouter(prefix="/rmc", tags=["RMC Risk"])


@router.post("/risk/predict", response_model=RiskPredictResponse)
@router.post("/risk/calculate", response_model=RiskPredictResponse)
def predict_risk(req: RiskPredictRequest):
    """
    Consumes delivery order specifications, environmental window, and traffic telemetry,
    executes Scikit-learn GBR inference, computes 3-dimensional risk scores, and returns
    explainable drivers and operational decisions.
    """
    res = rmc_model_service.calculate_delivery_risk(req.model_dump())
    
    return RiskPredictResponse(
        batch_id=req.batch_id,
        predicted_slump_mm=res["predicted_slump_mm"],
        slump_retention=res["slump_retention"],
        heat_risk=res["heat_risk"],
        travel_risk=res["travel_risk"],
        delivery_risk=res["delivery_risk"],
        composite_risk=res["composite_risk"],
        decision=res["decision"],
        status_label=res["status_label"],
        is_approved=res["is_approved"],
        primary_driver=res["primary_driver"],
        contributors=res["contributors"],
        model_version=res.get("model_version", "GBR-RMC-v2.0"),
        recommended_action=res.get("recommended_action"),
        heat_risk_level=res.get("heat_risk_level"),
        travel_risk_level=res.get("travel_risk_level"),
        delivery_risk_level=res.get("delivery_risk_level"),
        planned_transit_minutes=res.get("planned_transit_minutes"),
        expected_arrival_time=res.get("expected_arrival_time"),
        sla_status=res.get("sla_status", "COMPLIANT"),
        worst_material_factor=res.get("worst_material_factor"),
        is_data_insufficient=res.get("is_data_insufficient", False)
    )
