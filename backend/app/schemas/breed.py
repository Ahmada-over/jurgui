from typing import Optional
from datetime import datetime
from pydantic import BaseModel, ConfigDict


class BreedBase(BaseModel):
    name: str
    description: Optional[str] = None
    origin: Optional[str] = None
    is_active: bool = True


class BreedCreate(BreedBase):
    pass


class BreedUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    origin: Optional[str] = None
    is_active: Optional[bool] = None


class BreedOut(BreedBase):
    id: int
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
