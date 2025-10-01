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
	"""프로젝트 홈 페이지"""
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
	return templates.TemplateResponse("project_home_v2.html", {"request": request, "project": project})

@router.get("/{project_id}/kanban")
def kanban(request: Request, project_id: int, db: Session = Depends(get_db)):
	"""칸반 보드"""
	project = db.query(Project).filter(Project.id == project_id).first()
	tasks = db.query(Task).filter(Task.project_id == project_id).all()
	return templates.TemplateResponse("kanban_v2.html", {"request": request, "project": project, "tasks": tasks})

@router.get("/{project_id}/dashboard")
def dashboard(request: Request, project_id: int, db: Session = Depends(get_db)):
	"""프로젝트 대시보드"""
	project = db.query(Project).filter(Project.id == project_id).first()
	tasks = db.query(Task).filter(Task.project_id == project_id).all()

	# 통계 계산
	total = len(tasks)
	completed = len([t for t in tasks if t.status == "Done"])
	in_progress = len([t for t in tasks if t.status == "InProgress"])
	completion_rate = round((completed / total * 100) if total > 0 else 0, 1)

	# 상태별 분포
	status_counts = {}
	for task in tasks:
		status_counts[task.status] = status_counts.get(task.status, 0) + 1

	status_labels = list(status_counts.keys())
	status_data = list(status_counts.values())

	# 우선순위별 분포
	priority_counts = [0, 0, 0]  # [높음, 중간, 낮음]
	for task in tasks:
		if task.priority == 1:
			priority_counts[0] += 1
		elif task.priority == 2:
			priority_counts[1] += 1
		else:
			priority_counts[2] += 1

	stats = {
		"total": total,
		"completed": completed,
		"in_progress": in_progress,
		"completion_rate": completion_rate
	}

	return templates.TemplateResponse("dashboard.html", {
		"request": request,
		"project": project,
		"stats": stats,
		"status_labels": status_labels,
		"status_data": status_data,
		"priority_data": priority_counts
	})

@router.get("/{project_id}/calendar")
def calendar_view(request: Request, project_id: int, db: Session = Depends(get_db)):
	"""캘린더 뷰"""
	project = db.query(Project).filter(Project.id == project_id).first()
	tasks = db.query(Task).filter(Task.project_id == project_id).all()
	return templates.TemplateResponse("calendar.html", {"request": request, "project": project, "tasks": tasks})

@router.get("/{project_id}/settings")
def project_settings(request: Request, project_id: int, db: Session = Depends(get_db)):
	"""프로젝트 상세 설정 페이지"""
	project = db.query(Project).filter(Project.id == project_id).first()
	if not project:
		return RedirectResponse(url="/projects")
	return templates.TemplateResponse("project_settings.html", {"request": request, "project": project})
