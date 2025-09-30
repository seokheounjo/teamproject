from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.responses import RedirectResponse
from app.api import auth, projects, tasks, comments, advice, calendar, ws, api_projects

# Ensure models are imported so metadata includes all tables
from app.models import user as _user  # noqa: F401
from app.models import project as _project  # noqa: F401
from app.models import task as _task  # noqa: F401
from app.models import dependency as _dependency  # noqa: F401
from app.models import comment as _comment  # noqa: F401
from app.models.base import Base
from app.deps import engine
from fastapi import Response

app = FastAPI(title="Dev Calendar")
app.mount("/static", StaticFiles(directory="app/static"), name="static")

# Ensure tables exist for tests and local runs (in addition to startup)
Base.metadata.create_all(bind=engine)

@app.on_event("startup")
def _create_tables_if_needed():
	# For local SQLite development only (safe no-op on existing DB)
	Base.metadata.create_all(bind=engine)

app.include_router(auth.router, prefix="/auth", tags=["auth"])
app.include_router(projects.router, prefix="/projects", tags=["projects"])
app.include_router(api_projects.router, prefix="/api/projects", tags=["api-projects"])
app.include_router(tasks.router, prefix="/tasks", tags=["tasks"])
app.include_router(comments.router, prefix="/comments", tags=["comments"])
app.include_router(advice.router, prefix="/advice", tags=["advice"])
app.include_router(calendar.router, prefix="/calendar", tags=["calendar"])
app.include_router(ws.router)

@app.get("/")
def root():
	# Redirect to projects list
	return RedirectResponse(url="/projects")

@app.get("/healthz")
def healthz():
	return Response(status_code=204)
