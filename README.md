# Runalyze

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

### 1. User Registration

- **Endpoint:** `/register`
- **Method:** `POST`
- **Description:** Registers a new user.
- **Request Example:**
    
    ```
    {
        "username": "newuser",
        "password": "securepassword123",
        "third_party_id": "optional_third_party_id"
    }
    
    ```
    
- **Response Example (Success):**
    
    ```
    {
        "message": "User registered successfully"
    }
    
    ```
    
- **Error Responses:**
    - `400 Bad Request`: `{"message": "Username and password are required"}`
    - `409 Conflict`: `{"message": "Username already exists"}`
    - `409 Conflict`: `{"message": "Third-party ID already linked to an account"}`

### 2. User Login

- **Endpoint:** `/login`
- **Method:** `POST`
- **Description:** Authenticates user credentials and logs in.
- **Request Example:**
    
    ```
    {
        "username": "testuser",
        "password": "testpassword"
    }
    
    ```
    
- **Response Example (Success):**
    
    ```
    {
        "message": "Login successful",
        "user_id": 1
    }
    
    ```
    
- **Error Responses:**
    - `401 Unauthorized`: `{"message": "Invalid credentials"}`

### 3. Add Activity Record

- **Endpoint:** `/activities`
- **Method:** `POST`
- **Description:** Records a single running activity.
- **Request Example:**
    
    ```
    {
        "user_id": 1,
        "start_time": "2025-06-27T10:00:00",
        "duration_seconds": 1800,
        "distance_km": 5.0,
        "end_latitude": 25.0330,
        "end_longitude": 121.5645,
        "average_pace_seconds_per_km": 360.0,
        "split_paces": [350, 365, 355, 360, 370],
        "goal_state": true,
        "goal_dist": 5.0,
        "goal_pace": 370
    }
    
    ```
    
- **Response Example (Success):**
    
    ```
    {
        "message": "Activity added successfully",
        "activity_id": 101
    }
    
    ```
    
- **Error Responses:**
    - `400 Bad Request`: `{"message": "Missing field: [field_name]"}`
    - `400 Bad Request`: `{"message": "Invalid date format for start_time. Use ISO format (YYYY-MM-DDTHH:MM:SS)"}`
    - `404 Not Found`: `{"message": "User not found or not authenticated"}`
    - `500 Internal Server Error`: `{"message": "Error adding activity: [error_details]"}`

### 4. Get All User Activity Records

- **Endpoint:** `/activities/<int:user_id>`
- **Method:** `GET`
- **Description:** Retrieves all running activity records for a specified user, ordered by time in descending order.
- **URL Parameters:**
    - `user_id` (Integer): Unique identifier for the user.
- **Response Example (Success):**
    
    ```
    [
        {
            "id": 101,
            "user_id": 1,
            "start_time": "2025-06-27T10:00:00",
            "duration_seconds": 1800,
            "distance_km": 5.0,
            "end_latitude": 25.0330,
            "end_longitude": 121.5645,
            "average_pace_seconds_per_km": 360.0,
            "split_paces": [350, 365, 355, 360, 370],
            "goal_state": true,
            "goal_dist": 5.0,
            "goal_pace": 370
        },
        {
            "id": 100,
            "user_id": 1,
            "start_time": "2025-06-26T09:30:00",
            "duration_seconds": 1200,
            "distance_km": 3.0,
            "end_latitude": 25.0300,
            "end_longitude": 121.5600,
            "average_pace_seconds_per_km": 400.0,
            "split_paces": [390, 410, 400],
            "goal_state": false,
            "goal_dist": 4.0,
            "goal_pace": 390
        }
    ]
    
    ```
    
- **Error Responses:**
    - `404 Not Found`: `{"message": "User not found"}`

### 5. Get User Activity Records from Past Week

- **Endpoint:** `/activities/past_week/<int:user_id>`
- **Method:** `GET`
- **Description:** Retrieves running activity records for the past seven days for a specified user, ordered by time in descending order.
- **URL Parameters:**
    - `user_id` (Integer): Unique identifier for the user.
- **Response Example (Success):** (Similar to `get_user_activities`, but only includes data from the past seven days)
    
    ```
    [
        {
            "id": 101,
            "user_id": 1,
            "start_time": "2025-06-27T10:00:00",
            "duration_seconds": 1800,
            "distance_km": 5.0,
            "end_latitude": 25.0330,
            "end_longitude": 121.5645,
            "average_pace_seconds_per_km": 360.0,
            "split_paces": [350, 365, 355, 360, 370],
            "goal_state": true,
            "goal_dist": 5.0,
            "goal_pace": 370
        }
    ]
    
    ```
    
- **Error Responses:**
    - `404 Not Found`: `{"message": "User not found"}`

### 6. Get User Activity Records for a Specific Date

- **Endpoint:** `/activities_by_date/<int:user_id>/<string:date_str>`
- **Method:** `GET`
- **Description:** Retrieves all running activity records for a specified user on a specific date, ordered by time in descending order.
- **URL Parameters:**
    - `user_id` (Integer): Unique identifier for the user.
    - `date_str` (String): Date string in `YYYY-MM-DD` format.
- **Request Example:** `/activities_by_date/1/2025-06-27`
- **Response Example (Success):** (Similar to `get_user_activities`, but only includes data for the specified date)
    
    ```
    [
        {
            "id": 101,
            "user_id": 1,
            "start_time": "2025-06-27T10:00:00",
            "duration_seconds": 1800,
            "distance_km": 5.0,
            "end_latitude": 25.0330,
            "end_longitude": 121.5645,
            "average_pace_seconds_per_km": 360.0,
            "split_paces": [350, 365, 355, 360, 370],
            "goal_state": true,
            "goal_dist": 5.0,
            "goal_pace": 370
        }
    ]
    
    ```
    
- **Error Responses:**
    - `400 Bad Request`: `{"message": "Invalid date format. Use ISO-MM-DD"}`
    - `404 Not Found`: `{"message": "User not found"}`

### 7. Complete Questionnaire and Set User Traits/Goals

- **Endpoint:** `/finish_questionare`
- **Method:** `POST`
- **Description:** After a user completes the questionnaire, their long-term and current running goals and other traits are set based on their answers.
- **Request Example:**
    
    ```
    {
        "user_id": 1,
        "g1": "Faster speed (Additional: distance=10, speed=4.5)",
        "g2": "Yes (Additional: distance=21, speed=4)",
        "h1": "Within a week",
        "h2": "3~10km",
        "h3": "5~7",
        "h4": "kg (Additional: weight=75)",
        "m1": "No",
        "m2": "Yes"
    }
    
    ```
    
    - **g1:** Running motivation ('Faster speed', 'Longer distance', 'Healthier shape'). Can include additional parameters in `(Additional: ...)` format.
    - **g2:** Whether there is a long-term goal ('Yes', 'No'). If 'Yes', can include additional parameters in `(Additional: ...)` format, such as `distance` (target distance), `speed` (target pace in min/km), `goal` (target distance, used for 'Longer distance' type), `weight` (target weight).
    - **h1:** Time since last run ('More than a month', 'Within a month', 'Within a week').
    - **h2:** Usual running distance ('Less than 3km', '3~10km', 'More than 10km').
    - **h3:** Usual running pace ('Less than 5', '5~7', 'More than 7'), in min/km.
    - **h4:** Current weight. Can include additional parameters in `(Additional: weight=...)` format.
    - **m1:** Whether habitually gives up ('Yes', 'No').
    - **m2:** Whether believes in AI recommendations ('Yes', 'No').
- **Response Example (Success):**
    
    ```
    {
        "message": "Trait created successfully"
    }
    
    ```
    
- **Error Responses:**
    - `400 Bad Request`: `{"error": "Missing user_id"}`

### 8. Get Today's Running Goal

- **Endpoint:** `/goal/<int:user_id>`
- **Method:** `GET`
- **Description:** Retrieves the current running goal (distance and pace) for a specified user.
- **URL Parameters:**
    - `user_id` (Integer): Unique identifier for the user.
- **Response Example (Success):**
    
    ```
    {
        "goal_dist": 5.0,
        "goal_pace": 360.0
    }
    
    ```
    
- **Response Example (Questionnaire not completed):**
    
    ```
    {
        "goal_dist": -1,
        "goal_pace": -1
    }
    
    ```
    
- **Error Responses:**
    - `404 Not Found`: `{"message": "User not found"}`

### 9. Get User Type and Current Weight/Frequency

- **Endpoint:** `/user_type/<int:user_id>`
- **Method:** `GET`
- **Description:** Retrieves the user's type, their current weight, and their running frequency goal.
- **URL Parameters:**
    - `user_id` (Integer): Unique identifier for the user.
- **Response Example (Success):**
    
    ```
    {
        "user_type": "faster",
        "weight": 70.0,
        "freq": 3.0
    }
    
    ```
    
- **Error Responses:**
    - `404 Not Found`: `{"message": "User not found"}`
    - `404 Not Found`: `{"message": "Trait not found"}`

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
