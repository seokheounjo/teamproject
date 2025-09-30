from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.deps import get_db
import httpx, json
from app.config import settings

router = APIRouter()

ADVICE_PROMPT = """너는 선임 개발 코치다. 아래 컨텍스트를 바탕으로
1) 바로 할 일 3~5개 체크리스트
2) 리스크 1~3개와 완화전략
3) 간단 커밋 메시지 예시
를 한국어로 간결히 제시하라.
컨텍스트:
{context}
"""

def build_context(db, task_id: int) -> str:
	row = db.execute("SELECT title, description, status FROM tasks WHERE id=:id", {"id": task_id}).first()
	deps = db.execute(
		"""
		  SELECT t2.title, t2.status FROM task_dependencies d JOIN tasks t2
		  ON t2.id=d.prereq_task_id WHERE d.task_id=:tid
		""",
		{"tid": task_id},
	).all()
	return json.dumps({"task": dict(row._mapping) if row else {}, "deps": [dict(title=x[0], status=x[1]) for x in deps]}, ensure_ascii=False)

@router.post("/ask/{task_id}")
def ask(task_id: int, db: Session = Depends(get_db)):
	ctx = build_context(db, task_id)
	prompt = ADVICE_PROMPT.format(context=ctx)

	headers = {"Authorization": f"Bearer {settings.LLM_API_KEY}"} if settings.LLM_API_KEY else {}
	try:
		r = httpx.post(settings.LLM_ENDPOINT, json={"prompt": prompt}, headers=headers, timeout=60)
		r.raise_for_status()
		advice = r.json().get("text") if r.headers.get("content-type","" ).startswith("application/json") else r.text
	except Exception as e:
		advice = f"(조언 생성 실패) {e}"

	db.execute("INSERT INTO comments (task_id, source, body) VALUES (:t,'advisor',:b)", {"t": task_id, "b": advice})
	db.commit()
	return {"ok": True, "advice": advice}
