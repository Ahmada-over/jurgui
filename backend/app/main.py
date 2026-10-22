from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import select

from app.core.config import settings
from app.core.database import engine, Base, AsyncSessionLocal
from app.core.security import get_password_hash
import app.models  # Ensures all 24 models are registered on Base.metadata
from app.models.user import User, UserRole
from app.models.breed import Breed
from app.models.sector import Sector
from app.models.feed import FeedProduct

from app.api.v1.auth import router as auth_router
from app.api.v1.breeds import router as breeds_router
from app.api.v1.sectors import router as sectors_router
from app.api.v1.animals import router as animals_router
from app.api.v1.reproduction import router as reproduction_router
from app.api.v1.feed import router as feed_router
from app.api.v1.health import router as health_router
from app.api.v1.tasks import router as tasks_router
from app.api.v1.finances import router as finances_router
from app.api.v1.dashboard import router as dashboard_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: Create tables if not existing
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    # Seed initial data (Admin user, Breeds, Sectors, Feed catalog)
    async with AsyncSessionLocal() as session:
        # 1. Admin user
        admin_check = await session.execute(select(User).where(User.email == "admin@jurgui.sn"))
        if not admin_check.scalars().first():
            default_admin = User(
                email="admin@jurgui.sn",
                full_name="Administrateur Jur-gui",
                hashed_password=get_password_hash("admin1234"),
                role=UserRole.ADMIN.value,
                phone="+221770000000",
                is_active=True
            )
            session.add(default_admin)

        # 2. Breeds
        for breed_name in settings.INITIAL_BREEDS:
            breed_check = await session.execute(select(Breed).where(Breed.name == breed_name))
            if not breed_check.scalars().first():
                session.add(Breed(name=breed_name, is_active=True))

        # 3. Sectors
        for sec_data in settings.INITIAL_SECTORS:
            sec_check = await session.execute(select(Sector).where(Sector.name == sec_data["name"]))
            if not sec_check.scalars().first():
                session.add(Sector(
                    name=sec_data["name"],
                    description=sec_data["description"],
                    estimated_capacity=sec_data["estimated_capacity"],
                    status="active"
                ))

        # 4. Standard Feed Catalog
        initial_feeds = [
            {"name": "Son de blé", "category": "concentrate", "unit": "kg", "unit_price_cfa": 250.0, "current_stock": 500.0, "min_stock_threshold": 50.0},
            {"name": "Tourteau de coton", "category": "concentrate", "unit": "kg", "unit_price_cfa": 350.0, "current_stock": 300.0, "min_stock_threshold": 40.0},
            {"name": "Fanes d'arachide", "category": "forage", "unit": "botte", "unit_price_cfa": 1500.0, "current_stock": 100.0, "min_stock_threshold": 15.0},
            {"name": "Fanes de niébé", "category": "forage", "unit": "botte", "unit_price_cfa": 1800.0, "current_stock": 80.0, "min_stock_threshold": 10.0},
            {"name": "Bloc minéral / Pierre à lécher", "category": "mineral", "unit": "piece", "unit_price_cfa": 4000.0, "current_stock": 20.0, "min_stock_threshold": 5.0},
            {"name": "Ripasse (Litière copeaux)", "category": "supplement", "unit": "sac", "unit_price_cfa": 1000.0, "current_stock": 50.0, "min_stock_threshold": 10.0},
        ]
        for feed in initial_feeds:
            feed_check = await session.execute(select(FeedProduct).where(FeedProduct.name == feed["name"]))
            if not feed_check.scalars().first():
                session.add(FeedProduct(**feed))

        await session.commit()

    yield


app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="API de gestion de cheptel ovin pour l'Élevage Intelligent – Dakar (Jur-gui)",
    lifespan=lifespan,
)

# CORS configuration for Flutter Mobile & Web clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount API Routers
app.include_router(auth_router, prefix=settings.API_V1_STR)
app.include_router(breeds_router, prefix=settings.API_V1_STR)
app.include_router(sectors_router, prefix=settings.API_V1_STR)
app.include_router(animals_router, prefix=settings.API_V1_STR)
app.include_router(reproduction_router, prefix=settings.API_V1_STR)
app.include_router(feed_router, prefix=settings.API_V1_STR)
app.include_router(health_router, prefix=settings.API_V1_STR)
app.include_router(tasks_router, prefix=settings.API_V1_STR)
app.include_router(finances_router, prefix=settings.API_V1_STR)
app.include_router(dashboard_router, prefix=settings.API_V1_STR)


@app.get("/health", tags=["Health"])
async def health_check():
    return {
        "status": "healthy",
        "app": settings.PROJECT_NAME,
        "version": settings.VERSION,
        "mode": "offline-ready / cloud-ready"
    }
