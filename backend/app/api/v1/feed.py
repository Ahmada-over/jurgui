from typing import List
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from backend.app.core.database import get_db
from backend.app.models.feed import FeedProduct, FeedRation, RationItem, FeedingRecord, InventoryMovement
from backend.app.models.user import User
from backend.app.schemas.feed import (
    FeedProductCreate, FeedProductOut, FeedProductUpdate,
    InventoryMovementCreate, InventoryMovementOut,
    FeedRationCreate, FeedRationOut, RationItemOut
)
from backend.app.api.deps import get_current_user

router = APIRouter(prefix="/feed", tags=["Nutrition & Stocks"])


@router.get("/products", response_model=List[FeedProductOut])
async def list_feed_products(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = await db.execute(select(FeedProduct).order_by(FeedProduct.name))
    products = result.scalars().all()
    output = []
    for p in products:
        p_out = FeedProductOut.model_validate(p)
        p_out.is_low_stock = (p.current_stock <= p.min_stock_threshold)
        output.append(p_out)
    return output


@router.post("/products", response_model=FeedProductOut, status_code=status.HTTP_201_CREATED)
async def create_feed_product(
    prod_in: FeedProductCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    existing = await db.execute(select(FeedProduct).where(FeedProduct.name == prod_in.name.strip()))
    if existing.scalars().first():
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Le produit '{prod_in.name}' existe déjà")

    product = FeedProduct(
        name=prod_in.name.strip(),
        category=prod_in.category,
        unit=prod_in.unit,
        supplier=prod_in.supplier,
        unit_price_cfa=prod_in.unit_price_cfa,
        current_stock=prod_in.current_stock,
        min_stock_threshold=prod_in.min_stock_threshold,
        expiration_date=prod_in.expiration_date,
        storage_conditions=prod_in.storage_conditions,
        notes=prod_in.notes
    )
    db.add(product)
    await db.commit()
    await db.refresh(product)
    p_out = FeedProductOut.model_validate(product)
    p_out.is_low_stock = (product.current_stock <= product.min_stock_threshold)
    return p_out


@router.post("/movements", response_model=InventoryMovementOut, status_code=status.HTTP_201_CREATED)
async def record_stock_movement(
    mov_in: InventoryMovementCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    prod_res = await db.execute(select(FeedProduct).where(FeedProduct.id == mov_in.feed_product_id))
    product = prod_res.scalars().first()
    if not product:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Produit alimentaire introuvable")

    # If it is an exit movement, verify stock sufficiency (Rule 10 of Cahier des charges: no negative stock without authorization)
    if mov_in.movement_type.startswith("out_"):
        if product.current_stock < mov_in.quantity:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Stock insuffisant ({product.current_stock} {product.unit} disponible, {mov_in.quantity} requis)"
            )
        product.current_stock -= mov_in.quantity
    elif mov_in.movement_type == "in_purchase":
        product.current_stock += mov_in.quantity
        if mov_in.unit_price_cfa:
            product.unit_price_cfa = mov_in.unit_price_cfa
    elif mov_in.movement_type == "adjustment":
        # Direct adjustment to new quantity
        product.current_stock = mov_in.quantity

    total_price = (mov_in.unit_price_cfa or product.unit_price_cfa) * mov_in.quantity

    movement = InventoryMovement(
        feed_product_id=product.id,
        movement_type=mov_in.movement_type,
        quantity=mov_in.quantity,
        unit=mov_in.unit or product.unit,
        unit_price_cfa=mov_in.unit_price_cfa or product.unit_price_cfa,
        total_price_cfa=total_price,
        supplier=mov_in.supplier,
        batch_number=mov_in.batch_number,
        expiry_date=mov_in.expiry_date,
        reason=mov_in.reason,
        user_id=current_user.id
    )
    db.add(movement)
    await db.commit()
    await db.refresh(movement)
    return InventoryMovementOut.model_validate(movement)


@router.get("/rations", response_model=List[FeedRationOut])
async def list_rations(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = select(FeedRation).options(selectinload(FeedRation.items)).order_by(FeedRation.date_applied.desc())
    res = await db.execute(query)
    rations = res.scalars().all()
    return [FeedRationOut.model_validate(r) for r in rations]


@router.post("/rations", response_model=FeedRationOut, status_code=status.HTTP_201_CREATED)
async def create_ration(
    ration_in: FeedRationCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    ration = FeedRation(
        target_type=ration_in.target_type,
        target_id=ration_in.target_id,
        title=ration_in.title,
        date_applied=ration_in.date_applied or datetime.now(timezone.utc).date(),
        instructions=ration_in.instructions,
        status="to_prepare",
        created_by_user_id=current_user.id
    )
    db.add(ration)
    await db.flush()

    for item_in in ration_in.items:
        prod_res = await db.execute(select(FeedProduct).where(FeedProduct.id == item_in.feed_product_id))
        if not prod_res.scalars().first():
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Produit ID {item_in.feed_product_id} introuvable")
        
        item = RationItem(
            ration_id=ration.id,
            feed_product_id=item_in.feed_product_id,
            quantity=item_in.quantity,
            unit=item_in.unit,
            feeding_frequency=item_in.feeding_frequency
        )
        db.add(item)

    await db.commit()
    
    # Reload with items
    query = select(FeedRation).options(selectinload(FeedRation.items)).where(FeedRation.id == ration.id)
    res = await db.execute(query)
    return FeedRationOut.model_validate(res.scalars().first())
