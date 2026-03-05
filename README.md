# SlayFit - Intelligent Weight Loss & Fitness App

A comprehensive mobile app built with **Flutter** and **FastAPI** for intelligent weight loss tracking and fitness management.

## 📱 Mobile App (Flutter)

### Features
- ✅ User authentication & onboarding
- ✅ Dashboard with calorie tracking
- ✅ Food logging with image recognition
- ✅ Weight tracking with graphs
- ✅ Activity logging
- ✅ Daily diary entries
- ✅ Progress analytics
- ⏳ Smart reminders & notifications
- ⏳ Wearable integrations (Fitbit, Apple Health, Google Fit)

### Requirements
- Flutter 3.0+
- Dart 3.0+
- Android SDK (for APK building)
- Xcode (for iOS, optional)

### Setup

1. **Install Flutter** (if not already installed)
   ```bash
   # Download from https://flutter.dev/docs/get-started/install
   # Add Flutter to your PATH
   flutter doctor
   ```

2. **Install dependencies**
   ```bash
   cd mobile
   flutter pub get
   ```

3. **Build APK for Android**
   ```bash
   # Development APK (debug)
   flutter build apk

   # Release APK (optimized, ~20% smaller)
   flutter build apk --release

   # Split APKs by architecture
   flutter build apk --split-per-abi
   ```

4. **Run on emulator or device**
   ```bash
   flutter run
   ```

### Build Output
The built APK will be located at:
```
mobile/build/app/outputs/flutter-apk/app-release.apk
```

### Installation on Android Device
```bash
# Via ADB
adb install build/app/outputs/flutter-apk/app-release.apk

# Or transfer APK directly to device and install manually
```

---

## 🔧 Backend API (FastAPI)

### Features
- ✅ User authentication (JWT)
- ✅ User profile & onboarding
- ✅ Food logging API
- ✅ Weight tracking
- ✅ Activity logging
- ✅ Diary entries
- ⏳ Food database integration
- ⏳ TDEE calculation
- ⏳ Weight loss analytics

### Requirements
- Python 3.11+
- PostgreSQL (or SQLite for development)
- pip or uv

### Setup

1. **Configure Python environment**
   ```bash
   cd backend
   
   # Using uv (faster)
   uv venv
   source .venv/bin/activate  # or .venv\Scripts\activate on Windows
   
   # Or using venv
   python -m venv venv
   source venv/bin/activate
   ```

2. **Install dependencies**
   ```bash
   # Using uv
   uv pip install -e ".[dev]"
   
   # Or using pip
   pip install -e ".[dev]"
   ```

3. **Configure database**
   ```bash
   cp .env.example .env
   # Edit .env with your database credentials
   ```

4. **Run migrations** (optional - FastAPI creates tables automatically)
   ```bash
   alembic upgrade head
   ```

5. **Start the server**
   ```bash
   uvicorn main:app --reload
   ```

Server will be running at `http://localhost:8000`

### API Documentation
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

---

## 📊 Project Structure

```
SlayFit/
├── mobile/                  # Flutter mobile app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/        # UI screens
│   │   ├── models/         # Data models
│   │   ├── services/       # API services
│   │   ├── providers/      # State management
│   │   └── widgets/        # Reusable widgets
│   ├── pubspec.yaml        # Flutter dependencies
│   └── android/            # Android-specific config
│
├── backend/                 # FastAPI backend
│   ├── app/
│   │   ├── api/            # Route handlers
│   │   ├── models/         # Database models
│   │   ├── schemas/        # Pydantic schemas
│   │   ├── services/       # Business logic
│   │   └── core/           # Config, security, database
│   ├── main.py             # FastAPI entry point
│   ├── pyproject.toml      # Python dependencies
│   └── .env.example        # Environment variables
│
└── README.md
```

---

## 🚀 Development Workflow

### Backend Development
```bash
cd backend
source venv/bin/activate
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Mobile Development
```bash
cd mobile
flutter run -d <device_id>

# Hot reload while running
# Press 'r' to rebuild, 'R' for full restart
```

---

## 🔐 Security

- JWT tokens for authentication
- Password hashing with bcrypt
- CORS enabled for mobile app
- Environment variables for sensitive config

**Important**: Never commit `.env` file or API keys to version control!

---

## 📱 Android APK Signing (Release)

For distributing outside Google Play:

```bash
# Create keystore (one-time)
keytool -genkey -v -keystore ~/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias slayfit

# Build signed APK
flutter build apk --release \
  --dart-define=KEYSTORE_PATH=~/key.jks \
  --dart-define=KEYSTORE_PASSWORD=yourpassword \
  --dart-define=KEY_ALIAS=slayfit \
  --dart-define=KEY_PASSWORD=yourpassword
```

Or create `android/key.properties`:
```properties
storePassword=yourpassword
keyPassword=yourpassword
keyAlias=slayfit
storeFile=/path/to/key.jks
```

---

## 🔄 API Integration

Mobile app connects to backend via:
- **Base URL**: `http://localhost:8000/api` (development)
- **Production**: Update `API_BASE_URL` in [mobile/lib/config/api_config.dart](mobile/lib/config/api_config.dart)

---

## 🧪 Testing

### Backend Tests
```bash
cd backend
pytest tests/
```

### Mobile Tests
```bash
cd mobile
flutter test
```

---

## 🐛 Troubleshooting

### Flutter Issues
- `flutter clean && flutter pub get`
- Check `flutter doctor` for missing dependencies
- Ensure Android SDK is correctly configured

### Backend Issues
- Verify PostgreSQL is running
- Check `.env` configuration
- Review logs in `uvicorn` terminal

### API Connection
- Ensure backend is running on correct port
- Check firewall/network settings
- Verify `API_BASE_URL` in mobile config

---

## 📝 Next Steps

1. **Database**: Set up PostgreSQL for production
2. **Authentication**: Integrate Firebase or OAuth2
3. **Food Database**: Connect Edamam or Nutritionix API
4. **Image Recognition**: Implement ML model for food detection
5. **Wearables**: Add Fitbit/Apple Health integration
6. **Push Notifications**: Configure Firebase Cloud Messaging
7. **Analytics**: Add event tracking

---

## 📄 License

Private - SlayFit Team

---

## 👥 Contributing

1. Create a feature branch: `git checkout -b feature/name`
2. Commit changes: `git commit -m "Add feature"`
3. Push: `git push origin feature/name`
4. Create Pull Request

---

## 📞 Support

For issues and questions, create an GitHub issue or contact the team.

---

**Built with ❤️ for a healthier you**
