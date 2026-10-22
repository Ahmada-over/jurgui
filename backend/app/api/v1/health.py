from typing import List, Optional
from datetime import datetime, timezone, timedelta, date
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from app.core.database import get_db
from app.models.health import HealthRecord, Treatment, Vaccination, HygieneTask
from app.models.animal import Animal
from app.models.sector import Sector
from app.models.user import User
from app.schemas.health import (
    HealthRecordCreate, HealthRecordOut,
    VaccinationCreate, VaccinationOut,
    HygieneTaskCreate, HygieneTaskOut
)
from app.api.deps import get_current_user

router = APIRouter(prefix="/health", tags=["Santé animale & Hygiène"])


@router.post("/observations", response_model=HealthRecordOut, status_code=status.HTTP_201_CREATED)
async def create_health_observation(
    obs_in: HealthRecordCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    anim_res = await db.execute(select(Animal).where(Animal.id == obs_in.animal_id))
    animal = anim_res.scalars().first()
    if not animal:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Animal introuvable")

    record = HealthRecord(
        animal_id=animal.id,
        symptoms=obs_in.symptoms,
        general_condition=obs_in.general_condition,
        appetite_behavior=obs_in.appetite_behavior,
        diagnostic=obs_in.diagnostic,
        consulted_professional=obs_in.consulted_professional,
        severity=obs_in.severity,
        notes=obs_in.notes,
        user_id=current_user.id
    )
    db.add(record)
    await db.flush()

    for treat_in in obs_in.treatments:
        start_d = treat_in.start_date or datetime.now(timezone.utc).date()
        withdrawal_end = start_d + timedelta(days=treat_in.withdrawal_period_days) if treat_in.withdrawal_period_days > 0 else None
        
        treatment = Treatment(
            health_record_id=record.id,
            animal_id=animal.id,
            product_name=treat_in.product_name,
            active_substance=treat_in.active_substance,
            dosage=treat_in.dosage,
            start_date=start_d,
            end_date=treat_in.end_date,
            withdrawal_period_days=treat_in.withdrawal_period_days,
            withdrawal_end_date=withdrawal_end,
            prescribing_vet=treat_in.prescribing_vet or obs_in.consulted_professional,
            administered_by=treat_in.administered_by or current_user.full_name,
            result="in_progress"
        )
        db.add(treatment)

    await db.commit()

    query = select(HealthRecord).options(selectinload(HealthRecord.treatments)).where(HealthRecord.id == record.id)
    res = await db.execute(query)
    return HealthRecordOut.model_validate(res.scalars().first())


@router.get("/observations", response_model=List[HealthRecordOut])
async def list_health_observations(
    animal_id: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = select(HealthRecord).options(selectinload(HealthRecord.treatments)).order_by(HealthRecord.observation_date.desc())
    if animal_id:
        query = query.where(HealthRecord.animal_id == animal_id)
    res = await db.execute(query)
    return [HealthRecordOut.model_validate(r) for r in res.scalars().all()]


@router.post("/vaccinations", response_model=VaccinationOut, status_code=status.HTTP_201_CREATED)
async def record_vaccination(
    vac_in: VaccinationCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    anim_res = await db.execute(select(Animal).where(Animal.id == vac_in.animal_id))
    if not anim_res.scalars().first():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Animal introuvable")

    vaccination = Vaccination(
        animal_id=vac_in.animal_id,
        vaccine_name=vac_in.vaccine_name,
        administration_date=vac_in.administration_date or datetime.now(timezone.utc).date(),
        batch_number=vac_in.batch_number,
        administered_by=vac_in.administered_by or current_user.full_name,
        next_due_date=vac_in.next_due_date,
        notes=vac_in.notes
    )
    db.add(vaccination)
    await db.commit()
    await db.refresh(vaccination)
    return VaccinationOut.model_validate(vaccination)


@router.get("/vaccinations", response_model=List[VaccinationOut])
async def list_vaccinations(
    animal_id: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = select(Vaccination).order_by(Vaccination.administration_date.desc())
    if animal_id:
        query = query.where(Vaccination.animal_id == animal_id)
    res = await db.execute(query)
    return [VaccinationOut.model_validate(v) for v in res.scalars().all()]


@router.post("/hygiene", response_model=HygieneTaskOut, status_code=status.HTTP_201_CREATED)
async def schedule_hygiene_task(
    task_in: HygieneTaskCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    sec_res = await db.execute(select(Sector).where(Sector.id == task_in.sector_id))
    if not sec_res.scalars().first():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Secteur introuvable")

    task = HygieneTask(
        sector_id=task_in.sector_id,
        task_type=task_in.task_type,
        scheduled_date=task_in.scheduled_date,
        frequency=task_in.frequency,
        status="scheduled",
        material_used=task_in.material_used,
        quantity_used=task_in.quantity_used,
        cost_cfa=task_in.cost_cfa or 0.0,
        assigned_to_user_id=task_in.assigned_to_user_id or current_user.id,
        notes=task_in.notes
    )
    db.add(task)
    await db.commit()
    await db.refresh(task)
    return HygieneTaskOut.model_validate(task)


@router.get("/hygiene", response_model=List[HygieneTaskOut])
async def list_hygiene_tasks(
    sector_id: Optional[int] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = select(HygieneTask).order_by(HygieneTask.scheduled_date.asc())
    if sector_id:
        query = query.where(HygieneTask.sector_id == sector_id)
    res = await db.execute(query)
    return [HygieneTaskOut.model_validate(t) for t in res.scalars().all()]


@router.put("/hygiene/{task_id}/complete", response_model=HygieneTaskOut)
async def complete_hygiene_task(
    task_id: int,
    notes: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    res = await db.execute(select(HygieneTask).where(HygieneTask.id == task_id))
    task = res.scalars().first()
    if not task:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Tâche d'hygiène introuvable")

    task.status = "completed"
    task.completed_at = datetime.now(timezone.utc)
    if notes:
        task.notes = (task.notes or "") + f" | Réalisation: {notes}"

    await db.commit()
    await db.refresh(task)
    return HygieneTaskOut.model_validate(task)
