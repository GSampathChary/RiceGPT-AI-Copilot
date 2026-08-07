RiceGPT AI
===========

RiceGPT AI is a personal portfolio project for rice agriculture assistance.

What is included
----------------
- FastAPI backend for chat, diagnosis, history, provider discovery, and disease library access
- Flutter mobile app with home, chat, diagnosis, library, history, and settings screens
- Provider architecture for Gemini now, with OpenAI, Claude, Grok, DeepSeek, and Ollama slots ready
- Model loading hooks for Keras `.h5`/`.keras`, TensorFlow SavedModel, and PyTorch `.pt`/`.pth`
- Local fallback knowledge so the app still demonstrates the workflow even before you connect your own model

Where to put your trained model
-------------------------------
Store your trained model files inside:
- `E:\AI-Portfolio\Projects\RiceGPT-AI\backend\models\`

Set `MODEL_PATH` in `backend/.env` to the exact file you want to load. The backend will try to load:
- `.h5` or `.keras` with Keras/TensorFlow
- `.pt` or `.pth` with PyTorch
- TensorFlow SavedModel directories when you point `MODEL_PATH` at the exported folder

The repository includes a small placeholder folder at:
- `backend/models/sample_models/`

Use it as a reference for the expected layout, but keep the actual large weights local or attach them to a GitHub Release.

How to run the backend
----------------------
1. Copy `backend/.env.example` to `backend/.env`
2. Fill in `GEMINI_API_KEY` if you want live Gemini chat
3. Set `MODEL_PATH` to your trained model file if you have one
4. From the `backend` folder run:

```powershell
python -m app.main
```

The backend listens on `0.0.0.0:8000` by default, so the emulator can reach it.

How to run the Flutter app
--------------------------
1. From the `mobile` folder run `flutter pub get`
2. Start the app with `flutter run`
3. In Settings, confirm the backend URL matches your local server
4. Android emulator default backend URL is `http://10.0.2.2:8000`
5. iOS simulator and desktop default backend URL is `http://127.0.0.1:8000`

API endpoints
-------------
- `GET /health`
- `GET /api/providers`
- `POST /api/chat`
- `POST /api/diagnosis`
- `GET /api/history`
- `GET /api/library/diseases`
- `GET /api/labels`

Notes
-----
- Gemini is the default provider when an API key is configured.
- If no model is configured yet, the app still works with fallback responses and local disease data.
- You can extend the provider interfaces later without changing the Flutter UI.
- Large trained weights are intentionally excluded from GitHub so the repo stays lightweight.
- If you publish a release, attach model files as release assets instead of committing them to the source tree.
