from typing import Optional
from datetime import date, datetime
from pydantic import BaseModel, ConfigDict


class ExpenseCreate(BaseModel):
    amount_cfa: float
    expense_date: Optional[date] = None
    category: str  # animal_purchase, feed, veterinary_products, veterinary_fees, hygiene, equipment, transport, labor, other
    label: str
    receipt_url: Optional[str] = None
    notes: Optional[str] = None


class ExpenseOut(ExpenseCreate):
    id: int
    user_id: int
    expense_date: date
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class RevenueCreate(BaseModel):
    amount_cfa: float
    revenue_date: Optional[date] = None
    category: str  # animal_sale, lamb_sale, other_products, other_revenue
    animal_id: Optional[str] = None
    label: str
    buyer: Optional[str] = None
    receipt_url: Optional[str] = None
    notes: Optional[str] = None


class RevenueOut(RevenueCreate):
    id: int
    user_id: int
    revenue_date: date
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class FinancialSummaryOut(BaseModel):
    total_expenses_cfa: float = 0.0
    total_revenues_cfa: float = 0.0
    net_balance_cfa: float = 0.0
    feed_expenses_cfa: float = 0.0
    vet_expenses_cfa: float = 0.0
    animal_sales_cfa: float = 0.0
