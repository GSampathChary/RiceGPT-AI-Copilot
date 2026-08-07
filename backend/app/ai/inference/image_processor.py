from __future__ import annotations

from io import BytesIO
from pathlib import Path
from typing import List

from PIL import Image


def load_image(path: Path) -> Image.Image:
    return Image.open(path).convert("RGB")


def load_image_from_bytes(blob: bytes) -> Image.Image:
    return Image.open(BytesIO(blob)).convert("RGB")


def preprocess_image(image: Image.Image, size: int = 224) -> List[List[List[List[float]]]]:
    resized = image.resize((size, size))
    pixels = list(resized.getdata())
    rows: List[List[List[float]]] = []
    row: List[List[float]] = []
    for index, pixel in enumerate(pixels, start=1):
        row.append([channel / 255.0 for channel in pixel])
        if index % size == 0:
            rows.append(row)
            row = []
    return [rows]
