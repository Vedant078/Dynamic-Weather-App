from typing import Optional, List
from datetime import datetime, timezone
from sqlalchemy.orm import Session
from app.db.models import User, Role, user_roles
from app.core.security import hash_password


STANDARD_ROLES = [
    {"id": "rmc", "name": "RMC Logistics Manager", "description": "Ready-Mix Concrete Transit Loss Prevention"},
    {"id": "health", "name": "Health-Conscious User", "description": "Air Quality & Heat Vulnerability Intelligence"},
    {"id": "fitness", "name": "Outdoor Fitness Enthusiast", "description": "Optimal Training Window Predictor"},
    {"id": "beach", "name": "Beachgoer / Surfer", "description": "Coastal & Marine Safety Telemetry"},
    {"id": "traveler", "name": "Traveler / Commuter", "description": "Corridor Weather & Highway Delay Alerts"},
    {"id": "family", "name": "Parent / Family", "description": "Family Safety & School Commute Guard"},
    {"id": "agriculture", "name": "Agriculture / Gardener", "description": "Crop Hydration & Microclimate Guidance"},
]


class UserRepository:
    @staticmethod
    def get_by_id(db: Session, user_id: str) -> Optional[User]:
        return db.query(User).filter(User.id == user_id).first()

    @staticmethod
    def get_by_email(db: Session, email: str) -> Optional[User]:
        normalized = email.strip().lower()
        return db.query(User).filter(User.email == normalized).first()

    @staticmethod
    def create_user(
        db: Session,
        email: str,
        password: str,
        full_name: str,
        organization_name: Optional[str] = None,
        role_ids: Optional[List[str]] = None
    ) -> User:
        normalized_email = email.strip().lower()
        pwd_hash = hash_password(password)

        user = User(
            email=normalized_email,
            password_hash=pwd_hash,
            full_name=full_name,
            organization_name=organization_name,
            is_active=True
        )
        db.add(user)
        db.flush()

        if role_ids:
            for rid in role_ids:
                role = db.query(Role).filter(Role.id == rid).first()
                if role and role not in user.roles:
                    user.roles.append(role)
        
        db.commit()
        db.refresh(user)
        return user

    @staticmethod
    def update_last_login(db: Session, user: User) -> None:
        user.last_login_at = datetime.now(timezone.utc)
        db.commit()

    @staticmethod
    def seed_standard_roles(db: Session) -> None:
        for r_data in STANDARD_ROLES:
            existing = db.query(Role).filter(Role.id == r_data["id"]).first()
            if not existing:
                role = Role(
                    id=r_data["id"],
                    name=r_data["name"],
                    description=r_data["description"]
                )
                db.add(role)
        db.commit()
