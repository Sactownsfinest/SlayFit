"""
User profile routes
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.user import User
from app.schemas.user import UserResponse, UserProfileResponse, UserProfileCreate, UserProfileUpdate
from app.services.user_service import UserService, UserProfileService
from app.core.security import decode_token
from fastapi.security import HTTPBearer, HTTPAuthCredentials

router = APIRouter()
security = HTTPBearer()

def get_current_user(credentials: HTTPAuthCredentials = Depends(security), db: Session = Depends(get_db)) -> User:
    """Get current authenticated user"""
    token = credentials.credentials
    token_data = decode_token(token)
    
    if token_data is None or token_data.user_id is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials",
        )
    
    user = UserService.get_user_by_id(db, token_data.user_id)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )
    
    return user

@router.get("/profile", response_model=UserProfileResponse)
def get_profile(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Get user profile"""
    profile = UserProfileService.get_profile(db, current_user.id)
    
    if not profile:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Profile not found",
        )
    
    return profile

@router.put("/profile", response_model=UserProfileResponse)
def update_profile(
    profile_update: UserProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update user profile"""
    profile = UserProfileService.create_or_update_profile(
        db, current_user.id, profile_update
    )
    return profile

@router.post("/profile/onboarding-complete")
def complete_onboarding(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Mark onboarding as complete"""
    profile = UserProfileService.get_profile(db, current_user.id)
    
    if profile:
        profile.onboarding_completed = True
        db.commit()
    
    return {"status": "onboarding_completed"}
