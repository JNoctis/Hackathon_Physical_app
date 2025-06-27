# Runalyze

This is a full-stack application consisting of a **Flutter frontend** (mobile app) and a **Flask backend** (API server) for tracking physical activities (e.g., running). Below is the project structure and setup guide.

---

## 📁 Project Structure

### **Frontend (Flutter App)**
```
physicalapp/
├── android/                 # Android platform-specific files
├── ios/                     # iOS platform-specific files
├── lib/                     # Main Dart source code
│   ├── instruction.dart     # App instructions screen
│   ├── login.dart           # Login page
│   ├── main.dart            # App entry point
│   ├── signup.dart          # Signup page
│   ├── pages/               # App screens
│   │   ├── analysis.dart    # Activity analysis
│   │   ├── history.dart     # History overview
│   │   ├── history_day.dart # Daily history details
│   │   ├── run.dart         # Running activity screen
│   │   └── running_result.dart # Post-run results
│   └── utils/               # Helper utilities
│       ├── calculate.dart   # Calculation logic
│       ├── time_format.dart # Time formatting
│       └── titles.dart      # UI text constants
├── assets/                  # Static assets (e.g., animations)
│   └── lottie/running.json  # Lottie animation for running
├── pubspec.yaml             # Flutter dependencies
└── test/                    # Unit/widget tests
```

### **Backend (Flask API)**
```
physicalbackend/
├── database.py      # Database models and operations
├── server.py        # Flask API routes and logic
├── run_backend.bat  # Windows script to start the server
└── run_server.ps1   # PowerShell script to start the server
```

---

## 🛠 Setup Instructions

### **Frontend (Flutter)**
1. **Install Flutter**: Follow the [official guide](https://flutter.dev/docs/get-started/install).
2. **Run the app**:
   ```bash
   cd physicalapp
   flutter pub get   # Install dependencies
   flutter run       # Launch on connected device/emulator
   ```

### **Backend (Flask)**
1. **Install Python** (3.7+ recommended) and pip.
2. **Install dependencies**:
   ```bash
   cd physicalbackend
   pip install flask flask-cors sqlalchemy  # Install required packages
   ```
3. **Run the server**:
   - Windows (CMD):
     ```bash
     run_backend.bat
     ```
   - Windows (PowerShell):
     ```bash
     .\run_server.ps1
     ```
   - Linux/macOS:
     ```bash
     python server.py
     ```
   The server will start at `http://localhost:5000`.

---

## 🔌 API Endpoints (Backend)
The Flask backend provides the following endpoints:
- `POST /login`: User login.
- `POST /signup`: User registration.
- `POST /save_activity`: Save running activity data.
- `GET /history`: Fetch user activity history.

---

## 📱 App Features (Frontend)
1. **User Authentication**: Login/signup.
2. **Activity Tracking**: Record running sessions.
3. **History**: View past activities with details.
4. **Analysis**: Visualize performance metrics.
5. **Animations**: Lottie animations for better UX.

---

## 📦 Dependencies
### Flutter (Frontend)
- `lottie`: For animations (`running.json`).
- `http`: For API communication.
- Other standard Flutter packages (see `pubspec.yaml`).

### Flask (Backend)
- `Flask`: Web framework.
- `Flask-CORS`: Cross-origin support.
- `SQLAlchemy`: Database ORM.

---

## 📝 Notes
- **Database**: The backend uses SQLite (default) for simplicity. Modify `database.py` for other databases.
- **Environment**: Ensure Flutter and Python environments are properly set up.

---

Let me know if you'd like me to explain any specific file (e.g., `server.py`, `main.dart`) in detail!
