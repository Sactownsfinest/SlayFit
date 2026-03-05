# SlayFit - Quick Start Guide

## For Developers

### First Time Setup (Windows)

1. **Clone/Navigate to project**
   ```
   cd c:\Users\Dan Maeon\Documents\SlayFit
   ```

2. **Run setup**
   ```
   setup.bat
   ```

3. **Verify installations**
   ```
   flutter doctor
   python --version
   ```

### First Time Setup (Mac/Linux)

```bash
cd ~/Documents/SlayFit
bash setup.sh
```

---

## Running the App

### Backend (Required)

**Terminal 1:**
```bash
cd backend
source venv/bin/activate  # or venv\Scripts\activate on Windows
uvicorn main:app --reload
```

Server at: http://localhost:8000

API Docs: http://localhost:8000/docs

### Mobile App

**Terminal 2:**
```bash
cd mobile
flutter run
```

Or specific device:
```bash
flutter run -d emulator-5554
flutter run -d physical_device
```

---

## Building for Release

### Build APK

```bash
cd mobile
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Build Split APKs (Smaller)

```bash
cd mobile
flutter build apk --split-per-abi
```

Output: `build/app/outputs/flutter-apk/app-*.apk`

---

## Project Structure

```
SlayFit/
├── mobile/              # Flutter iOS/Android app
│   ├── lib/            # Source code
│   ├── pubspec.yaml    # Dependencies
│   └── BUILD_APK.md    # APK build guide
│
├── backend/            # FastAPI server
│   ├── app/           # Application code
│   ├── main.py        # Entry point
│   └── pyproject.toml # Dependencies
│
├── README.md          # Full documentation
├── setup.bat          # Windows setup
└── setup.sh           # Mac/Linux setup
```

---

## Common Commands

### Flutter
```bash
flutter pub get                    # Install dependencies
flutter run                        # Run app
flutter build apk --release        # Build APK
flutter clean                      # Clean build
flutter format lib/                # Format code
flutter analyze                    # Check for issues
```

### Python
```bash
pip install -e ".[dev]"           # Install deps
uvicorn main:app --reload         # Run server
pytest tests/                     # Run tests
black app/                        # Format code
mypy app/                         # Type check
```

---

## Database Setup (Optional)

### Using SQLite (Development)
No setup needed - database.db created automatically

### Using PostgreSQL (Production)

1. **Install PostgreSQL**
2. **Create database**
   ```sql
   CREATE DATABASE slayfit;
   CREATE USER slayfit_user WITH PASSWORD 'password';
   GRANT ALL PRIVILEGES ON DATABASE slayfit TO slayfit_user;
   ```
3. **Update .env**
   ```
   DATABASE_URL=postgresql://slayfit_user:password@localhost:5432/slayfit
   ```

---

## Troubleshooting

### "Flutter not found"
- Add Flutter to PATH
- Run `flutter doctor` to verify

### Backend won't start
- Check Python version: `python --version`
- Clear cache: `rm -rf __pycache__`
- Check port 8000 is free

### Mobile app won't connect to backend
- Ensure backend is running on 8000
- Check API_BASE_URL in `mobile/lib/config/api_config.dart`
- For Android emulator: use `10.0.2.2` instead of `localhost`
- For physical device: use your machine IP address

### APK install fails
- `adb uninstall com.example.slayfit`
- `adb install -r build/app/outputs/flutter-apk/app-release.apk`

---

## IDE Setup

### VS Code
Install extensions:
- Flutter
- Python
- Dart

### Android Studio
- Create new Flutter project
- Open SlayFit/mobile folder
- Let it set up Android SDK

---

## Next Steps

1. ✅ Set up backend
2. ✅ Set up mobile app
3. ⏳ Connect to PostgreSQL database
4. ⏳ Add Firebase authentication
5. ⏳ Integrate food database API
6. ⏳ Test on real Android device
7. ⏳ Build and distribute APK

---

## Resources

- [Flutter Docs](https://flutter.dev/docs)
- [FastAPI Docs](https://fastapi.tiangolo.com)
- [Android App Distribution](https://developer.android.com/distribute)
- [Firebase Setup](https://firebase.google.com/docs)

---

## Need Help?

- Check [README.md](README.md) for full documentation
- See [backend/API.md](backend/API.md) for API endpoints
- See [mobile/BUILD_APK.md](mobile/BUILD_APK.md) for build details
