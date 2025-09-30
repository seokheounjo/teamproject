from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy import Integer, String, Text, DateTime, func, ForeignKey
from .base import Base
from datetime import datetime

class Comment(Base):
	__tablename__ = "comments"
	id: Mapped[int] = mapped_column(primary_key=True)
	task_id: Mapped[int] = mapped_column(ForeignKey("tasks.id", ondelete="CASCADE"), index=True)
	source: Mapped[str] = mapped_column(String(32), default="user")
	body: Mapped[str] = mapped_column(Text)
	created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
