from fastapi import APIRouter, Depends, Request, Form
from fastapi.templating import Jinja2Templates
from fastapi.responses import RedirectResponse
from sqlalchemy.orm import Session
from app.deps import get_db
from app.models.task import Task
from app.models.project import Project, ProjectStatus
from datetime import datetime

router = APIRouter()
templates = Jinja2Templates(directory="app/templates")

@router.get("/")
def projects_list(request: Request, db: Session = Depends(get_db)):
	"""프로젝트 목록 페이지"""
	projects = db.query(Project).order_by(Project.created_at.desc()).all()
	return templates.TemplateResponse("projects_list.html", {"request": request, "projects": projects})

@router.get("/{project_id}")
def project_index(request: Request, project_id: int, db: Session = Depends(get_db)):
	"""프로젝트 메인 페이지 (칸반보드로 리다이렉트)"""
	project = db.query(Project).filter(Project.id == project_id).first()
	if not project:
		# 프로젝트가 없으면 기본 프로젝트 생성
		project = Project(
			team_id=1,
			name=f"Project {project_id}",
			description="기본 프로젝트",
			status=ProjectStatus.Active
		)
		db.add(project)
		db.commit()
		db.refresh(project)
	return templates.TemplateResponse("index.html", {"request": request, "project": project})

@router.get("/{project_id}/kanban")
def kanban(request: Request, project_id: int, db: Session = Depends(get_db)):
	"""칸반 보드"""
	project = db.query(Project).filter(Project.id == project_id).first()
	tasks = db.query(Task).filter(Task.project_id == project_id).all()
	return templates.TemplateResponse("kanban_improved.html", {"request": request, "project": project, "tasks": tasks})

@router.get("/{project_id}/calendar")
def calendar_view(request: Request, project_id: int, db: Session = Depends(get_db)):
	"""캘린더 뷰"""
	project = db.query(Project).filter(Project.id == project_id).first()
	tasks = db.query(Task).filter(Task.project_id == project_id).all()
	return templates.TemplateResponse("calendar.html", {"request": request, "project": project, "tasks": tasks})
