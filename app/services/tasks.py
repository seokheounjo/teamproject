ALLOWED = {("Backlog","Planned"),("Planned","InProgress"),("InProgress","Review"),("Review","Done"),("*","Blocked"),("Blocked","Planned")}

def can_transition(cur: str, nxt: str) -> bool:
	return (cur, nxt) in ALLOWED or ("*", nxt) in ALLOWED

def dependencies_done(db, task_id: int) -> bool:
	q = db.execute(
		"""
		SELECT t2.status FROM task_dependencies d
		 JOIN tasks t2 ON t2.id=d.prereq_task_id WHERE d.task_id=:tid
		""",
		{"tid": task_id},
	)
	return all(r[0] == "Done" for r in q)
