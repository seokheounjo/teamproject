from fastapi import APIRouter, WebSocket

router = APIRouter()

clients = dict()  # project_id -> set of WebSocket

@router.websocket("/ws/projects/{project_id}")
async def project_ws(websocket: WebSocket, project_id: int):
	await websocket.accept()
	clients.setdefault(project_id, set()).add(websocket)
	try:
		while True:
			await websocket.receive_text()  # client ping
	except Exception:
		pass
	finally:
		clients.get(project_id, set()).discard(websocket)
