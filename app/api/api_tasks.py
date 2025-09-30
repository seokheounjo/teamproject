from fastapi import APIRouter, Depends, Form, HTTPException
from fastapi.responses import HTMLResponse
from sqlalchemy.orm import Session
from app.deps import get_db
from app.models.task import Task
from app.models.comment import Comment
from datetime import datetime

router = APIRouter()

@router.post("/create")
def create_task(
    project_id: int = Form(...),
    title: str = Form(...),
    description: str = Form(""),
    status: str = Form("Backlog"),
    priority: int = Form(2),
    start_date: str = Form(None),
    due_date: str = Form(None),
    story_points: int = Form(None),
    tags: str = Form(None),
    db: Session = Depends(get_db)
):
    """새 태스크 생성"""
    # 날짜 파싱
    start_dt = None
    due_dt = None
    if start_date:
        try:
            start_dt = datetime.strptime(start_date, "%Y-%m-%d")
        except:
            pass
    if due_date:
        try:
            due_dt = datetime.strptime(due_date, "%Y-%m-%d")
        except:
            pass

    task = Task(
        project_id=project_id,
        title=title,
        description=description,
        status=status,
        priority=priority,
        start_date=start_dt,
        due_date=due_dt,
        story_points=story_points,
        tags=tags
    )
    db.add(task)
    db.commit()
    db.refresh(task)

    # 태스크 카드 HTML 반환
    priority_class = f"priority-{task.priority}"
    html = f'''<div class="task-card" data-task-id="{task.id}" onclick="openTaskDetail({task.id})">
    <div class="task-title">{task.title}</div>
    <div class="task-meta">
        <span class="task-id">TASK-{task.id}</span>
        <span class="priority-badge {priority_class}">
            {'높음' if task.priority == 1 else '중간' if task.priority == 2 else '낮음'}
        </span>
    </div>
</div>'''

    return HTMLResponse(content=html)

@router.post("/{task_id}/update")
def update_task(
    task_id: int,
    title: str = Form(None),
    description: str = Form(None),
    status: str = Form(None),
    priority: int = Form(None),
    start_date: str = Form(None),
    due_date: str = Form(None),
    story_points: int = Form(None),
    tags: str = Form(None),
    db: Session = Depends(get_db)
):
    """태스크 업데이트"""
    task = db.query(Task).filter(Task.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    if title:
        task.title = title
    if description is not None:
        task.description = description
    if status:
        task.status = status
    if priority:
        task.priority = priority
    if start_date:
        try:
            task.start_date = datetime.strptime(start_date, "%Y-%m-%d")
        except:
            pass
    if due_date:
        try:
            task.due_date = datetime.strptime(due_date, "%Y-%m-%d")
        except:
            pass
    if story_points is not None:
        task.story_points = story_points
    if tags is not None:
        task.tags = tags

    db.commit()
    return {"success": True, "task_id": task_id}

@router.post("/{task_id}/move")
def move_task(
    task_id: int,
    status: str = Form(...),
    db: Session = Depends(get_db)
):
    """태스크 상태 변경"""
    task = db.query(Task).filter(Task.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    task.status = status
    db.commit()
    return {"success": True, "task_id": task_id, "new_status": status}

@router.delete("/{task_id}")
def delete_task(task_id: int, db: Session = Depends(get_db)):
    """태스크 삭제"""
    task = db.query(Task).filter(Task.id == task_id).first()
    if task:
        db.delete(task)
        db.commit()
        return {"success": True}
    raise HTTPException(status_code=404, detail="Task not found")

@router.get("/{task_id}")
def get_task_detail(task_id: int, db: Session = Depends(get_db)):
    """태스크 상세 정보"""
    task = db.query(Task).filter(Task.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    comments = db.query(Comment).filter(Comment.task_id == task_id).order_by(Comment.created_at.desc()).all()

    return {
        "id": task.id,
        "title": task.title,
        "description": task.description,
        "status": task.status,
        "priority": task.priority,
        "start_date": task.start_date.strftime("%Y-%m-%d") if task.start_date else None,
        "due_date": task.due_date.strftime("%Y-%m-%d") if task.due_date else None,
        "story_points": task.story_points,
        "tags": task.tags,
        "created_at": task.created_at.strftime("%Y-%m-%d %H:%M"),
        "comments": [{"id": c.id, "body": c.body, "created_at": c.created_at.strftime("%Y-%m-%d %H:%M")} for c in comments]
    }

@router.post("/{task_id}/comment")
def add_comment(
    task_id: int,
    body: str = Form(...),
    db: Session = Depends(get_db)
):
    """코멘트 추가"""
    comment = Comment(
        task_id=task_id,
        body=body,
        source="user"
    )
    db.add(comment)
    db.commit()
    db.refresh(comment)

    return {
        "success": True,
        "comment": {
            "id": comment.id,
            "body": comment.body,
            "created_at": comment.created_at.strftime("%Y-%m-%d %H:%M")
        }
    }
