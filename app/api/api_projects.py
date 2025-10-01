from fastapi import APIRouter, Depends, Form, Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy.orm import Session
from app.deps import get_db
from app.models.project import Project, ProjectStatus
from datetime import datetime

router = APIRouter()
templates = Jinja2Templates(directory="app/templates")

@router.post("/create")
def create_project(
    request: Request,
    name: str = Form(...),
    description: str = Form(""),
    status: str = Form("Active"),
    start_date: str = Form(None),
    end_date: str = Form(None),
    db: Session = Depends(get_db)
):
    """새 프로젝트 생성"""
    # 날짜 파싱
    started_at = None
    if start_date:
        try:
            started_at = datetime.strptime(start_date, "%Y-%m-%d")
        except:
            started_at = datetime.now() if status == "Active" else None
    elif status == "Active":
        started_at = datetime.now()

    project = Project(
        team_id=1,
        name=name,
        description=description,
        status=ProjectStatus[status],
        started_at=started_at,
        completed_at=None
    )
    db.add(project)
    db.commit()
    db.refresh(project)

    # 전체 프로젝트 목록 다시 렌더링
    projects = db.query(Project).order_by(Project.created_at.desc()).all()

    # HTML 문자열을 직접 반환
    from fastapi.responses import HTMLResponse

    html = ""
    for proj in projects:
        date_info = ""
        if proj.started_at:
            date_info += f'<span>📅 시작: {proj.started_at.strftime("%Y-%m-%d")}</span>'
        if proj.completed_at:
            date_info += f'<span>🏁 완료: {proj.completed_at.strftime("%Y-%m-%d")}</span>'

        html += f'''<a href="/projects/{proj.id}" class="project-card">
    <div class="project-name">{proj.name}</div>
    <div class="project-desc">{proj.description or '프로젝트 설명이 없습니다.'}</div>
    <div class="project-meta">
        <span class="status-badge status-{proj.status.value.lower()}">
            {proj.status.value}
        </span>
        {date_info}
    </div>
</a>'''

    return HTMLResponse(content=html)

@router.post("/{project_id}/update")
def update_project(
    project_id: int,
    name: str = Form(None),
    description: str = Form(None),
    status: str = Form(None),
    db: Session = Depends(get_db)
):
    """프로젝트 업데이트"""
    project = db.query(Project).filter(Project.id == project_id).first()
    if not project:
        return {"error": "Project not found"}

    if name:
        project.name = name
    if description is not None:
        project.description = description
    if status:
        project.status = ProjectStatus[status]
        if status == "Completed" and not project.completed_at:
            project.completed_at = datetime.now()

    db.commit()
    return {"success": True, "project_id": project_id}

@router.delete("/{project_id}")
def delete_project(project_id: int, db: Session = Depends(get_db)):
    """프로젝트 삭제"""
    project = db.query(Project).filter(Project.id == project_id).first()
    if project:
        db.delete(project)
        db.commit()
        return {"success": True}
    return {"error": "Project not found"}

@router.post("/{project_id}/settings")
def update_project_settings(
    project_id: int,
    goals: str = Form(""),
    milestones: str = Form("[]"),
    sprints: str = Form("[]"),
    db: Session = Depends(get_db)
):
    """프로젝트 상세 설정 업데이트"""
    import json
    project = db.query(Project).filter(Project.id == project_id).first()
    if not project:
        return {"error": "Project not found"}

    project.goals = goals
    try:
        milestone_data = json.loads(milestones) if milestones and milestones != "[]" else []
        sprint_data = json.loads(sprints) if sprints and sprints != "[]" else []

        project.milestones = milestone_data
        project.sprints = sprint_data

        print(f"DEBUG: Saved milestones: {project.milestones}")
        print(f"DEBUG: Saved sprints: {project.sprints}")
    except json.JSONDecodeError as e:
        print(f"DEBUG: JSON decode error: {e}")
        return {"error": "Invalid JSON format"}

    db.commit()
    db.refresh(project)
    return {
        "success": True,
        "project_id": project_id,
        "milestones": project.milestones,
        "sprints": project.sprints
    }

@router.get("/{project_id}/progress")
def get_project_progress(project_id: int, db: Session = Depends(get_db)):
    """프로젝트 진행률 계산"""
    from app.models.task import Task

    project = db.query(Project).filter(Project.id == project_id).first()
    if not project:
        return {"error": "Project not found"}

    tasks = db.query(Task).filter(Task.project_id == project_id).all()
    total_tasks = len(tasks)
    completed_tasks = len([t for t in tasks if t.status == "Done"])

    progress = round((completed_tasks / total_tasks * 100) if total_tasks > 0 else 0, 1)

    return {
        "project_id": project_id,
        "total_tasks": total_tasks,
        "completed_tasks": completed_tasks,
        "progress": progress
    }
