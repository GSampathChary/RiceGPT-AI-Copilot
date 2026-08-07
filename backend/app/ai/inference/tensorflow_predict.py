from __future__ import annotations

from pathlib import Path
from typing import List, Optional, Tuple

from .image_processor import load_image, preprocess_image


class TensorflowPredictor:
    def __init__(self, model_path: Optional[Path], labels: List[str], input_size: int = 224) -> None:
        self.model_path = model_path
        self.labels = labels
        self.input_size = input_size
        self.model = None

    def is_available(self) -> bool:
        return self.model_path is not None and self.model_path.exists()

    def load(self) -> None:
        if not self.is_available():
            return
        try:
            import tensorflow as tf

            self.model = tf.saved_model.load(str(self.model_path))
        except Exception as exc:
            raise RuntimeError(f"Failed to load TensorFlow model at {self.model_path}: {exc}") from exc

    def predict(self, image_path: Path) -> Tuple[str, float]:
        if self.model is None:
            self.load()
        if self.model is None:
            raise RuntimeError("TensorFlow model is not loaded.")

        raise RuntimeError(
            "SavedModel inference is project-specific. Configure a Keras .h5/.keras model or extend the loader for your exported signature."
        )
