from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    DATABASE_URL: str = "postgresql://user:password@localhost:5432/slayfit"
    SECRET_KEY: str = "your-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    ENVIRONMENT: str = "development"
    DEBUG: bool = True
    
    # API Keys for integrations
    EDAMAM_API_ID: Optional[str] = None
    EDAMAM_API_KEY: Optional[str] = None
    NUTRITIONIX_API_KEY: Optional[str] = None
    
    class Config:
        env_file = ".env"

settings = Settings()
