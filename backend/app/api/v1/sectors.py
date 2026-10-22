from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from backend.app.core.database import get_db
from backend.app.models.sector import Sector
from backend.app.models.animal import Animal
from backend.app.models.user import User
from backend.app.schemas.sector import SectorCreate, SectorOut, SectorUpdate
from backend.app.api.deps import get_current_user, get_current_admin

router = APIRouter(prefix="/sectors", tags=["Secteurs & Enclos"])


@router.get("", response_model=List[SectorOut])
async def list_sectors(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Fetch sectors with count of active animals in each sector
    result = await db.execute(select(Sector).order_by(Sector.name))
    sectors = result.scalars().all()
    
    # Query animal count per sector
    counts_query = (
        select(Animal.current_sector_id, func.count(Animal.id))
        .where(Animal.status == "active", Animal.current_sector_id.isnot(None))
        .group_by(Animal.current_sector_id)
    )
    counts_res = await db.execute(counts_query)
    counts_map = dict(counts_res.all())
    
    output = []
    for s in sectors:
        s_out = SectorOut.model_validate(s)
        s_out.current_occupancy = counts_map.get(s.id, 0)
        output.append(s_out)
    return output


@router.post("", response_model=SectorOut, status_code=status.HTTP_201_CREATED)
async def create_sector(
    sector_in: SectorCreate,
    db: AsyncSession = Depends(get_db),
    current_admin: User = Depends(get_current_admin)
):
    existing = await db.execute(select(Sector).where(Sector.name == sector_in.name.strip()))
    if existing.scalars().first():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Le secteur '{sector_in.name}' existe déjà"
        )
    
    new_sector = Sector(
        name=sector_in.name.strip(),
        description=sector_in.description,
        estimated_capacity=sector_in.estimated_capacity,
        status=sector_in.status,
        notes=sector_in.notes
    )
    db.add(new_sector)
    await db.commit()
    await db.refresh(new_sector)
    out = SectorOut.model_validate(new_sector)
    out.current_occupancy = 0
    return out


@router.get("/{sector_id}", response_model=SectorOut)
async def get_sector(
    sector_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = await db.execute(select(Sector).where(Sector.id == sector_id))
    sector = result.scalars().first()
    if not sector:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Secteur introuvable")
    
    count_res = await db.execute(
        select(func.count(Animal.id)).where(Animal.status == "active", Animal.current_sector_id == sector_id)
    )
    count = count_res.scalar() or 0
    out = SectorOut.model_validate(sector)
    out.current_occupancy = count
    return out


@router.put("/{sector_id}", response_model=SectorOut)
async def update_sector(
    sector_id: int,
    sector_in: SectorUpdate,
    db: AsyncSession = Depends(get_db),
    current_admin: User = Depends(get_current_admin)
):
    result = await db.execute(select(Sector).where(Sector.id == sector_id))
    sector = result.scalars().first()
    if not sector:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Secteur introuvable")
    
    if sector_in.name is not None:
        sector.name = sector_in.name.strip()
    if sector_in.description is not None:
        sector.description = sector_in.description
    if sector_in.estimated_capacity is not None:
        sector.estimated_capacity = sector_in.estimated_capacity
    if sector_in.status is not None:
        sector.status = sector_in.status
    if sector_in.notes is not None:
        sector.notes = sector_in.notes
        
    await db.commit()
    await db.refresh(sector)
    
    count_res = await db.execute(
        select(func.count(Animal.id)).where(Animal.status == "active", Animal.current_sector_id == sector_id)
    )
    out = SectorOut.model_validate(sector)
    out.current_occupancy = count_res.scalar() or 0
    return out
