from typing import List
from datetime import timedelta, datetime, timezone, date
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from backend.app.core.database import get_db
from backend.app.models.reproduction import MatingEvent, Pregnancy, Birth, Offspring
from backend.app.models.animal import Animal
from backend.app.models.task_notification import Task, Notification
from backend.app.models.user import User
from backend.app.schemas.reproduction import (
    MatingEventCreate, MatingEventOut,
    PregnancyCreate, PregnancyOut, PregnancyUpdate, GestationTimelineItem,
    BirthCreate, BirthOut
)
from backend.app.api.deps import get_current_user

router = APIRouter(prefix="/reproduction", tags=["Reproduction & Généalogie"])


MILESTONES = [
    (90, "Vérification nutritionnelle & transition", "Vérifier les besoins nutritionnels et préparer la transition alimentaire si nécessaire."),
    (105, "Bilan sanitaire & vétérinaire", "Examiner le calendrier sanitaire et vérifier avec le vétérinaire les interventions appropriées."),
    (120, "Évaluation état corporel", "Évaluer l'état corporel et les besoins nutritionnels avec un professionnel compétent."),
    (135, "Vérification ration fin de gestation", "Vérifier la ration, la qualité des aliments et les consignes adaptées à la fin de gestation."),
    (145, "Préparation espace mise bas", "Préparer l'espace de mise bas et renforcer la surveillance."),
    (150, "Surveillance renforcée mise bas", "Date théorique de mise bas : surveillance renforcée selon les consignes de l'éleveur et du vétérinaire."),
]


def build_timeline(start_date: date, gestation_days: int) -> List[GestationTimelineItem]:
    today = datetime.now(timezone.utc).date()
    items = []
    for day_offset, title, desc in MILESTONES:
        # Scale milestone if user configured different duration
        actual_offset = int(day_offset * (gestation_days / 150.0))
        target_d = start_date + timedelta(days=actual_offset)
        items.append(
            GestationTimelineItem(
                day_offset=actual_offset,
                title=title,
                target_date=target_d,
                action_description=desc,
                is_passed=(today >= target_d)
            )
        )
    return items


@router.post("/matings", response_model=MatingEventOut, status_code=status.HTTP_201_CREATED)
async def record_mating(
    mating_in: MatingEventCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Verify female exists and is female
    female_res = await db.execute(select(Animal).where(Animal.id == mating_in.female_id))
    female = female_res.scalars().first()
    if not female:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Brebis introuvable")
    if female.sex != "female":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="L'animal sélectionné comme mère doit être une femelle")
        
    if mating_in.ram_id:
        ram_res = await db.execute(select(Animal).where(Animal.id == mating_in.ram_id))
        ram = ram_res.scalars().first()
        if not ram:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Bélier introuvable")
        if ram.sex != "male":
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Le reproducteur doit être un mâle")

    mating = MatingEvent(
        female_id=mating_in.female_id,
        ram_id=mating_in.ram_id,
        mating_date=mating_in.mating_date,
        mating_type=mating_in.mating_type,
        status=mating_in.status,
        notes=mating_in.notes,
        registered_by_user_id=current_user.id
    )
    db.add(mating)
    await db.commit()
    await db.refresh(mating)
    return MatingEventOut.model_validate(mating)


@router.get("/matings", response_model=List[MatingEventOut])
async def list_matings(
    female_id: str = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = select(MatingEvent).order_by(MatingEvent.mating_date.desc())
    if female_id:
        query = query.where(MatingEvent.female_id == female_id)
    res = await db.execute(query)
    return [MatingEventOut.model_validate(m) for m in res.scalars().all()]


@router.post("/pregnancies", response_model=PregnancyOut, status_code=status.HTTP_201_CREATED)
async def create_pregnancy(
    preg_in: PregnancyCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    female_res = await db.execute(select(Animal).where(Animal.id == preg_in.female_id))
    female = female_res.scalars().first()
    if not female:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Brebis introuvable")

    duration = preg_in.gestation_duration_days or 150
    expected_date = preg_in.start_date + timedelta(days=duration)

    pregnancy = Pregnancy(
        female_id=preg_in.female_id,
        mating_event_id=preg_in.mating_event_id,
        ram_id=preg_in.ram_id,
        start_date=preg_in.start_date,
        gestation_duration_days=duration,
        expected_birth_date=expected_date,
        confirmation_status=preg_in.confirmation_status,
        status="in_progress",
        notes=preg_in.notes
    )
    db.add(pregnancy)
    female.reproduction_status = "suspected" if preg_in.confirmation_status == "unverified" else "confirmed"

    # Automatically generate tracking tasks for the 6 milestones
    timeline_items = build_timeline(preg_in.start_date, duration)
    for item in timeline_items:
        task = Task(
            title=f"Suivi Gestation ({female.name}) : {item.title}",
            description=item.action_description,
            category="reproduction",
            due_date=datetime.combine(item.target_date, datetime.min.time()),
            priority="high" if item.day_offset >= 145 else "medium",
            status="pending",
            animal_id=female.id,
            created_by_user_id=current_user.id
        )
        db.add(task)

    await db.commit()
    await db.refresh(pregnancy)
    
    out = PregnancyOut.model_validate(pregnancy)
    out.timeline = timeline_items
    return out


@router.get("/pregnancies", response_model=List[PregnancyOut])
async def list_pregnancies(
    status_filter: str = "in_progress",
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = select(Pregnancy).order_by(Pregnancy.expected_birth_date.asc())
    if status_filter and status_filter.lower() != "all":
        query = query.where(Pregnancy.status == status_filter)
    res = await db.execute(query)
    pregnancies = res.scalars().all()
    
    out_list = []
    for p in pregnancies:
        p_out = PregnancyOut.model_validate(p)
        p_out.timeline = build_timeline(p.start_date, p.gestation_duration_days)
        out_list.append(p_out)
    return out_list


@router.put("/pregnancies/{pregnancy_id}", response_model=PregnancyOut)
async def update_pregnancy(
    pregnancy_id: int,
    preg_in: PregnancyUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = await db.execute(select(Pregnancy).where(Pregnancy.id == pregnancy_id))
    pregnancy = result.scalars().first()
    if not pregnancy:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Gestation introuvable")

    if preg_in.gestation_duration_days is not None:
        pregnancy.gestation_duration_days = preg_in.gestation_duration_days
        pregnancy.expected_birth_date = pregnancy.start_date + timedelta(days=pregnancy.gestation_duration_days)
    if preg_in.confirmation_status is not None:
        pregnancy.confirmation_status = preg_in.confirmation_status
        # Update female animal reproduction status
        fem_res = await db.execute(select(Animal).where(Animal.id == pregnancy.female_id))
        fem = fem_res.scalars().first()
        if fem:
            if preg_in.confirmation_status == "confirmed":
                fem.reproduction_status = "confirmed"
            elif preg_in.confirmation_status == "not_pregnant":
                fem.reproduction_status = "not_pregnant"
    if preg_in.confirmation_date is not None:
        pregnancy.confirmation_date = preg_in.confirmation_date
    if preg_in.confirmation_method is not None:
        pregnancy.confirmation_method = preg_in.confirmation_method
    if preg_in.professional_name is not None:
        pregnancy.professional_name = preg_in.professional_name
    if preg_in.status is not None:
        pregnancy.status = preg_in.status
    if preg_in.notes is not None:
        pregnancy.notes = preg_in.notes

    await db.commit()
    await db.refresh(pregnancy)
    out = PregnancyOut.model_validate(pregnancy)
    out.timeline = build_timeline(pregnancy.start_date, pregnancy.gestation_duration_days)
    return out


@router.post("/births", response_model=BirthOut, status_code=status.HTTP_201_CREATED)
async def record_birth(
    birth_in: BirthCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    female_res = await db.execute(select(Animal).where(Animal.id == birth_in.female_id))
    mother = female_res.scalars().first()
    if not mother:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Mère introuvable")

    # If pregnancy provided, mark it completed
    ram_id = birth_in.ram_id
    if birth_in.pregnancy_id:
        preg_res = await db.execute(select(Pregnancy).where(Pregnancy.id == birth_in.pregnancy_id))
        pregnancy = preg_res.scalars().first()
        if pregnancy:
            pregnancy.status = "completed"
            if not ram_id:
                ram_id = pregnancy.ram_id

    birth = Birth(
        pregnancy_id=birth_in.pregnancy_id,
        female_id=birth_in.female_id,
        ram_id=ram_id,
        birth_date=birth_in.birth_date,
        total_lambs=birth_in.total_lambs,
        alive_count=birth_in.alive_count,
        stillborn_count=birth_in.stillborn_count,
        male_count=birth_in.male_count,
        female_count=birth_in.female_count,
        difficulties=birth_in.difficulties,
        interventions=birth_in.interventions,
        health_notes=birth_in.health_notes,
        registered_by_user_id=current_user.id
    )
    db.add(birth)
    await db.flush()  # to obtain birth.id

    # Automatically create lambs if provided in payload
    for lamb_in in birth_in.new_lambs:
        # Check id not duplicate
        dup_check = await db.execute(select(Animal).where(Animal.id == lamb_in.id.strip()))
        if dup_check.scalars().first():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"L'identifiant '{lamb_in.id}' pour le nouvel agneau existe déjà"
            )
        
        lamb = Animal(
            id=lamb_in.id.strip(),
            name=lamb_in.name.strip(),
            physical_tag=lamb_in.physical_tag,
            breed_id=mother.breed_id,
            sex=lamb_in.sex.lower(),
            birth_date=birth_in.birth_date.date(),
            origin="birth",
            entry_date=birth_in.birth_date.date(),
            current_sector_id=mother.current_sector_id,
            current_weight_kg=lamb_in.weight_kg,
            body_condition="normal",
            reproduction_status="not_pregnant",
            mother_id=mother.id,
            father_id=ram_id,
            status="active",
            notes=f"Né lors de la mise bas #{birth.id}"
        )
        db.add(lamb)
        await db.flush()

        offspring_link = Offspring(
            birth_id=birth.id,
            lamb_id=lamb.id,
            notes="Descendance confirmée à la naissance"
        )
        db.add(offspring_link)

    mother.reproduction_status = "lactating"
    await db.commit()
    await db.refresh(birth)
    return BirthOut.model_validate(birth)
