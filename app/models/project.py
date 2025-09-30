from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy import String, DateTime, func, Text
from .base import Base
import enum
from datetime import datetime

class ProjectStatus(str, enum.Enum):
	Active = "Active"
	Archived = "Archived"
	Completed = "Completed"

class Project(Base):
	__tablename__ = "projects"
	id: Mapped[int] = mapped_column(primary_key=True)
	team_id: Mapped[int] = mapped_column(index=True)
	name: Mapped[str] = mapped_column(String(120))
	description: Mapped[str] = mapped_column(Text, default="")
	status: Mapped[ProjectStatus]
	started_at: Mapped[datetime | None]
	completed_at: Mapped[datetime | None]
	created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
