from typing import List, Optional
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from app.core.database import get_db
from app.models.finance import Expense, Revenue
from app.models.animal import Animal
from app.models.user import User
from app.schemas.finance import ExpenseCreate, ExpenseOut, RevenueCreate, RevenueOut, FinancialSummaryOut
from app.api.deps import get_current_user, get_current_admin

router = APIRouter(prefix="/finances", tags=["Finances (FCFA)"])


@router.post("/expenses", response_model=ExpenseOut, status_code=status.HTTP_201_CREATED)
async def create_expense(
    exp_in: ExpenseCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    expense = Expense(
        amount_cfa=exp_in.amount_cfa,
        expense_date=exp_in.expense_date or datetime.now(timezone.utc).date(),
        category=exp_in.category,
        label=exp_in.label,
        receipt_url=exp_in.receipt_url,
        notes=exp_in.notes,
        user_id=current_user.id
    )
    db.add(expense)
    await db.commit()
    await db.refresh(expense)
    return ExpenseOut.model_validate(expense)


@router.get("/expenses", response_model=List[ExpenseOut])
async def list_expenses(
    category: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = select(Expense).order_by(Expense.expense_date.desc())
    if category:
        query = query.where(Expense.category == category)
    res = await db.execute(query)
    return [ExpenseOut.model_validate(e) for e in res.scalars().all()]


@router.post("/revenues", response_model=RevenueOut, status_code=status.HTTP_201_CREATED)
async def create_revenue(
    rev_in: RevenueCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # If this revenue is from an animal sale, update the animal's status to 'sold'
    if rev_in.animal_id:
        anim_res = await db.execute(select(Animal).where(Animal.id == rev_in.animal_id))
        animal = anim_res.scalars().first()
        if animal:
            animal.status = "sold"

    revenue = Revenue(
        amount_cfa=rev_in.amount_cfa,
        revenue_date=rev_in.revenue_date or datetime.now(timezone.utc).date(),
        category=rev_in.category,
        animal_id=rev_in.animal_id,
        label=rev_in.label,
        buyer=rev_in.buyer,
        receipt_url=rev_in.receipt_url,
        notes=rev_in.notes,
        user_id=current_user.id
    )
    db.add(revenue)
    await db.commit()
    await db.refresh(revenue)
    return RevenueOut.model_validate(revenue)


@router.get("/revenues", response_model=List[RevenueOut])
async def list_revenues(
    category: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = select(Revenue).order_by(Revenue.revenue_date.desc())
    if category:
        query = query.where(Revenue.category == category)
    res = await db.execute(query)
    return [RevenueOut.model_validate(r) for r in res.scalars().all()]


@router.get("/summary", response_model=FinancialSummaryOut)
async def get_financial_summary(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    tot_exp_res = await db.execute(select(func.sum(Expense.amount_cfa)))
    total_expenses = tot_exp_res.scalar() or 0.0

    tot_rev_res = await db.execute(select(func.sum(Revenue.amount_cfa)))
    total_revenues = tot_rev_res.scalar() or 0.0

    feed_exp_res = await db.execute(select(func.sum(Expense.amount_cfa)).where(Expense.category == "feed"))
    feed_expenses = feed_exp_res.scalar() or 0.0

    vet_exp_res = await db.execute(
        select(func.sum(Expense.amount_cfa)).where(Expense.category.in_(["veterinary_products", "veterinary_fees"]))
    )
    vet_expenses = vet_exp_res.scalar() or 0.0

    anim_sales_res = await db.execute(
        select(func.sum(Revenue.amount_cfa)).where(Revenue.category.in_(["animal_sale", "lamb_sale"]))
    )
    animal_sales = anim_sales_res.scalar() or 0.0

    return FinancialSummaryOut(
        total_expenses_cfa=total_expenses,
        total_revenues_cfa=total_revenues,
        net_balance_cfa=total_revenues - total_expenses,
        feed_expenses_cfa=feed_expenses,
        vet_expenses_cfa=vet_expenses,
        animal_sales_cfa=animal_sales
    )
