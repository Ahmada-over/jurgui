from typing import Optional
from datetime import datetime
from pydantic import BaseModel, ConfigDict


class TaskCreate(BaseModel):
    title: str
    description: Optional[str] = None
    category: str = "general"
    due_date: datetime
    priority: str = "medium"
    animal_id: Optional[str] = None
    sector_id: Optional[int] = None
    assigned_user_id: Optional[int] = None


class TaskUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    due_date: Optional[datetime] = None
    priority: Optional[str] = None
    status: Optional[str] = None
    assigned_user_id: Optional[int] = None


class TaskOut(TaskCreate):
    id: int
    status: str
    created_by_user_id: int
    completed_at: Optional[datetime] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class NotificationOut(BaseModel):
    id: int
    title: str
    message: str
    category: str
    priority: str
    status: str
    target_user_id: Optional[int] = None
    related_entity_type: Optional[str] = None
    related_entity_id: Optional[str] = None
    scheduled_for: Optional[datetime] = None
    sent_at: datetime

    model_config = ConfigDict(from_attributes=True)
