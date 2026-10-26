from datetime import date
from sqlalchemy import Column, Integer, String, Text, Float, Date, DateTime, ForeignKey, CheckConstraint
from sqlalchemy.orm import relationship
from app.core.database import Base, utc_now


class Animal(Base):
    __tablename__ = "animals"

    # ID format example: NK-2026-01 (Internal unique code)
    id = Column(String(50), primary_key=True, index=True)
    name = Column(String(100), index=True, nullable=False)
    physical_tag = Column(String(100), unique=True, index=True, nullable=True)  # Boucle / bague
    photo_url = Column(Text, nullable=True)
    
    breed_id = Column(Integer, ForeignKey("breeds.id"), nullable=False)
    sex = Column(String(10), nullable=False)  # male / female
    birth_date = Column(Date, nullable=True)
    estimated_age_months = Column(Integer, nullable=True)
    
    origin = Column(String(50), default="birth", nullable=False)  # birth, purchase, gift, other
    entry_date = Column(Date, default=date.today, nullable=False)
    seller_info = Column(String(255), nullable=True)
    purchase_price_cfa = Column(Float, nullable=True)
    
    status = Column(String(50), default="active", nullable=False)  # active, sold, deceased, transferred
    current_sector_id = Column(Integer, ForeignKey("sectors.id"), nullable=True)
    
    current_weight_kg = Column(Float, nullable=True)
    body_condition = Column(String(50), default="normal", nullable=False)  # thin, normal, fat
    reproduction_status = Column(String(50), default="not_pregnant", nullable=False)  # not_pregnant, suspected, confirmed, lactating, resting
    
    mother_id = Column(String(50), ForeignKey("animals.id"), nullable=True)
    father_id = Column(String(50), ForeignKey("animals.id"), nullable=True)
    
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=utc_now, nullable=False)
    updated_at = Column(DateTime, default=utc_now, onupdate=utc_now, nullable=False)

    # Integrity constraint to prevent self-parentage
    __table_args__ = (
        CheckConstraint("mother_id != id", name="check_mother_not_self"),
        CheckConstraint("father_id != id", name="check_father_not_self"),
    )

    # Relationships
    breed = relationship("Breed", lazy="joined")
    current_sector = relationship("Sector", lazy="joined")
    mother = relationship("Animal", remote_side=[id], foreign_keys=[mother_id], backref="maternal_offspring")
    father = relationship("Animal", remote_side=[id], foreign_keys=[father_id], backref="paternal_offspring")
    
    movements = relationship("AnimalMovement", back_populates="animal", cascade="all, delete-orphan", order_by="desc(AnimalMovement.movement_date)")
    weight_records = relationship("WeightRecord", back_populates="animal", cascade="all, delete-orphan", order_by="desc(WeightRecord.recorded_at)")
    body_condition_records = relationship("BodyConditionRecord", back_populates="animal", cascade="all, delete-orphan", order_by="desc(BodyConditionRecord.recorded_at)")


class AnimalMovement(Base):
    __tablename__ = "animal_movements"

    id = Column(Integer, primary_key=True, index=True)
    animal_id = Column(String(50), ForeignKey("animals.id"), nullable=False, index=True)
    from_sector_id = Column(Integer, ForeignKey("sectors.id"), nullable=True)
    to_sector_id = Column(Integer, ForeignKey("sectors.id"), nullable=False)
    movement_date = Column(DateTime, default=utc_now, nullable=False)
    moved_by_user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    reason = Column(Text, nullable=True)

    animal = relationship("Animal", back_populates="movements")
    from_sector = relationship("Sector", foreign_keys=[from_sector_id])
    to_sector = relationship("Sector", foreign_keys=[to_sector_id])
    moved_by = relationship("User")


class WeightRecord(Base):
    __tablename__ = "weight_records"

    id = Column(Integer, primary_key=True, index=True)
    animal_id = Column(String(50), ForeignKey("animals.id"), nullable=False, index=True)
    weight_kg = Column(Float, nullable=False)
    recorded_at = Column(DateTime, default=utc_now, nullable=False)
    recorded_by_user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    notes = Column(Text, nullable=True)

    animal = relationship("Animal", back_populates="weight_records")
    recorded_by = relationship("User")


class BodyConditionRecord(Base):
    __tablename__ = "body_condition_records"

    id = Column(Integer, primary_key=True, index=True)
    animal_id = Column(String(50), ForeignKey("animals.id"), nullable=False, index=True)
    condition = Column(String(50), nullable=False)  # thin, normal, fat
    recorded_at = Column(DateTime, default=utc_now, nullable=False)
    recorded_by_user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    notes = Column(Text, nullable=True)

    animal = relationship("Animal", back_populates="body_condition_records")
    recorded_by = relationship("User")
