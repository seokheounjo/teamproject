from fastapi import APIRouter, Depends, HTTPException, Response
from sqlalchemy.orm import Session
from icalendar import Calendar, Event
from app.deps import get_db
from app.config import settings
from app.models.task import Task

router = APIRouter()

@router.get("/{project_id}.ics")
def ics_feed(project_id: int, token: str, db: Session = Depends(get_db)):
	if token != settings.ICS_TOKEN:
		raise HTTPException(403)
	cal = Calendar()
	cal.add('prodid', '-//DevCalendar//')
	cal.add('version', '2.0')
	tasks = db.query(Task).filter(Task.project_id == project_id).all()
	for t in tasks:
		if t.due_date:
			ev = Event()
			ev.add('summary', f"[{t.status}] {t.title}")
			ev.add('dtstart', t.due_date)
			ev.add('dtend', t.due_date)
			cal.add_component(ev)
	return Response(cal.to_ical(), media_type="text/calendar")
