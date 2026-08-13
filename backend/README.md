RiceGPT AI Backend
==================

This backend is a FastAPI service for RiceGPT AI.

Main responsibilities
---------------------
- Chat with rice-specific context
- Load a trained image classifier for rice leaf disease
- Save chat and diagnosis history
- Expose provider metadata for the Flutter app
- Serve a disease library for the UI

Environment variables
---------------------
Use `backend/.env.example` as a template.

Important values:
- `GEMINI_API_KEY`
- `SELECTED_PROVIDER`
- `MODEL_PATH`
- `MODEL_LABELS`

Supported model types
---------------------
- Keras `.h5`
- Keras `.keras`
- TensorFlow SavedModel directory
- PyTorch `.pt` / `.pth` for TorchScript exports

Recommended local paths
-----------------------
- `backend/models/rice_disease_model.h5`
- `backend/models/rice_disease_model.keras`
- `backend/models/rice_disease_model.pt`
- `backend/models/rice_disease_model.pth`
- `backend/models/rice_disease_savedmodel/`

Placeholder folder
-------------------
- `backend/models/sample_models/`

This folder is tracked only as a layout reference. Put your real model files in `backend/models/` locally, then point `MODEL_PATH` at the exact file or folder you want the backend to use.

If you want to share the trained weights without bloating the repository, attach them to a GitHub Release as separate assets.

Run locally
-----------

```powershell
python -m app.main
```

The API will be available at `http://127.0.0.1:8000` on the host machine and `http://10.0.2.2:8000` from an Android emulator.

Deploying to Render
-------------------
Render should run the service on `0.0.0.0` and use the port exposed by the platform. This backend now reads `PORT` automatically, so you can use Render's web service defaults safely.

Recommended Render settings:
- Build command: `pip install -r requirements.txt`
- Start command: `python -m app.main`
- Environment variables:
  - `GEMINI_API_KEY`
  - `SELECTED_PROVIDER=gemini`
  - `SERVER_HOST=0.0.0.0`
  - `PORT` supplied by Render

After deployment, copy the Render URL and use it when building the Flutter web app with `--dart-define=RICEGPT_API_BASE_URL=...`.

Useful endpoints
----------------
- `GET /api/labels` for the model stress-label catalog
- `GET /api/library/diseases` for the disease knowledge cards
- `GET /api/history` for saved chats and diagnoses
