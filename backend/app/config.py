try:
    from pydantic_settings import BaseSettings
except ImportError:
    from pydantic import BaseModel as BaseSettings
from typing import Dict, Any


class Settings(BaseSettings):
    APP_NAME: str = "MAUSAM Decision Engine"
    API_V1_PREFIX: str = "/api/v1"
    DEBUG: bool = True
    
    # Database & Authentication Configuration
    DATABASE_URL: str = "postgresql+psycopg://localhost:5432/mausam_db"
    JWT_SECRET: str = "mausam-super-secret-jwt-key-for-sih-2026-rmc-transit-loss-prevention-platform"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440  # 24 hours
    
    # Development Seed Credentials
    SEED_DEV_USER_EMAIL: str = "rmc.demo@mausam.local"
    SEED_DEV_USER_PASSWORD: str = "RmcManager2026!"
    ENVIRONMENT: str = "development"

    # Operational Thresholds (PRD.md Section 3.4)
    SAFE_TRANSIT_MAX_MINUTES: float = 78.0
    SAFE_SLUMP_RETENTION_MIN_RATIO: float = 0.92
    
    # Risk weights for composite score (PRD.md Section 4.3)
    WEIGHT_HEAT_RISK: float = 0.30
    WEIGHT_TRAVEL_RISK: float = 0.30
    WEIGHT_DELIVERY_RISK: float = 0.40
    
    # Default Plant & Project Coords (Ahmedabad corridor)
    DEFAULT_PLANT_LAT: float = 23.0225
    DEFAULT_PLANT_LNG: float = 72.5714
    DEFAULT_PLANT_NAME: str = "Ahmedabad Plant 01"
    
    DEFAULT_PROJECT_LAT: float = 23.0900
    DEFAULT_PROJECT_LNG: float = 72.6100
    DEFAULT_PROJECT_NAME: str = "Project Site 07 (Gift City Expansion)"

    # Financial defaults
    DEFAULT_LOSS_PER_REJECTED_M3_INR: float = 40166.67  # ~2.41 Lakhs for 6 m3
    
    model_config = {
        "extra": "ignore",
        "env_file": ".env",
        "env_file_encoding": "utf-8"
    }


settings = Settings()
