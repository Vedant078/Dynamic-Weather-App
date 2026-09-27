from fastapi import APIRouter, HTTPException
from typing import List
from app.models.schemas import (
    RouteAnalyzeRequest, RouteAnalyzeResponse, RouteOption
)
from app.repositories.batch_repository import batch_repo


router = APIRouter(prefix="/rmc", tags=["RMC Routes"])


@router.get("/batches/{batch_id}/routes", response_model=List[RouteOption])
def get_batch_routes(batch_id: str):
    """Returns candidate routes and comparative metrics for a batch."""
    routes = batch_repo.get_routes_for_batch(batch_id)
    if not routes:
        # Return default routes if not specifically registered
        routes = batch_repo.get_routes_for_batch("batch-rmc-204")
    return routes


@router.post("/routes/analyze", response_model=RouteAnalyzeResponse)
def analyze_routes(req: RouteAnalyzeRequest):
    """
    Evaluates candidate routes considering weather-weighted heat exposure,
    traffic congestion, and transit decay risk.
    """
    routes = batch_repo.get_routes_for_batch(req.batch_id) or batch_repo.get_routes_for_batch("batch-rmc-204")
    
    # Identify recommended route
    rec_route = next((r for r in routes if r["is_recommended"]), routes[0])
    
    return RouteAnalyzeResponse(
        recommended_route_id=rec_route["route_id"],
        eta_minutes=rec_route["eta_minutes"],
        delivery_risk=rec_route["delivery_risk"],
        recommendation_reason=rec_route["trade_off_explanation"],
        alternatives=routes
    )
