import os
import sys

from fastapi.testclient import TestClient

sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))
from main import app  # noqa: E402

client = TestClient(app)

def test_health_check():
    res = client.get("/health")
    assert res.status_code == 200
    assert res.json()["status"] == "healthy"

def test_create_task():
    res = client.post("/tasks", json={
        "title": "Implement OAuth",
        "project": "RD-2024",
        "status": "pending"
    })
    assert res.status_code == 201
    data = res.json()
    assert data["title"] == "Implement OAuth"
    assert "id" in data

def test_list_tasks():
    res = client.get("/tasks")
    assert res.status_code == 200
    assert isinstance(res.json(), list)

def test_get_task():
    # Create first
    create = client.post("/tasks", json={"title": "Test Task", "status": "pending"})
    task_id = create.json()["id"]
    # Then fetch
    res = client.get(f"/tasks/{task_id}")
    assert res.status_code == 200
    assert res.json()["id"] == task_id

def test_update_task():
    create = client.post("/tasks", json={"title": "Old Title", "status": "pending"})
    task_id = create.json()["id"]
    res = client.put(f"/tasks/{task_id}", json={"title": "New Title", "status": "in_progress"})
    assert res.status_code == 200
    assert res.json()["status"] == "in_progress"

def test_delete_task():
    create = client.post("/tasks", json={"title": "To Delete", "status": "pending"})
    task_id = create.json()["id"]
    res = client.delete(f"/tasks/{task_id}")
    assert res.status_code == 204
    # Confirm gone
    res = client.get(f"/tasks/{task_id}")
    assert res.status_code == 404

def test_get_nonexistent_task():
    res = client.get("/tasks/00000000-0000-0000-0000-000000000000")
    assert res.status_code == 404
