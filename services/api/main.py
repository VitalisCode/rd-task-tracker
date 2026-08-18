import logging
import sys
from datetime import datetime, timezone
from uuid import UUID, uuid4

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

# Structured logging for ELK
logging.basicConfig(
    stream=sys.stdout,
    level=logging.INFO,
    format='{"time": "%(asctime)s", "level": "%(levelname)s", "message": "%(message)s"}'
)
logger = logging.getLogger(__name__)

# Secrets like SECRET_KEY, DB_PASSWORD, and JWT_SECRET are expected to be injected
# into the pod as environment variables by the runtime/platform.
app = FastAPI(title="R&D Task Tracker API", version="1.0.0")

# In-memory store (good enough for demo)
tasks_db = {}

class Task(BaseModel):
    title: str
    description: str | None = None
    status: str = "pending"  # pending | in_progress | done
    project: str | None = None

class TaskResponse(Task):
    id: UUID
    created_at: datetime

@app.get("/health")
def health_check():
    logger.info("Health check called")
    return {"status": "healthy", "service": "api"}

@app.get("/tasks", response_model=list[TaskResponse])
def list_tasks():
    logger.info(f"Listing {len(tasks_db)} tasks")
    return list(tasks_db.values())

@app.post("/tasks", response_model=TaskResponse, status_code=201)
def create_task(task: Task):
    task_id = uuid4()
    new_task = TaskResponse(id=task_id, created_at=datetime.now(timezone.utc), **task.dict())
    tasks_db[task_id] = new_task
    logger.info(f"Created task {task_id}: {task.title}")
    return new_task

@app.get("/tasks/{task_id}", response_model=TaskResponse)
def get_task(task_id: UUID):
    if task_id not in tasks_db:
        raise HTTPException(status_code=404, detail="Task not found")
    return tasks_db[task_id]

@app.put("/tasks/{task_id}", response_model=TaskResponse)
def update_task(task_id: UUID, updated: Task):
    if task_id not in tasks_db:
        raise HTTPException(status_code=404, detail="Task not found")
    existing = tasks_db[task_id]
    updated_task = TaskResponse(
        id=task_id,
        created_at=existing.created_at,
        **updated.dict()
    )
    tasks_db[task_id] = updated_task
    logger.info(f"Updated task {task_id}")
    return updated_task

@app.delete("/tasks/{task_id}", status_code=204)
def delete_task(task_id: UUID):
    if task_id not in tasks_db:
        raise HTTPException(status_code=404, detail="Task not found")
    del tasks_db[task_id]
    logger.info(f"Deleted task {task_id}")

# @app.get("/config")
# def show_config():
#     """Shows which secrets were loaded — values masked for safety"""
#     return {
#         "SECRET_KEY_SET": bool(os.environ.get("SECRET_KEY")),
#         "DB_PASSWORD_SET": bool(os.environ.get("DB_PASSWORD")),
#         "JWT_SECRET_SET": bool(os.environ.get("JWT_SECRET")),
#     }