from typing import Optional
from datetime import datetime
from pydantic import BaseModel, ConfigDict


class SectorBase(BaseModel):
    name: str
    description: Optional[str] = None
    estimated_capacity: int = 0
    status: str = "active"
    notes: Optional[str] = None


class SectorCreate(SectorBase):
    pass


class SectorUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    estimated_capacity: Optional[int] = None
    status: Optional[str] = None
    notes: Optional[str] = None


class SectorOut(SectorBase):
    id: int
    created_at: datetime
    current_occupancy: Optional[int] = 0

    model_config = ConfigDict(from_attributes=True)
