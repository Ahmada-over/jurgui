from typing import List
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    PROJECT_NAME: str = "Jur-gui — Élevage Intelligent Dakar"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    
    # Secret Key for JWT
    SECRET_KEY: str = "dakar-ladoum-jur-gui-super-secret-key-2026-production-ready"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days
    
    # Database URL: default to async SQLite for local/test, configurable to PostgreSQL
    # Example for Postgres: postgresql+asyncpg://postgres:postgres@localhost:5432/jurgui
    DATABASE_URL: str = "sqlite+aiosqlite:///./jurgui.db"
    
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

