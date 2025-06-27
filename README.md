# Runalyze

This project is a running performance tracking application, consisting of a Flutter-based mobile frontend and a Flask-based Python backend. It allows users to record their running activities, view historical data, and track progress towards their fitness goals.

# Running Performance Tracker App

This project is a running performance tracking application, consisting of a Flutter-based mobile frontend and a Flask-based Python backend. It allows users to record their running activities, view historical data, and track progress towards their fitness goals.

## Table of Contents

- [Features](https://www.notion.so/21f2ac42b1da80fa81e3cace044a23aa?pvs=21)
- [Directory Structure](https://www.notion.so/21f2ac42b1da80fa81e3cace044a23aa?pvs=21)
- [Setup Instructions](https://www.notion.so/21f2ac42b1da80fa81e3cace044a23aa?pvs=21)
    - [Backend Setup](https://www.notion.so/21f2ac42b1da80fa81e3cace044a23aa?pvs=21)
        - [Prerequisites](https://www.notion.so/21f2ac42b1da80fa81e3cace044a23aa?pvs=21)
        - [Installation](https://www.notion.so/21f2ac42b1da80fa81e3cace044a23aa?pvs=21)
        - [Database Initialization](https://www.notion.so/21f2ac42b1da80fa81e3cace044a23aa?pvs=21)
        - [Running the Backend](https://www.notion.so/21f2ac42b1da80fa81e3cace044a23aa?pvs=21)
    - [Frontend Setup](https://www.notion.so/21f2ac42b1da80fa81e3cace044a23aa?pvs=21)
        - [Prerequisites](https://www.notion.so/21f2ac42b1da80fa81e3cace044a23aa?pvs=21)
        - [Installation](https://www.notion.so/21f2ac42b1da80fa81e3cace044a23aa?pvs=21)
        - [Running the Frontend](https://www.notion.so/21f2ac42b1da80fa81e3cace044a23aa?pvs=21)
- [API Endpoints](https://www.notion.so/21f2ac42b1da80fa81e3cace044a23aa?pvs=21)
- [Database Schema](https://www.notion.so/21f2ac42b1da80fa81e3cace044a23aa?pvs=21)
- [Frontend Architecture](https://www.notion.so/21f2ac42b1da80fa81e3cace044a23aa?pvs=21)
- [Usage](https://www.notion.so/21f2ac42b1da80fa81e3cace044a23aa?pvs=21)
- [Contributing](https://www.notion.so/21f2ac42b1da80fa81e3cace044a23aa?pvs=21)
- [License](https://www.notion.so/21f2ac42b1da80fa81e3cace044a23aa?pvs=21)

## Features

- **User Authentication:** Secure user registration and login.
- **Activity Tracking:** Record running distance, duration, pace, and split times.
- **Historical Data:** View past workout records by date.
- **Goal Tracking:** Monitor goal achievement status (completed/missed) for each activity.
- **Personalized Goals:** Backend logic to update user performance traits and goals based on activity.
- **Responsive UI:** Flutter frontend designed for various screen sizes.

## Directory Structure

```
jnoctis-hackathon_physical_app/
├── README.md
├── physicalapp/
│   ├── analysis_options.yaml
│   ├── pubspec.yaml
│   ├── .metadata
│   ├── android/
│   │   ├── build.gradle.kts
│   │   ├── gradle.properties
│   │   ├── settings.gradle.kts
│   │   └── app/...
│   ├── assets/
│   │   └── lottie/
│   │       └── running.json
│   ├── ios/...
│   ├── lib/
│   │   ├── instruction.dart
│   │   ├── login.dart
│   │   ├── main.dart
│   │   ├── signup.dart
│   │   ├── pages/
│   │   │   ├── analysis.dart
│   │   │   ├── history.dart
│   │   │   ├── history_day.dart
│   │   │   ├── run.dart
│   │   │   └── running_result.dart
│   │   └── utils/
│   │       ├── calculate.dart
│   │       ├── time_format.dart
│   │       └── titles.dart
│   ├── linux/...
│   ├── macos/...
│   ├── test/...
│   ├── web/...
│   └── windows/...
└── physicalbackend/
    ├── database.py
    ├── run_backend.bat
    ├── run_server.ps1
    ├── server.py
    └── requirements.txt

```

## Database Schema

The backend uses `Flask-SQLAlchemy` to manage the database. The database schema is defined in `physicalbackend/database.py` and includes the following models:

### User Model

Represents a user of the application.

- `id` (Integer, Primary Key): Unique identifier for the user.
- `username` (String, Unique, Not Null): User's unique username.
- `password_hash` (String, Not Null): Hashed password for secure storage.
- `third_party_id` (String, Unique, Nullable): Optional ID for third-party authentication (e.g., Google, Facebook).
- `created_at` (DateTime): Timestamp when the user account was created (UTC).
- `activities` (Relationship): One-to-many relationship with `Activity` records.

### Activity Model

Stores details of each running activity.

- `id` (Integer, Primary Key): Unique identifier for the activity.
- `user_id` (Integer, Foreign Key): Links to the `User` who performed the activity.
- `start_time` (DateTime, Not Null): The exact start time of the activity.
- `duration_seconds` (Integer, Not Null): Total duration of the activity in seconds.
- `distance_km` (Float, Not Null): Total distance covered in kilometers.
- `end_latitude` (Float, Nullable): Latitude at the end of the activity.
- `end_longitude` (Float, Nullable): Longitude at the end of the activity.
- `average_pace_seconds_per_km` (Integer, Not Null): Average pace in seconds per kilometer.
- `split_paces_json` (Text, Nullable): JSON string storing a list of dictionaries, where each dictionary contains `km` and `paceSeconds` for individual kilometers.
- `goal_state` (String, Nullable): The state of the goal for this activity (e.g., 'completed', 'missed', 'None').
- `goal_dist` (Float, Nullable): The target distance for the goal (if any).
- `goal_pace` (Integer, Nullable): The target pace in seconds per km for the goal (if any).

### Trait Model

Stores user-specific traits and personalized goal information.

- `id` (Integer, Primary Key): Unique identifier for the trait record.
- `user_id` (Integer, Foreign Key, Unique, Not Null): Links to the `User` this trait belongs to.
- `user_type` (String, Nullable): User's type, possibly determined from a questionnaire.
- `long_goal` (MutableDict / JSON, Nullable): A dictionary storing long-term goals.
- `curr_goal` (MutableDict / JSON, Nullable): A dictionary storing current active goals.
- `usually_quit` (Boolean, Default False): Indicates if the user usually quits runs.
- `now_quit` (Boolean, Default False): Indicates if the user quit the current run.
- `believe_ai` (Boolean, Default True): Indicates if the user believes in AI recommendations.

## API Endpoints

The Flask backend provides the following RESTful API endpoints:

### User Management

- **`POST /register`**
    - **Description:** Registers a new user.
    - **Request Body:** `application/json`
        
        ```
        {
            "username": "newuser",
            "password": "securepassword",
            "third_party_id": "optional_id_from_oauth"
        }
        
        ```
        
    - **Responses:** `201 Created` (success) or `400 Bad Request` / `409 Conflict` (failure).
- **`POST /login`**
    - **Description:** Authenticates a user.
    - **Request Body:** `application/json`
        
        ```
        {
            "username": "existinguser",
            "password": "correctpassword"
        }
        
        ```
        
    - **Responses:** `200 OK` (success with `user_id`) or `401 Unauthorized` (failure).

### Activity Management

- **`POST /activities`**
    - **Description:** Adds a new running activity record.
    - **Request Body:** `application/json`
        
        ```
        {
            "user_id": 1,
            "start_time": "2025-06-27T10:00:00",
            "duration_seconds": 1800,
            "distance_km": 5.2,
            "average_pace_seconds_per_km": 346,
            "split_paces": [{"km": 1, "pace_seconds": 340}, ...],
            "goal_state": "completed",
            "goal_dist": 5.0,
            "goal_pace": 360
        }
        
        ```
        
    - **Responses:** `201 Created` (success with `activity_id`) or `400 Bad Request` / `404 Not Found` / `500 Internal Server Error` (failure).
- **`GET /activities/<int:user_id>`**
    - **Description:** Retrieves all running activities for a specific user, ordered by `start_time` descending.
    - **Parameters:** `user_id` (Path)
    - **Responses:** `200 OK` (array of activity objects) or `404 Not Found` (user not found).
- **`GET /activities/past_week/<int:user_id>`**
    - **Description:** Retrieves running activities for a specific user from the past 7 days.
    - **Parameters:** `user_id` (Path)
    - **Responses:** `200 OK` (array of activity objects) or `404 Not Found` (user not found).
- **`GET /activities_by_date/<int:user_id>/<string:date_str>`**
    - **Description:** Retrieves running activities for a specific user on a given date.
    - **Parameters:** `user_id` (Path), `date_str` (Path, format `YYYY-MM-DD`)
    - **Responses:** `200 OK` (array of activity objects) or `400 Bad Request` / `404 Not Found` (failure).

### Trait and Goal Management

- **`POST /finish_questionare`**
    - **Description:** Processes a user's questionnaire answers to initialize or update their `Trait` record and set initial goals.
    - **Request Body:** `application/json`, containing `user_id` and questionnaire answers.
    - **Responses:** `201 Created` (success) or `400 Bad Request` / `409 Conflict` (failure).
- **`GET /goal/<int:user_id>`**
    - **Description:** Retrieves the current recommended running goal (distance and pace) for a specific user.
    - **Parameters:** `user_id` (Path)
    - **Responses:** `200 OK` (JSON with `goal_dist` and `goal_pace`) or `404 Not Found` (user not found).
- **`GET /user_type/<int:user_id>`**
    - **Description:** Retrieves the user's type, current weight, and running frequency.
    - **Parameters:** `user_id` (Path)
    - **Responses:** `200 OK` (JSON with `user_type`, `weight`, `freq`) or `404 Not Found` (user or trait not found).

## Setup Instructions

### Backend Setup

### Prerequisites

- Python 3.8+
- pip (Python package installer)

### Installation

1. Navigate to the `physicalbackend/` directory:
    
    ```
    cd jnoctis-hackathon_physical_app/physicalbackend/
    
    ```
    
2. (Recommended) Create and activate a virtual environment:
    
    ```
    python -m venv venv
    # Windows:
    .\venv\Scripts\activate
    # macOS/Linux:
    source venv/bin/activate
    
    ```
    
3. Install required Python packages:
    
    ```
    pip install -r requirements.txt
    
    ```
    

### Database Initialization

The backend uses a SQLite database (`site.db`) by default. It needs to be initialized before running the server.

1. Ensure your virtual environment is activated.
2. Set the `FLASK_APP` environment variable:
    
    ```
    # Windows:
    set FLASK_APP=server.py
    # macOS/Linux:
    export FLASK_APP=server.py
    
    ```
    
3. Run the database initialization command:
    
    ```
    flask init-db
    
    ```
    
    **Note:** If you modify your database models, you may need to delete `site.db` and re-run `flask init-db`. **Deleting `site.db` will erase all existing data.**
    

### Running the Backend

- **Windows (using Command Prompt/CMD):**
    
    ```
    @echo off
    
    echo Setting FLASK_APP environment variable...
    set FLASK_APP=server.py
    
    echo Initializing database... (This will drop existing data if uncommented in init_db_command)
    flask init-db
    
    echo Starting Flask server...
    python server.py
    
    pause
    
    ```
    
- **Windows (using PowerShell):**
    
    ```
    $env:FLASK_APP="server.py"
    
    flask init-db
    
    python .\server.py
    
    ```
    
- **Manual Run (for other OS or direct control):**
Ensure your virtual environment is activated and `FLASK_APP` is set, then run:
    
    ```
    python server.py
    
    ```
    
    The server typically runs on `http://127.0.0.1:5000`.
    

### Frontend Setup

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Android Studio](https://developer.android.com/studio) / Xcode
- Code editor (e.g., VS Code)

### Installation

1. Navigate to the `physicalapp/` directory:
    
    ```
    cd jnoctis-hackathon_physical_app/physicalapp/
    
    ```
    
2. Get Flutter dependencies:
    
    ```
    flutter pub get
    
    ```
    
3. **Create `.env` file:** In the `physicalapp/` directory, create a file named `.env` and add your backend API base URL:
    
    ```
    BASE_URL=http://127.0.0.1:5000
    
    ```
    
    **Important:** Ensure this URL matches where your Flask backend is running.
    

### Running the Frontend

1. Ensure you are in the `physicalapp/` directory and Flutter dependencies are installed.
2. Connect a device or start an emulator/simulator.
3. Run the Flutter application:
    
    ```
    flutter run
    
    ```
    
    The app will launch on your connected device or emulator.
    

## Frontend Architecture

The Flutter frontend (`physicalapp/lib/`) structure:

- **`main.dart`**: The entry point of the application, handling environment variable loading, app theme, routing, and main navigation flow. It directs users to the login or instruction page based on questionnaire completion.
- **`pages/history.dart`**: Displays a calendar view of user's past activities, coloring dates based on activity goal status, and allowing viewing detailed activities for a selected date.
- **`pages/history_day.dart`**: Shows detailed running activity records for a specific date, including goal status, key metrics, and split paces, with support for swiping through multiple activities.
- **`pages/run.dart`**: The core live run tracking screen, handling location tracking, timer, metric calculation, split times, pace alerts (audio feedback), progress bar, and data submission upon run completion.
- **`pages/running_result.dart`**: Displays a detailed summary of a single completed running activity, including date, distance, average pace, total time, and goal status.
- **`pages/analysis.dart`**: Serves as the "Analysis" tab, retrieving and displaying user-specific info (type, weight, frequency), weekly running statistics, and generating motivational titles and habit stability progress based on user data.
- **`login.dart`**: User login interface, handling credential submission, session management, and displaying error messages.
- **`signup.dart`**: New user registration interface, handling the registration process, input validation, and navigation.
- **`instruction.dart`**: Guides users through a series of questions to classify their running goals and habits, dynamically displaying input fields, collecting answers, and submitting to the backend for personalized goal setting.
- **`utils/time_format.dart`**: Contains utility functions for formatting time and pace values specifically for the app's UI, e.g., converting seconds to `HH:MM:SS` or `MM'SS"` format.
- **`utils/calculate.dart`**: Contains utility functions for performing calculations related to running data, e.g., calculating the average of a list of double values.
- **`utils/titles.dart`**: Contains utility functions for generating dynamic titles and messages based on user data and activity metrics, used in the analysis page for personalized feedback.
