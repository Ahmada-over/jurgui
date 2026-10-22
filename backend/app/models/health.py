from datetime import datetime, timezone, date
from sqlalchemy import Column, Integer, String, Text, Float, Date, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base


class HealthRecord(Base):
    __tablename__ = "health_records"

    id = Column(Integer, primary_key=True, index=True)
    animal_id = Column(String(50), ForeignKey("animals.id"), nullable=False, index=True)
    observation_date = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    symptoms = Column(Text, nullable=False)
    general_condition = Column(String(50), nullable=True)  # good, weakened, critical
    appetite_behavior = Column(String(50), nullable=True)  # normal, reduced, absent
    diagnostic = Column(Text, nullable=True)
    consulted_professional = Column(String(150), nullable=True)
    severity = Column(String(20), default="low", nullable=False)  # low, medium, high, critical
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    animal = relationship("Animal")
    user = relationship("User")
    treatments = relationship("Treatment", back_populates="health_record", cascade="all, delete-orphan")


class Treatment(Base):
    __tablename__ = "treatments"

    id = Column(Integer, primary_key=True, index=True)
    health_record_id = Column(Integer, ForeignKey("health_records.id"), nullable=True)
    animal_id = Column(String(50), ForeignKey("animals.id"), nullable=False, index=True)
    product_name = Column(String(100), nullable=False)  # ex: Lévamisole, Terramycine...
    active_substance = Column(String(100), nullable=True)
    dosage = Column(String(100), nullable=False)  # calculated with weight & prescription
    start_date = Column(Date, default=date.today, nullable=False)
    end_date = Column(Date, nullable=True)
    withdrawal_period_days = Column(Integer, default=0, nullable=False)  # Délai d'attente
    withdrawal_end_date = Column(Date, nullable=True)
    prescribing_vet = Column(String(150), nullable=True)
    administered_by = Column(String(150), nullable=True)
    result = Column(String(100), nullable=True)  # healed, in_progress, ineffective
    next_check_date = Column(Date, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    health_record = relationship("HealthRecord", back_populates="treatments")
    animal = relationship("Animal")


class Vaccination(Base):
    __tablename__ = "vaccinations"

    id = Column(Integer, primary_key=True, index=True)
    animal_id = Column(String(50), ForeignKey("animals.id"), nullable=False, index=True)
    vaccine_name = Column(String(100), nullable=False)
    administration_date = Column(Date, default=date.today, nullable=False)
    batch_number = Column(String(100), nullable=True)
    administered_by = Column(String(150), nullable=True)
    next_due_date = Column(Date, nullable=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    animal = relationship("Animal")


class HygieneTask(Base):
    __tablename__ = "hygiene_tasks"

    id = Column(Integer, primary_key=True, index=True)
    sector_id = Column(Integer, ForeignKey("sectors.id"), nullable=False, index=True)
    task_type = Column(String(50), nullable=False)  # litter_renewal_ripasse, trough_cleaning, feeder_cleaning, disinfection, inspection
    scheduled_date = Column(Date, nullable=False)
    frequency = Column(String(50), default="weekly", nullable=False)
    status = Column(String(50), default="scheduled", nullable=False)  # scheduled, in_progress, completed, cancelled
    material_used = Column(String(150), nullable=True)  # ex: Ripasse (copeaux/paille), désinfectant
    quantity_used = Column(Float, nullable=True)
    cost_cfa = Column(Float, default=0.0, nullable=True)
    assigned_to_user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    completed_at = Column(DateTime, nullable=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    sector = relationship("Sector")
    assigned_to = relationship("User")
