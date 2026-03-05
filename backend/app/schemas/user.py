from pydantic import BaseModel, EmailStr
from datetime import datetime
from typing import Optional, List

# User schemas
class UserBase(BaseModel):
    email: EmailStr
    username: str

class UserCreate(UserBase):
    password: str

class UserUpdate(BaseModel):
    email: Optional[str] = None
    username: Optional[str] = None
    password: Optional[str] = None

class UserResponse(UserBase):
    id: int
    is_active: bool
    created_at: datetime
    
    class Config:
        from_attributes = True

# Authentication
class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"

class LoginRequest(BaseModel):
    email: str
    password: str

# User Profile/Onboarding
class UserProfileBase(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    date_of_birth: Optional[datetime] = None
    sex: Optional[str] = None
    height_cm: Optional[float] = None
    current_weight_kg: Optional[float] = None
    goal_weight_kg: Optional[float] = None
    goal_timeline_weeks: Optional[int] = None
    preferred_pace: Optional[str] = None
    activity_level: Optional[str] = None
    sleep_hours: Optional[float] = None
    stress_level: Optional[str] = None
    dietary_preferences: Optional[str] = None
    allergies: Optional[str] = None
    cultural_foods: Optional[str] = None
    is_pregnant: bool = False
    dietary_restrictions: Optional[str] = None
    motivation_why: Optional[str] = None
    preferred_coaching_style: Optional[str] = None

class UserProfileCreate(UserProfileBase):
    pass

class UserProfileUpdate(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    height_cm: Optional[float] = None
    current_weight_kg: Optional[float] = None
    goal_weight_kg: Optional[float] = None
    activity_level: Optional[str] = None
    sleep_hours: Optional[float] = None
    stress_level: Optional[str] = None

class UserProfileResponse(UserProfileBase):
    id: int
    user_id: int
    tdee: Optional[float] = None
    calorie_target: Optional[float] = None
    onboarding_completed: bool
    updated_at: datetime
    
    class Config:
        from_attributes = True

# Food Log
class FoodLogBase(BaseModel):
    food_name: str
    calories: float
    protein_g: Optional[float] = None
    carbs_g: Optional[float] = None
    fat_g: Optional[float] = None
    fiber_g: Optional[float] = None
    portion_size: Optional[str] = None
    quantity: Optional[float] = None
    unit: Optional[str] = None
    meal_type: Optional[str] = None
    notes: Optional[str] = None

class FoodLogCreate(FoodLogBase):
    image_url: Optional[str] = None
    source: Optional[str] = "manual"

class FoodLogResponse(FoodLogBase):
    id: int
    user_id: int
    logged_at: datetime
    ai_confidence: Optional[float] = None
    is_custom: bool
    source: Optional[str]
    
    class Config:
        from_attributes = True

# Weight Entry
class WeightEntryBase(BaseModel):
    weight_kg: float
    body_fat_percent: Optional[float] = None
    waist_cm: Optional[float] = None
    hips_cm: Optional[float] = None
    chest_cm: Optional[float] = None
    notes: Optional[str] = None

class WeightEntryCreate(WeightEntryBase):
    pass

class WeightEntryResponse(WeightEntryBase):
    id: int
    user_id: int
    recorded_at: datetime
    
    class Config:
        from_attributes = True

# Activity
class ActivityBase(BaseModel):
    activity_name: str
    activity_type: Optional[str] = None
    duration_minutes: int
    intensity: Optional[str] = None
    calories_burned: Optional[float] = None
    distance_km: Optional[float] = None
    steps: Optional[int] = None
    heart_rate_avg: Optional[int] = None
    notes: Optional[str] = None

class ActivityCreate(ActivityBase):
    source: Optional[str] = "manual"

class ActivityResponse(ActivityBase):
    id: int
    user_id: int
    logged_at: datetime
    source: Optional[str]
    
    class Config:
        from_attributes = True

# Diary Entry
class DiaryEntryBase(BaseModel):
    mood: Optional[str] = None
    energy_level: Optional[int] = None
    hunger_level: Optional[int] = None
    sleep_hours: Optional[float] = None
    sleep_quality: Optional[str] = None
    wins: Optional[str] = None
    challenges: Optional[str] = None
    proud_of: Optional[str] = None
    notes: Optional[str] = None

class DiaryEntryCreate(DiaryEntryBase):
    pass

class DiaryEntryResponse(DiaryEntryBase):
    id: int
    user_id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

# Dashboard summary
class DashboardStatsResponse(BaseModel):
    today_calories: float
    today_goal: float
    today_water: int  # in ml
    steps_today: int
    weight_kg: Optional[float]
    weight_goal_kg: Optional[float]
    progress_percent: float
    
    class Config:
        from_attributes = True
