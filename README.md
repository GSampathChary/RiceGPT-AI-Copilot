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

If you want Render to load the model automatically, set:
- `MODEL_DOWNLOAD_URL=https://.../rice_disease_model.pth`

The backend will download that file on startup if `MODEL_PATH` is empty. This is the easiest way to keep the trained weights out of GitHub while still preserving real predictions in production.

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

Deploying for a public demo
---------------------------
1. Deploy the FastAPI backend to Render as a Web Service.
2. Set these Render environment variables:
   - `GEMINI_API_KEY`
   - `SELECTED_PROVIDER=gemini`
   - `SERVER_HOST=0.0.0.0`
   - `MODEL_DOWNLOAD_URL=https://.../rice_disease_model.pth` if you are hosting the weights elsewhere
   - `PORT=10000` if your Render setup expects a fixed port, or let Render provide `PORT`
3. Build the Flutter web app from `mobile`:

```powershell
flutter build web --release --dart-define=RICEGPT_API_BASE_URL=https://your-render-backend-url.onrender.com
```

4. Upload the `mobile/build/web` output to Firebase Hosting or Cloudflare Pages.
5. In your separate portfolio repo, set `links.live` to the public Flutter web URL.

If you want push-based deployment to Cloudflare Pages, do not rely on the Pages Git integration to build Flutter directly. Instead, use the included GitHub Actions workflow at:

- `.github/workflows/pages-deploy.yml`

That workflow builds `mobile/build/web` in GitHub Actions and deploys the prebuilt assets to Cloudflare Pages. Before using it, add these GitHub repository secrets:

- `CLOUDFLARE_ACCOUNT_ID`
- `CLOUDFLARE_API_TOKEN`

Also make sure the Cloudflare Pages project name in the workflow matches your actual Pages project name.

If you deploy to Firebase Hosting:
- Use the Flutter web build output as the hosting source.
- Firebase Hosting is designed for static web assets and gives you a `web.app` / `firebaseapp.com` URL.

If you deploy to Cloudflare Pages:
- Use the built `web` folder as the Pages output directory.
- Cloudflare Pages gives you a `pages.dev` URL and preview deployments for branches and pull requests.

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
