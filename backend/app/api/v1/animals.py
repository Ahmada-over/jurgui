from typing import List, Optional
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, or_
from sqlalchemy.orm import selectinload
from app.core.database import get_db
from app.models.animal import Animal, AnimalMovement, WeightRecord, BodyConditionRecord
from app.models.breed import Breed
from app.models.sector import Sector
from app.models.user import User
from app.schemas.animal import (
    AnimalCreate, AnimalOut, AnimalUpdate, AnimalDetailOut,
    AnimalMovementCreate, AnimalMovementOut,
    WeightRecordCreate, WeightRecordOut,
    BodyConditionRecordCreate, BodyConditionRecordOut,
    AnimalGenealogyOut, AnimalParentOut
)
from app.api.deps import get_current_user

router = APIRouter(prefix="/animals", tags=["Cheptel & Animaux"])


@router.get("", response_model=List[AnimalOut])
async def list_animals(
    breed_id: Optional[int] = None,
    sector_id: Optional[int] = None,
    sex: Optional[str] = None,
    status_filter: Optional[str] = Query("active", alias="status"),
    reproduction_status: Optional[str] = None,
    search: Optional[str] = None,
    skip: int = 0,
    limit: int = 100,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = (
        select(Animal)
        .options(selectinload(Animal.breed), selectinload(Animal.current_sector))
        .offset(skip)
        .limit(limit)
    )
    
    if status_filter and status_filter.lower() != "all":
        query = query.where(Animal.status == status_filter)
    if breed_id:
        query = query.where(Animal.breed_id == breed_id)
    if sector_id:
        query = query.where(Animal.current_sector_id == sector_id)
    if sex:
        query = query.where(Animal.sex == sex.lower())
    if reproduction_status:
        query = query.where(Animal.reproduction_status == reproduction_status)
    if search:
        search_term = f"%{search.strip()}%"
        query = query.where(
            or_(
                Animal.id.ilike(search_term),
                Animal.name.ilike(search_term),
                Animal.physical_tag.ilike(search_term),
            )
        )
    
    query = query.order_by(Animal.created_at.desc())
    result = await db.execute(query)
    animals = result.scalars().all()
    return [AnimalOut.model_validate(a) for a in animals]


@router.post("", response_model=AnimalOut, status_code=status.HTTP_201_CREATED)
async def create_animal(
    animal_in: AnimalCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Verify ID is unique
    existing = await db.execute(select(Animal).where(Animal.id == animal_in.id.strip()))
    if existing.scalars().first():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"L'identifiant '{animal_in.id}' est déjà attribué à un autre animal"
        )
    
    # Check breed exists
    breed_res = await db.execute(select(Breed).where(Breed.id == animal_in.breed_id))
    if not breed_res.scalars().first():
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Race spécifiée inexistante")
    
    # Check sector exists if provided
    if animal_in.current_sector_id:
        sector_res = await db.execute(select(Sector).where(Sector.id == animal_in.current_sector_id))
        if not sector_res.scalars().first():
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Secteur spécifié inexistant")
            
    # Check genealogy integrity: animal cannot be its own parent
    if animal_in.mother_id and animal_in.mother_id == animal_in.id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Un animal ne peut pas être sa propre mère")
    if animal_in.father_id and animal_in.father_id == animal_in.id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Un animal ne peut pas être son propre père")
        
    new_animal = Animal(
        id=animal_in.id.strip(),
        name=animal_in.name.strip(),
        physical_tag=animal_in.physical_tag.strip() if animal_in.physical_tag else None,
        photo_url=animal_in.photo_url,
        breed_id=animal_in.breed_id,
        sex=animal_in.sex.lower(),
        birth_date=animal_in.birth_date,
        estimated_age_months=animal_in.estimated_age_months,
        origin=animal_in.origin,
        entry_date=animal_in.entry_date or datetime.now(timezone.utc).date(),
        seller_info=animal_in.seller_info,
        purchase_price_cfa=animal_in.purchase_price_cfa,
        status=animal_in.status,
        current_sector_id=animal_in.current_sector_id,
        current_weight_kg=animal_in.current_weight_kg,
        body_condition=animal_in.body_condition,
        reproduction_status=animal_in.reproduction_status,
        mother_id=animal_in.mother_id,
        father_id=animal_in.father_id,
        notes=animal_in.notes
    )
    db.add(new_animal)
    
    # If initial weight is provided, record it in history
    if animal_in.current_weight_kg:
        initial_weight = WeightRecord(
            animal_id=new_animal.id,
            weight_kg=animal_in.current_weight_kg,
            recorded_by_user_id=current_user.id,
            notes="Pesée initiale à l'enregistrement"
        )
        db.add(initial_weight)
        
    # If initial sector is set, record movement
    if animal_in.current_sector_id:
        initial_movement = AnimalMovement(
            animal_id=new_animal.id,
            from_sector_id=None,
            to_sector_id=animal_in.current_sector_id,
            moved_by_user_id=current_user.id,
            reason="Affectation initiale à l'enclos"
        )
        db.add(initial_movement)
        
    await db.commit()
    
    # Reload with relationships
    query = (
        select(Animal)
        .options(selectinload(Animal.breed), selectinload(Animal.current_sector))
        .where(Animal.id == new_animal.id)
    )
    res = await db.execute(query)
    saved_animal = res.scalars().first()
    return AnimalOut.model_validate(saved_animal)


@router.get("/{animal_id}", response_model=AnimalDetailOut)
async def get_animal(
    animal_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = (
        select(Animal)
        .options(
            selectinload(Animal.breed),
            selectinload(Animal.current_sector),
            selectinload(Animal.movements),
            selectinload(Animal.weight_records),
            selectinload(Animal.body_condition_records),
        )
        .where(Animal.id == animal_id)
    )
    result = await db.execute(query)
    animal = result.scalars().first()
    if not animal:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Animal introuvable")
    return AnimalDetailOut.model_validate(animal)


@router.put("/{animal_id}", response_model=AnimalOut)
async def update_animal(
    animal_id: str,
    animal_in: AnimalUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = await db.execute(select(Animal).where(Animal.id == animal_id))
    animal = result.scalars().first()
    if not animal:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Animal introuvable")

    update_data = animal_in.model_dump(exclude_unset=True)
    for field, val in update_data.items():
        setattr(animal, field, val)
        
    await db.commit()
    
    # Reload with relations
    query = (
        select(Animal)
        .options(selectinload(Animal.breed), selectinload(Animal.current_sector))
        .where(Animal.id == animal_id)
    )
    res = await db.execute(query)
    return AnimalOut.model_validate(res.scalars().first())


@router.post("/{animal_id}/move", response_model=AnimalMovementOut)
async def move_animal_sector(
    animal_id: str,
    movement_in: AnimalMovementCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = await db.execute(select(Animal).where(Animal.id == animal_id))
    animal = result.scalars().first()
    if not animal:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Animal introuvable")
        
    target_sector_res = await db.execute(select(Sector).where(Sector.id == movement_in.to_sector_id))
    if not target_sector_res.scalars().first():
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Secteur de destination inexistant")
        
    if animal.current_sector_id == movement_in.to_sector_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="L'animal est déjà affecté à ce secteur"
        )

    previous_sector_id = animal.current_sector_id
    animal.current_sector_id = movement_in.to_sector_id

    movement = AnimalMovement(
        animal_id=animal.id,
        from_sector_id=previous_sector_id,
        to_sector_id=movement_in.to_sector_id,
        moved_by_user_id=current_user.id,
        reason=movement_in.reason or "Déplacement de routine"
    )
    db.add(movement)
    await db.commit()
    await db.refresh(movement)
    return AnimalMovementOut.model_validate(movement)


@router.post("/{animal_id}/weights", response_model=WeightRecordOut)
async def add_animal_weight(
    animal_id: str,
    weight_in: WeightRecordCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = await db.execute(select(Animal).where(Animal.id == animal_id))
    animal = result.scalars().first()
    if not animal:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Animal introuvable")

    record = WeightRecord(
        animal_id=animal.id,
        weight_kg=weight_in.weight_kg,
        recorded_at=(weight_in.recorded_at or datetime.now(timezone.utc)).replace(tzinfo=None),
        recorded_by_user_id=current_user.id,
        notes=weight_in.notes
    )
    animal.current_weight_kg = weight_in.weight_kg
    db.add(record)
    await db.commit()
    await db.refresh(record)
    return WeightRecordOut.model_validate(record)


@router.post("/{animal_id}/body-conditions", response_model=BodyConditionRecordOut)
async def add_animal_body_condition(
    animal_id: str,
    cond_in: BodyConditionRecordCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = await db.execute(select(Animal).where(Animal.id == animal_id))
    animal = result.scalars().first()
    if not animal:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Animal introuvable")

    record = BodyConditionRecord(
        animal_id=animal.id,
        condition=cond_in.condition.lower(),
        recorded_at=(cond_in.recorded_at or datetime.now(timezone.utc)).replace(tzinfo=None),
        recorded_by_user_id=current_user.id,
        notes=cond_in.notes
    )
    animal.body_condition = cond_in.condition.lower()
    db.add(record)
    await db.commit()
    await db.refresh(record)
    return BodyConditionRecordOut.model_validate(record)


@router.get("/{animal_id}/genealogy", response_model=AnimalGenealogyOut)
async def get_animal_genealogy(
    animal_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = (
        select(Animal)
        .options(
            selectinload(Animal.breed),
            selectinload(Animal.current_sector),
            selectinload(Animal.mother).selectinload(Animal.breed),
            selectinload(Animal.father).selectinload(Animal.breed),
        )
        .where(Animal.id == animal_id)
    )
    result = await db.execute(query)
    animal = result.scalars().first()
    if not animal:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Animal introuvable")

    # Fetch direct offspring
    offspring_res = await db.execute(
        select(Animal)
        .options(selectinload(Animal.breed))
        .where(or_(Animal.mother_id == animal.id, Animal.father_id == animal.id))
    )
    offspring_list = offspring_res.scalars().all()

    mother_out = AnimalParentOut.model_validate(animal.mother) if animal.mother else None
    father_out = AnimalParentOut.model_validate(animal.father) if animal.father else None
    offspring_out = [AnimalParentOut.model_validate(o) for o in offspring_list]

    return AnimalGenealogyOut(
        animal=AnimalOut.model_validate(animal),
        mother=mother_out,
        father=father_out,
        offspring=offspring_out
    )
