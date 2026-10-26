from sqlalchemy import Column, Integer, String, Text, DateTime
from app.core.database import Base, utc_now


class Sector(Base):
    __tablename__ = "sectors"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), unique=True, index=True, nullable=False)
    description = Column(Text, nullable=True)
    estimated_capacity = Column(Integer, default=0, nullable=False)
    status = Column(String(50), default="active", nullable=False)  # active, maintenance, quarantine
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=utc_now, nullable=False)
