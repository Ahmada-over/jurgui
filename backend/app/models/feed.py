from datetime import datetime, timezone, date
from sqlalchemy import Column, Integer, String, Text, Float, Date, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base


class FeedProduct(Base):
    __tablename__ = "feed_products"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), unique=True, index=True, nullable=False)
    category = Column(String(50), nullable=False)  # forage, concentrate, fanes, mineral, supplement
    unit = Column(String(20), default="kg", nullable=False)  # kg, sac, botte, bloc
    supplier = Column(String(150), nullable=True)
    unit_price_cfa = Column(Float, default=0.0, nullable=False)
    current_stock = Column(Float, default=0.0, nullable=False)
    min_stock_threshold = Column(Float, default=10.0, nullable=False)
    expiration_date = Column(Date, nullable=True)
    storage_conditions = Column(String(255), nullable=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    inventory_movements = relationship("InventoryMovement", back_populates="product", cascade="all, delete-orphan")


class FeedRation(Base):
    __tablename__ = "feed_rations"

    id = Column(Integer, primary_key=True, index=True)
    target_type = Column(String(50), default="group", nullable=False)  # group, animal, sector
    target_id = Column(String(50), nullable=False)  # Sector name/ID or Animal ID or Lot name
    title = Column(String(150), nullable=False)
    date_applied = Column(Date, default=date.today, nullable=False)
    instructions = Column(Text, nullable=True)
    status = Column(String(50), default="to_prepare", nullable=False)  # to_prepare, distributed, cancelled
    created_by_user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    created_by = relationship("User")
    items = relationship("RationItem", back_populates="ration", cascade="all, delete-orphan")


class RationItem(Base):
    __tablename__ = "ration_items"

    id = Column(Integer, primary_key=True, index=True)
    ration_id = Column(Integer, ForeignKey("feed_rations.id"), nullable=False, index=True)
    feed_product_id = Column(Integer, ForeignKey("feed_products.id"), nullable=False)
    quantity = Column(Float, nullable=False)
    unit = Column(String(20), default="kg", nullable=False)
    feeding_frequency = Column(String(50), default="daily", nullable=False)  # daily, twice_daily, morning, evening

    ration = relationship("FeedRation", back_populates="items")
    product = relationship("FeedProduct")


class FeedingRecord(Base):
    __tablename__ = "feeding_records"

    id = Column(Integer, primary_key=True, index=True)
    ration_id = Column(Integer, ForeignKey("feed_rations.id"), nullable=True)
    feed_product_id = Column(Integer, ForeignKey("feed_products.id"), nullable=False)
    target_type = Column(String(50), default="group", nullable=False)
    target_id = Column(String(50), nullable=False)
    quantity_planned = Column(Float, nullable=True)
    quantity_served = Column(Float, nullable=False)
    unit = Column(String(20), default="kg", nullable=False)
    recorded_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    notes = Column(Text, nullable=True)

    ration = relationship("FeedRation")
    product = relationship("FeedProduct")
    user = relationship("User")


class InventoryMovement(Base):
    __tablename__ = "inventory_movements"

    id = Column(Integer, primary_key=True, index=True)
    feed_product_id = Column(Integer, ForeignKey("feed_products.id"), nullable=False, index=True)
    movement_type = Column(String(50), nullable=False)  # in_purchase, out_feeding, out_health, out_loss, out_spoilage, adjustment, transfer
    quantity = Column(Float, nullable=False)
    unit = Column(String(20), default="kg", nullable=False)
    unit_price_cfa = Column(Float, default=0.0, nullable=True)
    total_price_cfa = Column(Float, default=0.0, nullable=True)
    supplier = Column(String(150), nullable=True)
    batch_number = Column(String(100), nullable=True)
    expiry_date = Column(Date, nullable=True)
    reason = Column(Text, nullable=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    recorded_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    product = relationship("FeedProduct", back_populates="inventory_movements")
    user = relationship("User")
