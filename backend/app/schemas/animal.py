from typing import Optional, List
from datetime import date, datetime
from pydantic import BaseModel, ConfigDict, field_validator
from app.schemas.breed import BreedOut
from app.schemas.sector import SectorOut


class WeightRecordBase(BaseModel):
    weight_kg: float
    recorded_at: Optional[datetime] = None
    notes: Optional[str] = None


class WeightRecordCreate(WeightRecordBase):
    pass


class WeightRecordOut(WeightRecordBase):
    id: int
    animal_id: str
    recorded_at: datetime
    recorded_by_user_id: Optional[int] = None

    model_config = ConfigDict(from_attributes=True)


class BodyConditionRecordBase(BaseModel):
    condition: str  # thin, normal, fat
    recorded_at: Optional[datetime] = None
    notes: Optional[str] = None


class BodyConditionRecordCreate(BodyConditionRecordBase):
    pass


class BodyConditionRecordOut(BodyConditionRecordBase):
    id: int
    animal_id: str
    recorded_at: datetime
    recorded_by_user_id: Optional[int] = None

    model_config = ConfigDict(from_attributes=True)


class AnimalMovementBase(BaseModel):
    to_sector_id: int
    reason: Optional[str] = None


class AnimalMovementCreate(AnimalMovementBase):
    pass


class AnimalMovementOut(BaseModel):
    id: int
    animal_id: str
    from_sector_id: Optional[int] = None
    to_sector_id: int
    movement_date: datetime
    moved_by_user_id: int
    reason: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


class AnimalBase(BaseModel):
    id: str  # e.g., NK-2026-01
    name: str
    physical_tag: Optional[str] = None
    photo_url: Optional[str] = None
    breed_id: int
    sex: str  # male, female
    birth_date: Optional[date] = None
    estimated_age_months: Optional[int] = None
    origin: str = "birth"  # birth, purchase, gift, other
    entry_date: Optional[date] = None
    seller_info: Optional[str] = None
    purchase_price_cfa: Optional[float] = None
    status: str = "active"  # active, sold, deceased, transferred
    current_sector_id: Optional[int] = None
    current_weight_kg: Optional[float] = None
    body_condition: str = "normal"  # thin, normal, fat
    reproduction_status: str = "not_pregnant"
    mother_id: Optional[str] = None
    father_id: Optional[str] = None
    lineage: Optional[str] = None
    notes: Optional[str] = None

    @field_validator("id")
    @classmethod
    def id_must_not_be_empty(cls, v: str) -> str:
        if not v or not v.strip():
            raise ValueError("L'identifiant interne est obligatoire")
        return v.strip()

    @field_validator("sex")
    @classmethod
    def validate_sex(cls, v: str) -> str:
        if v.lower() not in ("male", "female"):
            raise ValueError("Le sexe doit être 'male' ou 'female'")
        return v.lower()


class AnimalCreate(AnimalBase):
    pass


class AnimalUpdate(BaseModel):
    name: Optional[str] = None
    physical_tag: Optional[str] = None
    photo_url: Optional[str] = None
    breed_id: Optional[int] = None
    sex: Optional[str] = None
    birth_date: Optional[date] = None
    estimated_age_months: Optional[int] = None
    origin: Optional[str] = None
    entry_date: Optional[date] = None
    seller_info: Optional[str] = None
    purchase_price_cfa: Optional[float] = None
    status: Optional[str] = None
    current_sector_id: Optional[int] = None
    current_weight_kg: Optional[float] = None
    body_condition: Optional[str] = None
    reproduction_status: Optional[str] = None
    mother_id: Optional[str] = None
    father_id: Optional[str] = None
    lineage: Optional[str] = None
    notes: Optional[str] = None


class AnimalOut(AnimalBase):
    created_at: datetime
    updated_at: datetime
    breed: Optional[BreedOut] = None
    current_sector: Optional[SectorOut] = None

    model_config = ConfigDict(from_attributes=True)


class AnimalParentOut(BaseModel):
    id: str
    name: str
    sex: str
    lineage: Optional[str] = None
    breed: Optional[BreedOut] = None

    model_config = ConfigDict(from_attributes=True)


class AnimalGenealogyOut(BaseModel):
    animal: AnimalOut
    mother: Optional[AnimalParentOut] = None
    father: Optional[AnimalParentOut] = None
    maternal_grandparents: Optional[dict] = None
    paternal_grandparents: Optional[dict] = None
    offspring: List[AnimalParentOut] = []


class AnimalDetailOut(AnimalOut):
    movements: List[AnimalMovementOut] = []
    weight_records: List[WeightRecordOut] = []
    body_condition_records: List[BodyConditionRecordOut] = []

    model_config = ConfigDict(from_attributes=True)
