import os
from dotenv import load_dotenv

# Load .env if present
load_dotenv()


class Settings:
	DB_URL: str = os.getenv("DB_URL", "sqlite:///./app.db")
	SECRET_KEY: str = os.getenv("SECRET_KEY", "dev-secret")
	JWT_ALG: str = os.getenv("JWT_ALG", "HS256")
	LLM_API_KEY: str = os.getenv("LLM_API_KEY", "")
	LLM_ENDPOINT: str = os.getenv("LLM_ENDPOINT", "http://localhost:11434/api/generate")
	ICS_TOKEN: str = os.getenv("ICS_TOKEN", "dev")


settings = Settings()
