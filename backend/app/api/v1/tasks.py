from typing import List, Optional
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.core.database import get_db
from app.models.task_notification import Task, Notification
from app.models.user import User
from app.schemas.task import TaskCreate, TaskOut, TaskUpdate, NotificationOut
from app.api.deps import get_current_user

router = APIRouter(prefix="/tasks", tags=["Tâches & Notifications"])


@router.get("", response_model=List[TaskOut])
async def list_tasks(
    category: Optional[str] = None,
    status_filter: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = select(Task).order_by(Task.due_date.asc())
    if category:
        query = query.where(Task.category == category)
    if status_filter:
        query = query.where(Task.status == status_filter)
    res = await db.execute(query)
    return [TaskOut.model_validate(t) for t in res.scalars().all()]


@router.post("", response_model=TaskOut, status_code=status.HTTP_201_CREATED)
async def create_task(
    task_in: TaskCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    task = Task(
        title=task_in.title,
        description=task_in.description,
        category=task_in.category,
        due_date=task_in.due_date,
        priority=task_in.priority,
        status="pending",
        animal_id=task_in.animal_id,
        sector_id=task_in.sector_id,
        assigned_user_id=task_in.assigned_user_id or current_user.id,
        created_by_user_id=current_user.id
    )
    db.add(task)
    await db.commit()
    await db.refresh(task)
    return TaskOut.model_validate(task)


@router.put("/{task_id}", response_model=TaskOut)
async def update_task(
    task_id: int,
    task_in: TaskUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    res = await db.execute(select(Task).where(Task.id == task_id))
    task = res.scalars().first()
    if not task:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Tâche introuvable")

    if task_in.title is not None:
        task.title = task_in.title
    if task_in.description is not None:
        task.description = task_in.description
    if task_in.due_date is not None:
        task.due_date = task_in.due_date
    if task_in.priority is not None:
        task.priority = task_in.priority
    if task_in.status is not None:
        task.status = task_in.status
        if task_in.status == "completed":
            task.completed_at = datetime.now(timezone.utc).replace(tzinfo=None)
    if task_in.assigned_user_id is not None:
        task.assigned_user_id = task_in.assigned_user_id

    await db.commit()
    await db.refresh(task)
    return TaskOut.model_validate(task)


@router.get("/notifications", response_model=List[NotificationOut])
async def list_notifications(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = (
        select(Notification)
        .where(
            (Notification.target_user_id == current_user.id) | (Notification.target_user_id.is_(None))
        )
        .order_by(Notification.sent_at.desc())
        .limit(50)
    )
    res = await db.execute(query)
    return [NotificationOut.model_validate(n) for n in res.scalars().all()]
