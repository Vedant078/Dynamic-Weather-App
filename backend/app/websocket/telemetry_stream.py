from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from typing import Dict, List, Any
import asyncio
import json
from datetime import datetime, timezone
from app.repositories.batch_repository import batch_repo


router = APIRouter(tags=["WebSocket Telemetry"])


class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)

    async def broadcast(self, message: Dict[str, Any]):
        dead_connections = []
        for connection in self.active_connections:
            try:
                await connection.send_text(json.dumps(message))
            except Exception:
                dead_connections.append(connection)
        for dead in dead_connections:
            self.disconnect(dead)


manager = ConnectionManager()


@router.websocket("/ws/v1/rmc/batches/{batch_id}")
async def websocket_endpoint(websocket: WebSocket, batch_id: str):
    await manager.connect(websocket)
    try:
        # Send initial snapshot immediately
        batch = batch_repo.get_batch(batch_id)
        if batch:
            await websocket.send_text(json.dumps({
                "type": "telemetry_snapshot",
                "batch_id": batch_id,
                "data": batch
            }))
            
        while True:
            # Keep connection alive & listen for client ping or simulator trigger
            data = await websocket.receive_text()
            try:
                msg = json.loads(data)
                if msg.get("action") == "ping":
                    await websocket.send_text(json.dumps({"type": "pong", "time": datetime.now(timezone.utc).isoformat()}))
            except Exception:
                pass
    except WebSocketDisconnect:
        manager.disconnect(websocket)
    except Exception:
        manager.disconnect(websocket)
