import logging
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.db.models import User
from app.api.deps import get_current_user
from app.models.schemas import (
    LocationCreateRequest,
    LocationUpdateRequest,
    LocationResponse
)
from app.repositories.location_repository import LocationRepository

logger = logging.getLogger("locations_api")
router = APIRouter(prefix="/locations", tags=["Locations"])


@router.get("", response_model=List[LocationResponse])
def get_locations(
    type: Optional[str] = Query(None, description="Filter by type: PLANT, PROJECT_SITE, DESTINATION"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Returns all saved locations owned by the user or the user's organization.
    Strictly isolated per tenant.
    """
    locations = LocationRepository.list_locations(
        db=db,
        user_id=current_user.id,
        organization=current_user.organization_name,
        loc_type=type
    )
    return locations


@router.get("/geocode")
def geocode_location(
    address: str = Query(..., min_length=2, description="Physical address, landmark, or city name"),
    current_user: User = Depends(get_current_user)
):
    """
    Geocodes an address or city to real latitude and longitude using OpenStreetMap Nominatim.
    Fails explicitly if location cannot be resolved; never fabricates coordinates.
    """
    from app.services.geocoding_service import GeocodingService
    res = GeocodingService.geocode(address)
    if not res:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Unable to geocode '{address}'. Please verify address or enter coordinates manually."
        )
    return res


@router.post("", response_model=LocationResponse, status_code=status.HTTP_201_CREATED)
def create_location(
    data: LocationCreateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Create a new persistent plant, project site, or frequent destination.
    Uses real coordinates. If coordinates are zero and address is given, performs geocoding.
    """
    # Validate type
    valid_types = {"PLANT", "PROJECT_SITE", "DESTINATION"}
    if data.type.strip().upper() not in valid_types:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Invalid location type '{data.type}'. Must be one of {valid_types}"
        )

    # If coordinates are 0.0 and address is provided, auto-geocode
    if (data.latitude == 0.0 and data.longitude == 0.0) and data.address:
        from app.services.geocoding_service import GeocodingService
        geo = GeocodingService.geocode(data.address)
        if geo:
            data.latitude = geo["latitude"]
            data.longitude = geo["longitude"]
        else:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=f"Unable to determine coordinates for '{data.address}'. Please provide latitude and longitude."
            )

    loc = LocationRepository.create_location(
        db=db,
        user_id=current_user.id,
        organization=current_user.organization_name,
        data=data
    )
    return loc


@router.get("/{location_id}", response_model=LocationResponse)
def get_location_by_id(
    location_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get a single location by ID.
    Enforces authorization and ownership. Returns 404 if owned by another user/org.
    """
    loc = LocationRepository.get_location(
        db=db,
        location_id=location_id,
        user_id=current_user.id,
        organization=current_user.organization_name
    )
    if not loc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Location not found or access denied"
        )
    return loc


@router.put("/{location_id}", response_model=LocationResponse)
def update_location(
    location_id: str,
    data: LocationUpdateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Update a saved location.
    Enforces authorization and ownership. Returns 404 if owned by another user/org.
    """
    if data.type is not None:
        valid_types = {"PLANT", "PROJECT_SITE", "DESTINATION"}
        if data.type.strip().upper() not in valid_types:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=f"Invalid location type '{data.type}'. Must be one of {valid_types}"
            )

    loc = LocationRepository.update_location(
        db=db,
        location_id=location_id,
        user_id=current_user.id,
        data=data,
        organization=current_user.organization_name
    )
    if not loc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Location not found or access denied"
        )
    return loc


@router.delete("/{location_id}")
def delete_location(
    location_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Delete a saved location.
    Enforces authorization and ownership. Returns 404 if owned by another user/org.
    """
    success = LocationRepository.delete_location(
        db=db,
        location_id=location_id,
        user_id=current_user.id,
        organization=current_user.organization_name
    )
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Location not found or access denied"
        )
    return {"message": "Location deleted successfully", "id": location_id}
