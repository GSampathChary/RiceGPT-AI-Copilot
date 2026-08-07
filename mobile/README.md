RiceGPT AI Mobile App
=====================

Flutter app for the RiceGPT AI project.

Features
--------
- Home dashboard
- Rice chat assistant
- Leaf disease diagnosis upload
- Disease library
- History
- Settings

Run locally
-----------

```powershell
flutter pub get
flutter run
```

Make sure the backend URL in Settings points to your FastAPI server.
Default backend URL is `http://10.0.2.2:8000` on Android emulator and `http://127.0.0.1:8000` on iOS simulator or desktop.

The app reads the label catalog from the backend `GET /api/labels` endpoint and uses it as the stress-list view.
