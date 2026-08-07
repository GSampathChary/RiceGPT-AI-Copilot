from __future__ import annotations

import json
from pathlib import Path
from threading import Lock
from typing import Dict, List

from app.models.chat import ChatRecord
from app.models.diagnosis import DiagnosisRecord


class HistoryService:
    def __init__(self, storage_file: Path) -> None:
        self.storage_file = storage_file
        self._lock = Lock()
        self._data = {"chats": [], "diagnoses": []}
        self._load()

    def _load(self) -> None:
        if self.storage_file.exists():
            try:
                self._data = json.loads(self.storage_file.read_text(encoding="utf-8"))
            except Exception:
                self._data = {"chats": [], "diagnoses": []}

    def _persist(self) -> None:
        self.storage_file.parent.mkdir(parents=True, exist_ok=True)
        self.storage_file.write_text(json.dumps(self._data, indent=2), encoding="utf-8")

    def list_chats(self) -> List[Dict]:
        return list(self._data.get("chats", []))

    def list_diagnoses(self) -> List[Dict]:
        return list(self._data.get("diagnoses", []))

    def add_chat(self, record: ChatRecord) -> ChatRecord:
        with self._lock:
            self._data.setdefault("chats", []).insert(0, record.to_dict())
            self._persist()
        return record

    def add_diagnosis(self, record: DiagnosisRecord) -> DiagnosisRecord:
        with self._lock:
            self._data.setdefault("diagnoses", []).insert(0, record.to_dict())
            self._persist()
        return record

    def clear(self) -> None:
        with self._lock:
            self._data = {"chats": [], "diagnoses": []}
            self._persist()

    def delete_chat(self, record_id: str) -> bool:
        with self._lock:
            before = len(self._data.get("chats", []))
            self._data["chats"] = [item for item in self._data.get("chats", []) if item.get("id") != record_id]
            changed = len(self._data.get("chats", [])) != before
            if changed:
                self._persist()
            return changed

    def delete_diagnosis(self, record_id: str) -> bool:
        with self._lock:
            before = len(self._data.get("diagnoses", []))
            self._data["diagnoses"] = [item for item in self._data.get("diagnoses", []) if item.get("id") != record_id]
            changed = len(self._data.get("diagnoses", [])) != before
            if changed:
                self._persist()
            return changed

