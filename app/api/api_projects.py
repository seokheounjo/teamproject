from fastapi import APIRouter, Depends, Form
from sqlalchemy.orm import Session
from app.deps import get_db
from app.models.project import Project, ProjectStatus
from datetime import datetime

router = APIRouter()

@router.post("/create")
def create_project(
    name: str = Form(...),
    description: str = Form(""),
    status: str = Form("Active"),
    db: Session = Depends(get_db)
):
    """새 프로젝트 생성"""
    project = Project(
        team_id=1,  # 현재는 기본 팀 ID
        name=name,
        description=description,
        status=ProjectStatus[status],
        started_at=datetime.now() if status == "Active" else None
    )
    db.add(project)
    db.commit()
    db.refresh(project)

    # HTMX용 프로젝트 카드 HTML 반환
    projects = db.query(Project).order_by(Project.created_at.desc()).all()
    cards_html = ""
    for proj in projects:
        cards_html += f'''
        <a href="/projects/{proj.id}" class="project-card">
            <div class="project-name">{proj.name}</div>
            <div class="project-desc">{proj.description or '프로젝트 설명이 없습니다.'}</div>
            <div class="project-meta">
                <span class="status-badge status-{proj.status.value.lower()}">
                    {proj.status.value}
                </span>
                <span>📅 {proj.created_at.strftime('%Y-%m-%d')}</span>
            </div>
        </a>
        '''
    return cards_html

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
