from sqlalchemy import Column, Integer, String, Float, DateTime, Boolean, Text, Enum, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime
import enum
from app.core.database import Base

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    username = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    profile = relationship("UserProfile", back_populates="user", uselist=False)
    food_logs = relationship("FoodLog", back_populates="user")
    weight_entries = relationship("WeightEntry", back_populates="user")
    activities = relationship("Activity", back_populates="user")
    diary_entries = relationship("DiaryEntry", back_populates="user")
    
    def __repr__(self):
        return f"<User {self.email}>"

class UserProfile(Base):
    __tablename__ = "user_profiles"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True, index=True)
    
    # Onboarding data
    first_name = Column(String, nullable=True)
    last_name = Column(String, nullable=True)
    date_of_birth = Column(DateTime, nullable=True)
    sex = Column(String, nullable=True)  # M, F, Other
    height_cm = Column(Float, nullable=True)
    current_weight_kg = Column(Float, nullable=True)
    goal_weight_kg = Column(Float, nullable=True)
    goal_timeline_weeks = Column(Integer, nullable=True)
    preferred_pace = Column(String, nullable=True)  # slow, steady, aggressive
    
    # Lifestyle
    activity_level = Column(String, nullable=True)  # sedentary, lightly_active, moderate, very_active
    sleep_hours = Column(Float, nullable=True)
    stress_level = Column(String, nullable=True)  # low, moderate, high
    dietary_preferences = Column(String, nullable=True)  # JSON string or comma-separated
    allergies = Column(String, nullable=True)
    cultural_foods = Column(String, nullable=True)
    
    # Medical (general)
    is_pregnant = Column(Boolean, default=False)
    dietary_restrictions = Column(String, nullable=True)
    
    # Motivation
    motivation_why = Column(Text, nullable=True)
    preferred_coaching_style = Column(String, nullable=True)  # gentle, motivational, strict
    
    tdee = Column(Float, nullable=True)  # Calculated TDEE
    calorie_target = Column(Float, nullable=True)  # Daily calorie goal
    
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    onboarding_completed = Column(Boolean, default=False)
    
    # Relationships
    user = relationship("User", back_populates="profile")
    
    def __repr__(self):
        return f"<UserProfile user_id={self.user_id}>"

class FoodLog(Base):
    __tablename__ = "food_logs"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), index=True)
    logged_at = Column(DateTime, default=datetime.utcnow, index=True)
    
    # Food details
    food_name = Column(String, index=True)
    calories = Column(Float)
    protein_g = Column(Float, nullable=True)
    carbs_g = Column(Float, nullable=True)
    fat_g = Column(Float, nullable=True)
    fiber_g = Column(Float, nullable=True)
    
    # Portion
    portion_size = Column(String, nullable=True)
    quantity = Column(Float, nullable=True)
    unit = Column(String, nullable=True)  # g, ml, cup, oz, etc
    
    # AI Recognition (optional)
    image_url = Column(String, nullable=True)
    ai_confidence = Column(Float, nullable=True)  # 0-1
    
    # Meta
    meal_type = Column(String, nullable=True)  # breakfast, lunch, dinner, snack
    is_custom = Column(Boolean, default=False)
    source = Column(String, nullable=True)  # manual, barcode, ai_photo, integration
    notes = Column(Text, nullable=True)
    
    # Relationships
    user = relationship("User", back_populates="food_logs")
    
    def __repr__(self):
        return f"<FoodLog {self.food_name} {self.calories}kcal>"

class WeightEntry(Base):
    __tablename__ = "weight_entries"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), index=True)
    recorded_at = Column(DateTime, default=datetime.utcnow, index=True)
    
    weight_kg = Column(Float)
    body_fat_percent = Column(Float, nullable=True)
    
    # Measurements (optional)
    waist_cm = Column(Float, nullable=True)
    hips_cm = Column(Float, nullable=True)
    chest_cm = Column(Float, nullable=True)
    
    notes = Column(Text, nullable=True)
    
    # Relationships
    user = relationship("User", back_populates="weight_entries")
    
    def __repr__(self):
        return f"<WeightEntry {self.weight_kg}kg>"

class Activity(Base):
    __tablename__ = "activities"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), index=True)
    logged_at = Column(DateTime, default=datetime.utcnow, index=True)
    
    activity_name = Column(String, index=True)
    activity_type = Column(String, nullable=True)  # strength, cardio, walk, yoga, etc
    duration_minutes = Column(Integer)
    intensity = Column(String, nullable=True)  # light, moderate, vigorous
    calories_burned = Column(Float, nullable=True)
    
    # Optional
    distance_km = Column(Float, nullable=True)
    steps = Column(Integer, nullable=True)
    heart_rate_avg = Column(Integer, nullable=True)
    
    source = Column(String, nullable=True)  # manual, fitbit, apple_health, google_fit
    notes = Column(Text, nullable=True)
    
    # Relationships
    user = relationship("User", back_populates="activities")
    
    def __repr__(self):
        return f"<Activity {self.activity_name}>"

class DiaryEntry(Base):
    __tablename__ = "diary_entries"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), index=True)
    created_at = Column(DateTime, default=datetime.utcnow, index=True)
    
    # Tracking
    mood = Column(String, nullable=True)  # 1-5 or emoji
    energy_level = Column(Integer, nullable=True)  # 1-10
    hunger_level = Column(Integer, nullable=True)  # 1-10
    sleep_hours = Column(Float, nullable=True)
    sleep_quality = Column(String, nullable=True)  # poor, fair, good, excellent
    
    # Reflection
    wins = Column(Text, nullable=True)
    challenges = Column(Text, nullable=True)
    proud_of = Column(Text, nullable=True)
    
    # Overall notes
    notes = Column(Text, nullable=True)
    
    # Relationships
    user = relationship("User", back_populates="diary_entries")
    
    def __repr__(self):
        return f"<DiaryEntry user_id={self.user_id}>"
