from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.deps import get_db
from app.models.task import Task
from app.models.dependency import TaskDependency
from app.services.tasks import can_transition, dependencies_done

router = APIRouter()

@router.post("/{project_id}/create")
def create_task(project_id: int, title: str, db: Session = Depends(get_db)):
	t = Task(project_id=project_id, title=title)
	db.add(t)
	db.commit()
	db.refresh(t)
	return {"id": t.id}

@router.post("/move/{task_id}")
def move(task_id: int, next_status: str, db: Session = Depends(get_db)):
	t = db.get(Task, task_id)
	if not t:
		raise HTTPException(404)
	if not can_transition(t.status, next_status):
		raise HTTPException(400, "invalid transition")
	if next_status == "InProgress" and not dependencies_done(db, t.id):
		raise HTTPException(409, "deps not done")
	t.status = next_status
	db.commit()
	return {"ok": True}
