from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy import ForeignKey, UniqueConstraint
from .base import Base

class TaskDependency(Base):
	__tablename__ = "task_dependencies"
	__table_args__ = (UniqueConstraint("task_id", "prereq_task_id"),)
	id: Mapped[int] = mapped_column(primary_key=True)
	task_id: Mapped[int] = mapped_column(ForeignKey("tasks.id", ondelete="CASCADE"), index=True)
	prereq_task_id: Mapped[int] = mapped_column(ForeignKey("tasks.id", ondelete="CASCADE"), index=True)
