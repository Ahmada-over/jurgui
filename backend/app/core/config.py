from typing import List
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    PROJECT_NAME: str = "Jur-gui — Élevage Intelligent Dakar"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    
    # Environment: development | staging | production
    ENVIRONMENT: str = "development"
    
    # Secret Key for JWT
    SECRET_KEY: str = "dakar-ladoum-jur-gui-super-secret-key-2026-production-ready"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days
    
    # Database URL (Neon PostgreSQL / PostgreSQL asyncpg)
    DATABASE_URL: str = (
        "postgresql+asyncpg://neondb_owner:npg_QmENJ67foLtb"
        "@ep-icy-forest-b42rgcj6-pooler.c-6.us-east-2.aws.neon.tech/neondb"
    )
    DATABASE_SSL: bool = True  # Activé par défaut pour Neon PostgreSQL
    
    # Connection pool settings (tuned for Neon serverless)
    DB_POOL_SIZE: int = 5
    DB_MAX_OVERFLOW: int = 10
    DB_POOL_RECYCLE: int = 300  # Recycle before Neon's 5-min idle timeout
    
    # Cloud Run: PORT is injected by GCP
    PORT: int = 8000
    
    # CORS: restrict in production
    ALLOWED_ORIGINS: str = "*"  # Comma-separated in production, e.g. "https://jurgui.sn,https://app.jurgui.sn"
    
    # Default breeding settings
    DEFAULT_GESTATION_DAYS: int = 150
    DEFAULT_CURRENCY: str = "FCFA"
    
    # Seed data
    INITIAL_BREEDS: List[str] = ["Ladoum", "Métisse Ladoum", "Peulh Peulh"]
    INITIAL_SECTORS: List[dict] = [
        {"name": "Zone Ladoum/Métis", "description": "Enclos principal réservé aux ovins Ladoum et croisés Métis", "estimated_capacity": 30},
        {"name": "Zone Peulh Peulh", "description": "Enclos réservé aux ovins de race rustique Peulh Peulh", "estimated_capacity": 40},
    ]

    model_config = SettingsConfigDict(
        env_file=".env",
        case_sensitive=True
    )


settings = Settings()


