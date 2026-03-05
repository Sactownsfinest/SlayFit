"""
Activity routes
"""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.user import User
from app.schemas.user import ActivityCreate, ActivityResponse
from app.services.user_service import UserService, ActivityService
from app.api.users import get_current_user

router = APIRouter()

@router.post("", response_model=ActivityResponse, status_code=201)
def create_activity(
    activity: ActivityCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Log a new activity"""
    return ActivityService.create_activity(db, current_user.id, activity)

@router.get("/today", response_model=list[ActivityResponse])
def get_activities_today(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get today's activities"""
    return ActivityService.get_user_activities_today(db, current_user.id)
