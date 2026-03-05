"""
Diary routes
"""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.user import User
from app.schemas.user import DiaryEntryCreate, DiaryEntryResponse
from app.services.user_service import UserService, DiaryService
from app.api.users import get_current_user

router = APIRouter()

@router.post("", response_model=DiaryEntryResponse, status_code=201)
def create_diary_entry(
    entry: DiaryEntryCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create a diary entry"""
    return DiaryService.create_diary_entry(db, current_user.id, entry)

@router.get("/today", response_model=DiaryEntryResponse)
def get_diary_today(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get today's diary entry"""
    entry = DiaryService.get_user_diary_today(db, current_user.id)
    return entry or {}
