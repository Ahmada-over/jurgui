from typing import Optional, List
from datetime import date, datetime
from pydantic import BaseModel, ConfigDict


class FeedProductBase(BaseModel):
    name: str
    category: str  # forage, concentrate, fanes, mineral, supplement
    unit: str = "kg"  # kg, sac, botte, bloc
    supplier: Optional[str] = None
    unit_price_cfa: float = 0.0
    current_stock: float = 0.0
    min_stock_threshold: float = 10.0
    expiration_date: Optional[date] = None
    storage_conditions: Optional[str] = None
    notes: Optional[str] = None


class FeedProductCreate(FeedProductBase):
    pass


class FeedProductUpdate(BaseModel):
    name: Optional[str] = None
    category: Optional[str] = None
    unit: Optional[str] = None
    supplier: Optional[str] = None
    unit_price_cfa: Optional[float] = None
    min_stock_threshold: Optional[float] = None
    expiration_date: Optional[date] = None
    storage_conditions: Optional[str] = None
    notes: Optional[str] = None


class FeedProductOut(FeedProductBase):
    id: int
    created_at: datetime
    is_low_stock: bool = False

    model_config = ConfigDict(from_attributes=True)


class InventoryMovementCreate(BaseModel):
    feed_product_id: int
    movement_type: str  # in_purchase, out_feeding, out_health, out_loss, out_spoilage, adjustment, transfer
    quantity: float
    unit: str = "kg"
    unit_price_cfa: Optional[float] = 0.0
    supplier: Optional[str] = None
    batch_number: Optional[str] = None
    expiry_date: Optional[date] = None
    reason: Optional[str] = None


class InventoryMovementOut(BaseModel):
    id: int
    feed_product_id: int
    movement_type: str
    quantity: float
    unit: str
    unit_price_cfa: Optional[float] = 0.0
    total_price_cfa: Optional[float] = 0.0
    supplier: Optional[str] = None
    batch_number: Optional[str] = None
    expiry_date: Optional[date] = None
    reason: Optional[str] = None
    user_id: int
    recorded_at: datetime

    model_config = ConfigDict(from_attributes=True)


class RationItemCreate(BaseModel):
    feed_product_id: int
    quantity: float
    unit: str = "kg"
    feeding_frequency: str = "daily"


class RationItemOut(RationItemCreate):
    id: int
    ration_id: int

    model_config = ConfigDict(from_attributes=True)


class FeedRationCreate(BaseModel):
    target_type: str = "group"  # group, animal, sector
    target_id: str
    title: str
    date_applied: Optional[date] = None
    instructions: Optional[str] = None
    items: List[RationItemCreate] = []


class FeedRationOut(BaseModel):
    id: int
    target_type: str
    target_id: str
    title: str
    date_applied: date
    instructions: Optional[str] = None
    status: str
    created_by_user_id: int
    created_at: datetime
    items: List[RationItemOut] = []

    model_config = ConfigDict(from_attributes=True)
