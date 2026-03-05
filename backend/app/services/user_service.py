"""
Database service layer for user operations
"""

from sqlalchemy.orm import Session
from sqlalchemy import desc
from app.models.user import User, UserProfile, FoodLog, WeightEntry, Activity, DiaryEntry
from app.schemas.user import (
    UserCreate, UserProfileCreate, UserProfileUpdate,
    FoodLogCreate, WeightEntryCreate, ActivityCreate, DiaryEntryCreate
)
from app.core.security import get_password_hash
from datetime import datetime, timedelta
from typing import Optional, List

class UserService:
    """Service for user management"""
    
    @staticmethod
    def create_user(db: Session, user: UserCreate) -> User:
        """Create a new user"""
        hashed_password = get_password_hash(user.password)
        db_user = User(
            email=user.email,
            username=user.username,
            hashed_password=hashed_password
        )
        db.add(db_user)
        db.commit()
        db.refresh(db_user)
        return db_user
    
    @staticmethod
    def get_user_by_email(db: Session, email: str) -> Optional[User]:
        """Get user by email"""
        return db.query(User).filter(User.email == email).first()
    
    @staticmethod
    def get_user_by_id(db: Session, user_id: int) -> Optional[User]:
        """Get user by ID"""
        return db.query(User).filter(User.id == user_id).first()

class UserProfileService:
    """Service for user profile/onboarding"""
    
    @staticmethod
    def create_or_update_profile(
        db: Session, 
        user_id: int, 
        profile_data: UserProfileCreate | UserProfileUpdate
    ) -> UserProfile:
        """Create or update user profile"""
        profile = db.query(UserProfile).filter(UserProfile.user_id == user_id).first()
        
        if profile:
            for field, value in profile_data.dict(exclude_unset=True).items():
                setattr(profile, field, value)
        else:
            profile = UserProfile(user_id=user_id, **profile_data.dict(exclude_unset=True))
            db.add(profile)
        
        profile.updated_at = datetime.utcnow()
        db.commit()
        db.refresh(profile)
        return profile
    
    @staticmethod
    def get_profile(db: Session, user_id: int) -> Optional[UserProfile]:
        """Get user profile"""
        return db.query(UserProfile).filter(UserProfile.user_id == user_id).first()

class FoodLogService:
    """Service for food logging"""
    
    @staticmethod
    def create_food_log(
        db: Session,
        user_id: int,
        food_log: FoodLogCreate
    ) -> FoodLog:
        """Create a new food log entry"""
        db_food_log = FoodLog(
            user_id=user_id,
            **food_log.dict()
        )
        db.add(db_food_log)
        db.commit()
        db.refresh(db_food_log)
        return db_food_log
    
    @staticmethod
    def get_user_food_logs_today(db: Session, user_id: int) -> List[FoodLog]:
        """Get user's food logs for today"""
        today = datetime.utcnow().date()
        return db.query(FoodLog).filter(
            FoodLog.user_id == user_id,
            FoodLog.logged_at >= datetime.combine(today, datetime.min.time()),
            FoodLog.logged_at < datetime.combine(today + timedelta(days=1), datetime.min.time())
        ).all()
    
    @staticmethod
    def get_user_food_logs_range(
        db: Session,
        user_id: int,
        start_date: datetime,
        end_date: datetime
    ) -> List[FoodLog]:
        """Get user's food logs in a date range"""
        return db.query(FoodLog).filter(
            FoodLog.user_id == user_id,
            FoodLog.logged_at >= start_date,
            FoodLog.logged_at <= end_date
        ).all()
    
    @staticmethod
    def delete_food_log(db: Session, food_log_id: int, user_id: int) -> bool:
        """Delete a food log entry"""
        food_log = db.query(FoodLog).filter(
            FoodLog.id == food_log_id,
            FoodLog.user_id == user_id
        ).first()
        
        if food_log:
            db.delete(food_log)
            db.commit()
            return True
        return False

class WeightTrackingService:
    """Service for weight tracking"""
    
    @staticmethod
    def record_weight(
        db: Session,
        user_id: int,
        weight_entry: WeightEntryCreate
    ) -> WeightEntry:
        """Record a weight entry"""
        db_weight = WeightEntry(
            user_id=user_id,
            **weight_entry.dict()
        )
        db.add(db_weight)
        db.commit()
        db.refresh(db_weight)
        return db_weight
    
    @staticmethod
    def get_user_weight_entries(
        db: Session,
        user_id: int,
        days: int = 90
    ) -> List[WeightEntry]:
        """Get user's recent weight entries"""
        start_date = datetime.utcnow() - timedelta(days=days)
        return db.query(WeightEntry).filter(
            WeightEntry.user_id == user_id,
            WeightEntry.recorded_at >= start_date
        ).order_by(WeightEntry.recorded_at).all()
    
    @staticmethod
    def get_latest_weight(db: Session, user_id: int) -> Optional[WeightEntry]:
        """Get user's latest weight entry"""
        return db.query(WeightEntry).filter(
            WeightEntry.user_id == user_id
        ).order_by(desc(WeightEntry.recorded_at)).first()

class ActivityService:
    """Service for activity tracking"""
    
    @staticmethod
    def create_activity(
        db: Session,
        user_id: int,
        activity: ActivityCreate
    ) -> Activity:
        """Create a new activity entry"""
        db_activity = Activity(
            user_id=user_id,
            **activity.dict()
        )
        db.add(db_activity)
        db.commit()
        db.refresh(db_activity)
        return db_activity
    
    @staticmethod
    def get_user_activities_today(db: Session, user_id: int) -> List[Activity]:
        """Get user's activities for today"""
        today = datetime.utcnow().date()
        return db.query(Activity).filter(
            Activity.user_id == user_id,
            Activity.logged_at >= datetime.combine(today, datetime.min.time()),
            Activity.logged_at < datetime.combine(today + timedelta(days=1), datetime.min.time())
        ).all()

class DiaryService:
    """Service for diary entries"""
    
    @staticmethod
    def create_diary_entry(
        db: Session,
        user_id: int,
        diary: DiaryEntryCreate
    ) -> DiaryEntry:
        """Create a new diary entry"""
        db_diary = DiaryEntry(
            user_id=user_id,
            **diary.dict()
        )
        db.add(db_diary)
        db.commit()
        db.refresh(db_diary)
        return db_diary
    
    @staticmethod
    def get_user_diary_today(db: Session, user_id: int) -> Optional[DiaryEntry]:
        """Get today's diary entry"""
        today = datetime.utcnow().date()
        return db.query(DiaryEntry).filter(
            DiaryEntry.user_id == user_id,
            DiaryEntry.created_at >= datetime.combine(today, datetime.min.time()),
            DiaryEntry.created_at < datetime.combine(today + timedelta(days=1), datetime.min.time())
        ).first()
