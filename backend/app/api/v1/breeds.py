from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from backend.app.core.database import get_db
from backend.app.models.breed import Breed
from backend.app.models.user import User
from backend.app.schemas.breed import BreedCreate, BreedOut, BreedUpdate
from backend.app.api.deps import get_current_user, get_current_admin

router = APIRouter(prefix="/breeds", tags=["Races Ovines"])


@router.get("", response_model=List[BreedOut])
async def list_breeds(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = await db.execute(select(Breed).order_by(Breed.name))
    return [BreedOut.model_validate(b) for b in result.scalars().all()]


@router.post("", response_model=BreedOut, status_code=status.HTTP_201_CREATED)
async def create_breed(
    breed_in: BreedCreate,
    db: AsyncSession = Depends(get_db),
    current_admin: User = Depends(get_current_admin)
):
    existing = await db.execute(select(Breed).where(Breed.name == breed_in.name.strip()))
    if existing.scalars().first():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"La race '{breed_in.name}' existe déjà"
        )
    
    new_breed = Breed(
        name=breed_in.name.strip(),
        description=breed_in.description,
        origin=breed_in.origin,
        is_active=breed_in.is_active
    )
    db.add(new_breed)
    await db.commit()
    await db.refresh(new_breed)
    return BreedOut.model_validate(new_breed)


@router.put("/{breed_id}", response_model=BreedOut)
async def update_breed(
    breed_id: int,
    breed_in: BreedUpdate,
    db: AsyncSession = Depends(get_db),
    current_admin: User = Depends(get_current_admin)
):
    result = await db.execute(select(Breed).where(Breed.id == breed_id))
    breed = result.scalars().first()
    if not breed:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Race introuvable")
    
    if breed_in.name is not None:
        breed.name = breed_in.name.strip()
    if breed_in.description is not None:
        breed.description = breed_in.description
    if breed_in.origin is not None:
        breed.origin = breed_in.origin
    if breed_in.is_active is not None:
        breed.is_active = breed_in.is_active
        
    await db.commit()
    await db.refresh(breed)
    return BreedOut.model_validate(breed)
