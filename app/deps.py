from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from app.config import settings
import os

engine_kwargs = dict(pool_pre_ping=True, future=True)

if settings.DB_URL.startswith("sqlite"):
	# Make SQLite work well in local/tests (Windows paths, threads, in-memory)
	engine_kwargs["connect_args"] = {"check_same_thread": False}
	if settings.DB_URL in ("sqlite://", "sqlite:///:memory:"):
		engine_kwargs["poolclass"] = StaticPool

engine = create_engine(settings.DB_URL, **engine_kwargs)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False, future=True)

def get_db():
	db = SessionLocal()
	try:
		yield db
	finally:
		db.close()
