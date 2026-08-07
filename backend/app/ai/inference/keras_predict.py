from __future__ import annotations

from pathlib import Path
from typing import List, Optional, Tuple

from .image_processor import load_image, preprocess_image


class KerasPredictor:
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
            from tensorflow import keras

            self.model = keras.models.load_model(str(self.model_path))
        except Exception:
            try:
                import keras

                self.model = keras.models.load_model(str(self.model_path))
            except Exception as exc:
                raise RuntimeError(f"Failed to load Keras model at {self.model_path}: {exc}") from exc

    def predict(self, image_path: Path) -> Tuple[str, float]:
        if self.model is None:
            self.load()
        if self.model is None:
            raise RuntimeError("Keras model is not loaded.")

        image = load_image(image_path)
        data = preprocess_image(image, self.input_size)
        predictions = self.model.predict(data, verbose=0)
        first = predictions[0]
        if hasattr(first, "tolist"):
            values = [float(value) for value in first.tolist()]
        else:
            values = [float(value) for value in first]
        index = max(range(len(values)), key=values.__getitem__)
        confidence = float(values[index])
        label = self.labels[index] if 0 <= index < len(self.labels) else f"Class {index}"
        return label, confidence
