# Backend API Documentation

## Overview
FastAPI-based REST API for SlayFit mobile app. Handles user authentication, health data tracking, and analytics.

## Base URL
```
http://localhost:8000/api
```

## Authentication
Use Bearer token in Authorization header:
```
Authorization: Bearer {access_token}
```

## Endpoints

### Authentication

#### POST /auth/login
Login with email and password.
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

Response:
```json
{
  "access_token": "eyJhbGc...",
  "token_type": "bearer"
}
```

#### POST /auth/register
Register new account.
```json
{
  "email": "user@example.com",
  "username": "john_doe",
  "password": "password123"
}
```

---

### User Profile

#### GET /users/profile
Get current user's profile.

#### PUT /users/profile
Update user profile.
```json
{
  "first_name": "John",
  "last_name": "Doe",
  "height_cm": 175,
  "current_weight_kg": 85,
  "goal_weight_kg": 75,
  "activity_level": "moderate",
  "sleep_hours": 7.5,
  "stress_level": "low"
}
```

#### POST /users/profile/onboarding-complete
Mark onboarding as finished.

---

### Food Logging

#### POST /food/logs
Create food log entry.
```json
{
  "food_name": "Chicken Breast",
  "calories": 165,
  "protein_g": 31,
  "carbs_g": 0,
  "fat_g": 3.6,
  "portion_size": "100g",
  "meal_type": "lunch",
  "source": "manual"
}
```

#### GET /food/logs/today
Get today's food logs.

#### GET /food/logs
Get food logs for date range.
```
?start_date=2024-01-01&end_date=2024-01-31
```

#### DELETE /food/logs/{id}
Delete food log entry.

#### GET /food/search
Search food database.
```
?q=chicken
```

#### POST /food/estimate-calories
Estimate calories from image (AI).
```json
{
  "image_url": "https://..."
}
```

---

### Weight Tracking

#### POST /weight/entries
Record weight.
```json
{
  "weight_kg": 82.5,
  "body_fat_percent": 22.5,
  "waist_cm": 85,
  "hips_cm": 95,
  "chest_cm": 100
}
```

#### GET /weight/entries
Get weight history.
```
?days=90
```

#### GET /weight/latest
Get latest weight entry.

#### GET /weight/trend
Get weight trend data.

---

### Activities

#### POST /activities
Log activity.
```json
{
  "activity_name": "Running",
  "activity_type": "cardio",
  "duration_minutes": 30,
  "intensity": "vigorous",
  "calories_burned": 350,
  "distance_km": 5.0,
  "source": "manual"
}
```

#### GET /activities/today
Get today's activities.

---

### Diary

#### POST /diary
Create diary entry.
```json
{
  "mood": "happy",
  "energy_level": 8,
  "hunger_level": 3,
  "sleep_hours": 7.5,
  "sleep_quality": "good",
  "wins": "Stayed under calorie goal",
  "challenges": "Had cravings in evening",
  "proud_of": "Did 30min workout"
}
```

#### GET /diary/today
Get today's diary entry.

---

## Error Responses

### 400 Bad Request
```json
{
  "detail": "Invalid input"
}
```

### 401 Unauthorized
```json
{
  "detail": "Invalid authentication credentials"
}
```

### 404 Not Found
```json
{
  "detail": "Resource not found"
}
```

### 500 Server Error
```json
{
  "detail": "Internal server error"
}
```

---

## Rate Limiting
Currently not implemented. Add Redis for production.

---

## CORS
Enabled for all origins in development.
Restrict in production!

---

## Development

### Run with hot reload
```bash
uvicorn main:app --reload
```

### Run tests
```bash
pytest tests/
```

### Generate API docs
Automatically available at:
- Swagger: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc
