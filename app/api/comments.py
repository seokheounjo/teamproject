from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.deps import get_db

router = APIRouter()

@router.post("/{task_id}")
def add_comment(task_id: int, body: str, source: str = "user", db: Session = Depends(get_db)):
	db.execute("INSERT INTO comments (task_id, source, body) VALUES (:t,:s,:b)", {"t": task_id, "s": source, "b": body})
	db.commit()
	return {"ok": True}
