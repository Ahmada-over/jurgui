from typing import Optional, List
from datetime import date, datetime
from pydantic import BaseModel, ConfigDict


class TreatmentCreate(BaseModel):
    product_name: str
    active_substance: Optional[str] = None
    dosage: str
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    withdrawal_period_days: int = 0
    prescribing_vet: Optional[str] = None
    administered_by: Optional[str] = None
    notes: Optional[str] = None


class TreatmentOut(TreatmentCreate):
    id: int
    health_record_id: Optional[int] = None
    animal_id: str
    withdrawal_end_date: Optional[date] = None
    result: Optional[str] = None
    next_check_date: Optional[date] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class HealthRecordCreate(BaseModel):
    animal_id: str
    symptoms: str
    general_condition: Optional[str] = None
    appetite_behavior: Optional[str] = None
    diagnostic: Optional[str] = None
    consulted_professional: Optional[str] = None
    severity: str = "low"  # low, medium, high, critical
    notes: Optional[str] = None
    treatments: List[TreatmentCreate] = []


class HealthRecordOut(BaseModel):
    id: int
    animal_id: str
    observation_date: datetime
    symptoms: str
    general_condition: Optional[str] = None
    appetite_behavior: Optional[str] = None
    diagnostic: Optional[str] = None
    consulted_professional: Optional[str] = None
    severity: str
    user_id: int
    notes: Optional[str] = None
    created_at: datetime
    treatments: List[TreatmentOut] = []

    model_config = ConfigDict(from_attributes=True)


class VaccinationCreate(BaseModel):
    animal_id: str
    vaccine_name: str
    administration_date: Optional[date] = None
    batch_number: Optional[str] = None
    administered_by: Optional[str] = None
    next_due_date: Optional[date] = None
    notes: Optional[str] = None


class VaccinationOut(VaccinationCreate):
    id: int
    administration_date: date
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class HygieneTaskCreate(BaseModel):
    sector_id: int
    task_type: str  # litter_renewal_ripasse, trough_cleaning, feeder_cleaning, disinfection, inspection
    scheduled_date: date
    frequency: str = "weekly"
    material_used: Optional[str] = None
    quantity_used: Optional[float] = None
    cost_cfa: Optional[float] = 0.0
    assigned_to_user_id: Optional[int] = None
    notes: Optional[str] = None


class HygieneTaskOut(HygieneTaskCreate):
    id: int
    status: str
    completed_at: Optional[datetime] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
