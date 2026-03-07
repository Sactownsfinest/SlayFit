"""
Main FastAPI application for SlayFit backend
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZIPMiddleware
from app.core.database import engine, Base
from app.models.user import User, UserProfile, FoodLog, WeightEntry, Activity, DiaryEntry
from app.api import users, food, weight, activities, diary, auth, coach

# Create tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="SlayFit API",
    description="Intelligent Weight Loss & Fitness App API",
    version="0.1.0",
)

# Middleware
app.add_middleware(GZIPMiddleware, minimum_size=1000)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Health check
@app.get("/health")
def health_check():
    return {"status": "ok"}

# API Routes
app.include_router(auth.router, prefix="/api/auth", tags=["Authentication"])
app.include_router(users.router, prefix="/api/users", tags=["Users"])
app.include_router(food.router, prefix="/api/food", tags=["Food Logging"])
app.include_router(weight.router, prefix="/api/weight", tags=["Weight Tracking"])
app.include_router(activities.router, prefix="/api/activities", tags=["Activities"])
app.include_router(diary.router, prefix="/api/diary", tags=["Diary"])
app.include_router(coach.router, prefix="/api/coach", tags=["AI Coach"])

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
