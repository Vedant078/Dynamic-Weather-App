import logging
from typing import List, Optional
from sqlalchemy.orm import Session
from sqlalchemy import or_
from app.db.models import Location
from app.models.schemas import LocationCreateRequest, LocationUpdateRequest

logger = logging.getLogger("location_repo")


class LocationRepository:
    @staticmethod
    def create_location(
        db: Session,
        user_id: str,
        organization: Optional[str],
        data: LocationCreateRequest
    ) -> Location:
        location = Location(
            user_id=user_id,
            organization=organization,
            name=data.name.strip(),
            type=data.type.strip().upper(),
            address=data.address.strip() if data.address else None,
            latitude=float(data.latitude),
            longitude=float(data.longitude),
        )
        db.add(location)
        db.commit()
        db.refresh(location)
        logger.info(f"Created location {location.id} ({location.name}) for user {user_id}")
        return location

    @staticmethod
    def list_locations(
        db: Session,
        user_id: str,
        organization: Optional[str] = None,
        loc_type: Optional[str] = None
    ) -> List[Location]:
        query = db.query(Location)
        if organization:
            query = query.filter(
                or_(
                    Location.organization == organization,
                    Location.user_id == user_id
                )
            )
        else:
            query = query.filter(Location.user_id == user_id)

        if loc_type:
            query = query.filter(Location.type == loc_type.strip().upper())

        return query.order_by(Location.created_at.desc()).all()

    @staticmethod
    def get_location(
        db: Session,
        location_id: str,
        user_id: str,
        organization: Optional[str] = None
    ) -> Optional[Location]:
        query = db.query(Location).filter(Location.id == location_id)
        if organization:
            query = query.filter(
                or_(
                    Location.organization == organization,
                    Location.user_id == user_id
                )
            )
        else:
            query = query.filter(Location.user_id == user_id)
        return query.first()

    @staticmethod
    def update_location(
        db: Session,
        location_id: str,
        user_id: str,
        data: LocationUpdateRequest,
        organization: Optional[str] = None
    ) -> Optional[Location]:
        loc = LocationRepository.get_location(db, location_id, user_id, organization)
        if not loc:
            return None

        if data.name is not None:
            loc.name = data.name.strip()
        if data.type is not None:
            loc.type = data.type.strip().upper()
        if data.address is not None:
            loc.address = data.address.strip()
        if data.latitude is not None:
            loc.latitude = float(data.latitude)
        if data.longitude is not None:
            loc.longitude = float(data.longitude)

        db.commit()
        db.refresh(loc)
        return loc

    @staticmethod
    def delete_location(
        db: Session,
        location_id: str,
        user_id: str,
        organization: Optional[str] = None
    ) -> bool:
        loc = LocationRepository.get_location(db, location_id, user_id, organization)
        if not loc:
            return False

        db.delete(loc)
        db.commit()
        logger.info(f"Deleted location {location_id}")
        return True
