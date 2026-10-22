from typing import Optional, List
from datetime import date, datetime
from pydantic import BaseModel, ConfigDict


class MatingEventBase(BaseModel):
    female_id: str
    ram_id: Optional[str] = None
    mating_date: datetime
    mating_type: str = "natural"  # natural, assisted
    status: str = "observed"  # observed, declared, confirmed, to_verify
    notes: Optional[str] = None


class MatingEventCreate(MatingEventBase):
    pass


class MatingEventOut(MatingEventBase):
    id: int
    registered_by_user_id: int
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class GestationTimelineItem(BaseModel):
    day_offset: int
    title: str
    target_date: date
    action_description: str
    is_passed: bool = False


class PregnancyBase(BaseModel):
    female_id: str
    mating_event_id: Optional[int] = None
    ram_id: Optional[str] = None
    start_date: date
    gestation_duration_days: int = 150
    expected_birth_date: Optional[date] = None
    confirmation_status: str = "unverified"  # unverified, suspected, confirmed, not_pregnant
    confirmation_date: Optional[date] = None
    confirmation_method: Optional[str] = None
    professional_name: Optional[str] = None
    status: str = "in_progress"  # in_progress, completed, aborted
    notes: Optional[str] = None


class PregnancyCreate(BaseModel):
    female_id: str
    mating_event_id: Optional[int] = None
    ram_id: Optional[str] = None
    start_date: date
    gestation_duration_days: int = 150
    confirmation_status: str = "unverified"
    notes: Optional[str] = None


class PregnancyUpdate(BaseModel):
    gestation_duration_days: Optional[int] = None
    confirmation_status: Optional[str] = None
    confirmation_date: Optional[date] = None
    confirmation_method: Optional[str] = None
    professional_name: Optional[str] = None
    status: Optional[str] = None
    notes: Optional[str] = None


class PregnancyOut(PregnancyBase):
    id: int
    created_at: datetime
    timeline: List[GestationTimelineItem] = []

    model_config = ConfigDict(from_attributes=True)


class LambBirthInput(BaseModel):
    id: str  # internal code NK-2026-XX
    name: str
    sex: str  # male, female
    weight_kg: Optional[float] = None
    physical_tag: Optional[str] = None


class BirthCreate(BaseModel):
    pregnancy_id: Optional[int] = None
    female_id: str
    ram_id: Optional[str] = None
    birth_date: datetime
    total_lambs: int = 1
    alive_count: int = 1
    stillborn_count: int = 0
    male_count: int = 0
    female_count: int = 0
    difficulties: Optional[str] = None
    interventions: Optional[str] = None
    health_notes: Optional[str] = None
    new_lambs: List[LambBirthInput] = []


class BirthOut(BaseModel):
    id: int
    pregnancy_id: Optional[int] = None
    female_id: str
    ram_id: Optional[str] = None
    birth_date: datetime
    total_lambs: int
    alive_count: int
    stillborn_count: int
    male_count: int
    female_count: int
    difficulties: Optional[str] = None
    interventions: Optional[str] = None
    health_notes: Optional[str] = None
    registered_by_user_id: int
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
