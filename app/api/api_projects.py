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
