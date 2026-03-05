"""
Food logging routes
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime
from app.core.database import get_db
from app.models.user import User, FoodLog
from app.schemas.user import FoodLogCreate, FoodLogResponse
from app.services.user_service import UserService, FoodLogService
from app.api.users import get_current_user

router = APIRouter()

@router.post("/logs", response_model=FoodLogResponse, status_code=201)
def create_food_log(
    food_log: FoodLogCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create a food log entry"""
    db_food_log = FoodLogService.create_food_log(db, current_user.id, food_log)
    return db_food_log

@router.get("/logs/today", response_model=list[FoodLogResponse])
def get_food_logs_today(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get today's food logs"""
    return FoodLogService.get_user_food_logs_today(db, current_user.id)

@router.get("/logs", response_model=list[FoodLogResponse])
def get_food_logs(
    start_date: datetime,
    end_date: datetime,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get food logs in date range"""
    return FoodLogService.get_user_food_logs_range(db, current_user.id, start_date, end_date)

@router.delete("/logs/{food_log_id}")
def delete_food_log(
    food_log_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Delete a food log entry"""
    if not FoodLogService.delete_food_log(db, food_log_id, current_user.id):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Food log not found",
        )
    return {"status": "deleted"}

@router.get("/search")
def search_food(q: str):
    """Search food database"""
    # TODO: Integrate with Edamam or Nutritionix API
    return {"query": q, "results": []}

@router.post("/estimate-calories")
def estimate_calories(image_url: str):
    """Estimate calories from image using AI/ML"""
    # TODO: Integrate with ML model for food recognition
    return {"calories": 0, "confidence": 0.0}
