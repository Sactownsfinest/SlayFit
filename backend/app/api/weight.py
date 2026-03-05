"""
Weight tracking routes
"""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.user import User
from app.schemas.user import WeightEntryCreate, WeightEntryResponse
from app.services.user_service import UserService, WeightTrackingService
from app.api.users import get_current_user

router = APIRouter()

@router.post("/entries", response_model=WeightEntryResponse, status_code=201)
def record_weight(
    entry: WeightEntryCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Record a weight entry"""
    return WeightTrackingService.record_weight(db, current_user.id, entry)

@router.get("/entries", response_model=list[WeightEntryResponse])
def get_weight_history(
    days: int = 90,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get weight history"""
    return WeightTrackingService.get_user_weight_entries(db, current_user.id, days)

@router.get("/latest", response_model=WeightEntryResponse)
def get_latest_weight(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get latest weight entry"""
    latest = WeightTrackingService.get_latest_weight(db, current_user.id)
    return latest or {}

@router.get("/trend")
def get_weight_trend(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get weight trend data"""
    # TODO: Calculate trend and moving average
    entries = WeightTrackingService.get_user_weight_entries(db, current_user.id, 90)
    return {
        "entries": entries,
        "trend": "stable",
        "moving_average_7d": 0.0,
    }
