from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey, Boolean
from sqlalchemy.orm import relationship
from backend.app.core.database import Base


class Task(Base):
    __tablename__ = "tasks"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(200), nullable=False)
    description = Column(Text, nullable=True)
    category = Column(String(50), nullable=False)  # reproduction, nutrition, health, hygiene, admin
    due_date = Column(DateTime, nullable=False)
    priority = Column(String(20), default="medium", nullable=False)  # low, medium, high, critical
    status = Column(String(30), default="pending", nullable=False)  # pending, in_progress, completed, deferred, cancelled
    
    animal_id = Column(String(50), ForeignKey("animals.id"), nullable=True)
    sector_id = Column(Integer, ForeignKey("sectors.id"), nullable=True)
    assigned_user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    created_by_user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    completed_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    animal = relationship("Animal")
    sector = relationship("Sector")
    assigned_user = relationship("User", foreign_keys=[assigned_user_id])
    created_by = relationship("User", foreign_keys=[created_by_user_id])


class Notification(Base):
    __tablename__ = "notifications"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(200), nullable=False)
    message = Column(Text, nullable=False)
    category = Column(String(50), nullable=False)  # reproduction, health, nutrition, stock, hygiene, system
    priority = Column(String(20), default="normal", nullable=False)  # low, normal, urgent
    status = Column(String(20), default="unread", nullable=False)  # unread, read, dismissed
    
    target_user_id = Column(Integer, ForeignKey("users.id"), nullable=True)  # null = broadcast to all staff
    related_entity_type = Column(String(50), nullable=True)  # animal, pregnancy, feed_product, task
    related_entity_id = Column(String(50), nullable=True)
    
    scheduled_for = Column(DateTime, nullable=True)
    sent_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    is_fcm_sent = Column(Boolean, default=False, nullable=False)

    target_user = relationship("User")
