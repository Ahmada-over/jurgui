from typing import Dict, Any, List
from datetime import datetime, timezone, timedelta
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from app.core.database import get_db
from app.models.animal import Animal
from app.models.breed import Breed
from app.models.sector import Sector
from app.models.reproduction import Pregnancy
from app.models.feed import FeedProduct
from app.models.task_notification import Task
from app.models.health import HealthRecord
from app.models.user import User
from app.api.deps import get_current_user

router = APIRouter(prefix="/dashboard", tags=["Tableau de Bord & Statistiques"])


@router.get("/overview")
async def get_dashboard_overview(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Dict[str, Any]:
    today = datetime.now(timezone.utc).date()
    in_30_days = today + timedelta(days=30)

    # Total active animals
    tot_active_res = await db.execute(select(func.count(Animal.id)).where(Animal.status == "active"))
    total_active_animals = tot_active_res.scalar() or 0

    # Breakdown by breed
    breed_query = (
        select(Breed.name, func.count(Animal.id))
        .join(Animal, Animal.breed_id == Breed.id)
        .where(Animal.status == "active")
        .group_by(Breed.name)
    )
    breed_res = await db.execute(breed_query)
    by_breed = dict(breed_res.all())

    # Breakdown by sex
    sex_query = (
        select(Animal.sex, func.count(Animal.id))
        .where(Animal.status == "active")
        .group_by(Animal.sex)
    )
    sex_res = await db.execute(sex_query)
    by_sex = dict(sex_res.all())

    # Breakdown by sector & capacity check
    sector_res = await db.execute(select(Sector))
    sectors = sector_res.scalars().all()
    sector_breakdown = []
    for sec in sectors:
        occ_res = await db.execute(
            select(func.count(Animal.id)).where(Animal.status == "active", Animal.current_sector_id == sec.id)
        )
        count = occ_res.scalar() or 0
        sector_breakdown.append({
            "sector_id": sec.id,
            "sector_name": sec.name,
            "occupancy": count,
            "capacity": sec.estimated_capacity,
            "is_overcrowded": count > sec.estimated_capacity if sec.estimated_capacity > 0 else False
        })

    # Active pregnancies and upcoming births (next 30 days)
    active_preg_res = await db.execute(
        select(func.count(Pregnancy.id)).where(Pregnancy.status == "in_progress")
    )
    active_pregnancies_count = active_preg_res.scalar() or 0

    upcoming_births_res = await db.execute(
        select(Pregnancy)
        .where(Pregnancy.status == "in_progress", Pregnancy.expected_birth_date <= in_30_days)
        .order_by(Pregnancy.expected_birth_date.asc())
    )
    upcoming_births = [
        {
            "pregnancy_id": p.id,
            "female_id": p.female_id,
            "expected_date": p.expected_birth_date.isoformat(),
            "days_left": (p.expected_birth_date - today).days
        }
        for p in upcoming_births_res.scalars().all()
    ]

    # Pending tasks
    pending_tasks_res = await db.execute(
        select(func.count(Task.id)).where(Task.status.in_(["pending", "in_progress"]))
    )
    pending_tasks_count = pending_tasks_res.scalar() or 0

    # Low stock alerts
    low_stocks_res = await db.execute(
        select(FeedProduct).where(FeedProduct.current_stock <= FeedProduct.min_stock_threshold)
    )
    low_stocks = [
        {
            "product_id": p.id,
            "name": p.name,
            "current_stock": p.current_stock,
            "min_threshold": p.min_stock_threshold,
            "unit": p.unit
        }
        for p in low_stocks_res.scalars().all()
    ]

    # Recent critical/high health observations
    recent_health_res = await db.execute(
        select(HealthRecord)
        .where(HealthRecord.severity.in_(["high", "critical"]))
        .order_by(HealthRecord.observation_date.desc())
        .limit(5)
    )
    urgent_health = [
        {
            "id": h.id,
            "animal_id": h.animal_id,
            "symptoms": h.symptoms,
            "severity": h.severity,
            "date": h.observation_date.isoformat()
        }
        for h in recent_health_res.scalars().all()
    ]

    return {
        "cheptel": {
            "total_active": total_active_animals,
            "by_breed": by_breed,
            "by_sex": by_sex,
            "sectors": sector_breakdown,
        },
        "reproduction": {
            "active_pregnancies": active_pregnancies_count,
            "upcoming_births_next_30_days": upcoming_births,
        },
        "operations": {
            "pending_tasks": pending_tasks_count,
            "low_stock_alerts": low_stocks,
            "urgent_health_cases": urgent_health,
        }
    }
