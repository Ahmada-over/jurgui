from datetime import date
from sqlalchemy import Column, Integer, String, Text, Float, Date, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base, utc_now


class Expense(Base):
    __tablename__ = "expenses"

    id = Column(Integer, primary_key=True, index=True)
    amount_cfa = Column(Float, nullable=False)
    expense_date = Column(Date, default=date.today, nullable=False)
    category = Column(String(50), nullable=False)  # animal_purchase, feed, veterinary_products, veterinary_fees, hygiene, equipment, transport, labor, other
    label = Column(String(200), nullable=False)
    receipt_url = Column(String(500), nullable=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=utc_now, nullable=False)

    user = relationship("User")


class Revenue(Base):
    __tablename__ = "revenues"

    id = Column(Integer, primary_key=True, index=True)
    amount_cfa = Column(Float, nullable=False)
    revenue_date = Column(Date, default=date.today, nullable=False)
    category = Column(String(50), nullable=False)  # animal_sale, lamb_sale, other_products, other_revenue
    animal_id = Column(String(50), ForeignKey("animals.id"), nullable=True)
    label = Column(String(200), nullable=False)
    buyer = Column(String(150), nullable=True)
    receipt_url = Column(String(500), nullable=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=utc_now, nullable=False)

    animal = relationship("Animal")
    user = relationship("User")
