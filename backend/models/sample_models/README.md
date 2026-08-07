# Sample Model Folder

Use this folder as a reference for the local model layout expected by the backend.

Recommended local files:
- `backend/models/rice_disease_model.pth`
- `backend/models/rice_disease_model.pt`
- `backend/models/rice_disease_model.h5`
- `backend/models/rice_disease_model.keras`
- `backend/models/rice_disease_savedmodel/`

These files are intentionally not committed to GitHub because they are large training artifacts.
Keep them on your machine, then point `MODEL_PATH` in `backend/.env` to the exact file or folder you want to load.

If you want to publish the weights later, upload them as GitHub Release assets instead of committing them to the repo.
