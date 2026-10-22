from datetime import datetime, timezone, date
from sqlalchemy import Column, Integer, String, Text, Date, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base


class MatingEvent(Base):
    __tablename__ = "mating_events"

    id = Column(Integer, primary_key=True, index=True)
    female_id = Column(String(50), ForeignKey("animals.id"), nullable=False, index=True)
    ram_id = Column(String(50), ForeignKey("animals.id"), nullable=True, index=True)
    mating_date = Column(DateTime, nullable=False)
    mating_type = Column(String(50), default="natural", nullable=False)  # natural, assisted
    status = Column(String(50), default="observed", nullable=False)  # observed, declared, confirmed, to_verify
    notes = Column(Text, nullable=True)
    registered_by_user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    female = relationship("Animal", foreign_keys=[female_id])
    ram = relationship("Animal", foreign_keys=[ram_id])
    registered_by = relationship("User")
    pregnancy = relationship("Pregnancy", back_populates="mating_event", uselist=False)


class Pregnancy(Base):
    __tablename__ = "pregnancies"

    id = Column(Integer, primary_key=True, index=True)
    female_id = Column(String(50), ForeignKey("animals.id"), nullable=False, index=True)
    mating_event_id = Column(Integer, ForeignKey("mating_events.id"), nullable=True, unique=True)
    ram_id = Column(String(50), ForeignKey("animals.id"), nullable=True)
    
    start_date = Column(Date, nullable=False)
    gestation_duration_days = Column(Integer, default=150, nullable=False)
    expected_birth_date = Column(Date, nullable=False)
    
    confirmation_status = Column(String(50), default="unverified", nullable=False)  # unverified, suspected, confirmed, not_pregnant
    confirmation_date = Column(Date, nullable=True)
    confirmation_method = Column(String(100), nullable=True)
    professional_name = Column(String(100), nullable=True)
    
    status = Column(String(50), default="in_progress", nullable=False)  # in_progress, completed, aborted
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    female = relationship("Animal", foreign_keys=[female_id])
    ram = relationship("Animal", foreign_keys=[ram_id])
    mating_event = relationship("MatingEvent", back_populates="pregnancy")
    birth = relationship("Birth", back_populates="pregnancy", uselist=False)


class Birth(Base):
    __tablename__ = "births"

    id = Column(Integer, primary_key=True, index=True)
    pregnancy_id = Column(Integer, ForeignKey("pregnancies.id"), nullable=True, unique=True)
    female_id = Column(String(50), ForeignKey("animals.id"), nullable=False, index=True)
    ram_id = Column(String(50), ForeignKey("animals.id"), nullable=True)
    
    birth_date = Column(DateTime, nullable=False)
    total_lambs = Column(Integer, default=1, nullable=False)
    alive_count = Column(Integer, default=1, nullable=False)
    stillborn_count = Column(Integer, default=0, nullable=False)
    male_count = Column(Integer, default=0, nullable=False)
    female_count = Column(Integer, default=0, nullable=False)
    
    difficulties = Column(Text, nullable=True)
    interventions = Column(Text, nullable=True)
    health_notes = Column(Text, nullable=True)
    registered_by_user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    pregnancy = relationship("Pregnancy", back_populates="birth")
    female = relationship("Animal", foreign_keys=[female_id])
    ram = relationship("Animal", foreign_keys=[ram_id])
    registered_by = relationship("User")
    offspring_links = relationship("Offspring", back_populates="birth", cascade="all, delete-orphan")


class Offspring(Base):
    __tablename__ = "offspring"

    id = Column(Integer, primary_key=True, index=True)
    birth_id = Column(Integer, ForeignKey("births.id"), nullable=False, index=True)
    lamb_id = Column(String(50), ForeignKey("animals.id"), nullable=False, unique=True)
    notes = Column(Text, nullable=True)

    birth = relationship("Birth", back_populates="offspring_links")
    lamb = relationship("Animal", foreign_keys=[lamb_id])
