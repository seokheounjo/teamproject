from fastapi import APIRouter, Depends, Request
from fastapi.templating import Jinja2Templates
from sqlalchemy.orm import Session
from app.deps import get_db
from app.models.task import Task

router = APIRouter()
templates = Jinja2Templates(directory="app/templates")

@router.get("/{project_id}")
def project_index(request: Request, project_id: int):
	return templates.TemplateResponse("index.html", {"request": request, "project": {"id": project_id, "name": f"Project {project_id}"}})

@router.get("/{project_id}/kanban")
def kanban(request: Request, project_id: int, db: Session = Depends(get_db)):
	tasks = db.query(Task).filter(Task.project_id == project_id).all()
	return templates.TemplateResponse("kanban.html", {"request": request, "project": {"id": project_id, "name": f"Project {project_id}"}, "tasks": tasks})

@router.get("/{project_id}/calendar")
def calendar_view(request: Request, project_id: int, db: Session = Depends(get_db)):
	tasks = db.query(Task).filter(Task.project_id == project_id).all()
	return templates.TemplateResponse("calendar.html", {"request": request, "project": {"id": project_id, "name": f"Project {project_id}"}, "tasks": tasks})
