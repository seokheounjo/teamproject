from fastapi.testclient import TestClient
from app.main import app

c = TestClient(app)

def test_health_index():
	r = c.post("/auth/login", params={"email":"x","password":"y"})
	assert r.status_code in (200,401)

def test_create_task():
	r = c.post("/tasks/1/create", params={"title":"첫 작업"})
	assert r.status_code == 200
