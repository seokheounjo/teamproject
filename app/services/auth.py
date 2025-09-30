from passlib.context import CryptContext
from datetime import datetime, timedelta, timezone
import jwt
from app.config import settings

pwd = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_pw(raw: str) -> str:
	return pwd.hash(raw)

def verify_pw(raw: str, hashed: str) -> bool:
	return pwd.verify(raw, hashed)

def create_token(sub: str, expires_minutes: int = 60) -> str:
	payload = {"sub": sub, "exp": datetime.now(tz=timezone.utc) + timedelta(minutes=expires_minutes)}
	return jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.JWT_ALG)
