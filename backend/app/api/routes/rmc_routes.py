from fastapi import APIRouter, HTTPException, Depends
from typing import List
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.db.models import Delivery
from app.models.schemas import (
    RouteAnalyzeRequest, RouteAnalyzeResponse, RouteOption
)
from app.repositories.batch_repository import batch_repo
from app.services.routing_service import RoutingService


router = APIRouter(prefix="/rmc", tags=["RMC Routes"])


@router.get("/batches/{batch_id}/routes", response_model=List[RouteOption])
def get_batch_routes(batch_id: str, db: Session = Depends(get_db)):
    """
    Returns dynamic candidate routes and comparative metrics for a delivery batch.
    Uses real delivery coordinates.
    """
    # 1. Check persistent Delivery table first
    delivery = db.query(Delivery).filter(Delivery.id == batch_id).first()
    if delivery:
        routes = RoutingService.get_route_candidates(
            origin_lat=delivery.plant_lat,
            origin_lng=delivery.plant_lng,
            dest_lat=delivery.project_lat,
            dest_lng=delivery.project_lng,
            origin_name=delivery.plant_name,
            dest_name=delivery.project_name
        )
        return routes

    # 2. Check in-memory demo batch repository
    mem_batch = batch_repo.get_batch(batch_id)
    if mem_batch:
        mem_routes = batch_repo.get_routes_for_batch(batch_id)
        if mem_routes:
            return mem_routes
        # Generate dynamically if coords exist
        p_lat = mem_batch.get("plant_lat", 23.0225)
        p_lng = mem_batch.get("plant_lng", 72.5714)
        s_lat = mem_batch.get("project_lat", 23.0900)
        s_lng = mem_batch.get("project_lng", 72.6100)
        return RoutingService.get_route_candidates(
            origin_lat=p_lat,
            origin_lng=p_lng,
            dest_lat=s_lat,
            dest_lng=s_lng,
            origin_name=mem_batch.get("plant_name", "Origin Plant"),
            dest_name=mem_batch.get("project_name", "Destination Site")
        )

    # 3. For demo account explicitly requested
    if batch_id == "batch-rmc-204":
        return batch_repo.get_routes_for_batch("batch-rmc-204")

    raise HTTPException(status_code=404, detail=f"Delivery batch '{batch_id}' not found")


@router.post("/routes/analyze", response_model=RouteAnalyzeResponse)
def analyze_routes(req: RouteAnalyzeRequest, db: Session = Depends(get_db)):
    """
    Evaluates candidate routes dynamically between origin and destination waypoints.
    """
    routes = RoutingService.get_route_candidates(
        origin_lat=req.origin.lat,
        origin_lng=req.origin.lng,
        dest_lat=req.destination.lat,
        dest_lng=req.destination.lng,
        origin_name=req.origin.name or "Origin Plant",
        dest_name=req.destination.name or "Destination Site"
    )

    # Identify recommended route
    rec_route = next((r for r in routes if r["is_recommended"]), routes[0])

    return RouteAnalyzeResponse(
        recommended_route_id=rec_route["route_id"],
        eta_minutes=rec_route["eta_minutes"],
        delivery_risk=rec_route["delivery_risk"],
        recommendation_reason=rec_route["trade_off_explanation"],
        alternatives=routes
    )
