from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy import String, ForeignKey, DateTime, func, Text, Integer
from datetime import datetime
from .base import Base

class Task(Base):
	__tablename__ = "tasks"
	id: Mapped[int] = mapped_column(primary_key=True)
	project_id: Mapped[int] = mapped_column(ForeignKey("projects.id", ondelete="CASCADE"), index=True)
	sprint_id: Mapped[int | None]
	parent_task_id: Mapped[int | None]
	title: Mapped[str] = mapped_column(String(200))
	description: Mapped[str] = mapped_column(Text, default="")
	status: Mapped[str] = mapped_column(String(20), index=True, default="Backlog")
	priority: Mapped[int] = mapped_column(Integer, default=2)
	assignee_id: Mapped[int | None]
	start_date: Mapped[datetime | None]
	due_date: Mapped[datetime | None]
	story_points: Mapped[int | None]
	order_index: Mapped[int] = mapped_column(Integer, default=0)
	tags: Mapped[str | None]
	created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
	updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
