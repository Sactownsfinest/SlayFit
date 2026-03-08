from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    DATABASE_URL: str = "postgresql://user:password@localhost:5432/slayfit"
    # IMPORTANT: Set SECRET_KEY in your .env file before deploying.
    # Generate one with: python -c "import secrets; print(secrets.token_hex(32))"
    SECRET_KEY: str = "CHANGE_ME_generate_with_secrets_token_hex_32"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60

    ENVIRONMENT: str = "development"
    DEBUG: bool = False  # Never expose debug info in production
    
    # Anthropic AI Coach
    ANTHROPIC_API_KEY: Optional[str] = None

    # API Keys for integrations
    EDAMAM_API_ID: Optional[str] = None
    EDAMAM_API_KEY: Optional[str] = None
    NUTRITIONIX_API_KEY: Optional[str] = None
    
    class Config:
        env_file = ".env"

settings = Settings()
