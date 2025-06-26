# server.py
import os
from flask import Flask, request, jsonify
from flask_cors import CORS
import json
from datetime import datetime
import click # Import click for custom commands

# Import db and models from database.py
from database import db, User, Activity, init_db_command

# Initialize Flask app
app = Flask(__name__)
CORS(app) # Enable CORS for all routes

# Database Configuration
# Use PostgreSQL for production, SQLite for development for simplicity
# Example for PostgreSQL: 'postgresql://user:password@host:port/database_name'
app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get('DATABASE_URL', 'sqlite:///site.db')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

# Initialize db with the Flask app
db.init_app(app)

# --- Custom Flask CLI Command for Database Initialization ---
# Register the init_db_command with the Flask app's CLI
app.cli.add_command(click.command("init-db")(init_db_command))


# --- API Endpoints ---

@app.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')
    third_party_id = data.get('third_party_id')

    if not username or not password:
        return jsonify({'message': 'Username and password are required'}), 400

    if User.query.filter_by(username=username).first():
        return jsonify({'message': 'Username already exists'}), 409

    if third_party_id and User.query.filter_by(third_party_id=third_party_id).first():
        return jsonify({'message': 'Third-party ID already linked to an account'}), 409

    new_user = User(username=username, third_party_id=third_party_id)
    new_user.set_password(password)
    db.session.add(new_user)
    db.session.commit()
    return jsonify({'message': 'User registered successfully'}), 201


@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')

    user = User.query.filter_by(username=username).first()

    if user and user.check_password(password):
        # In a real application, you would return a JWT or session token here
        return jsonify({'message': 'Login successful', 'user_id': user.id}), 200
    return jsonify({'message': 'Invalid credentials'}), 401


@app.route('/activities', methods=['POST'])
def add_activity():
    data = request.get_json()

    # In a real app, authenticate the user and get their user_id from the session/token
    # For simplicity, we'll assume user_id is provided in the request body for now.
    # You'd likely get this from a JWT or session.
    user_id = data.get('user_id')
    
    if not user_id or not User.query.get(user_id):
        return jsonify({'message': 'User not found or not authenticated'}), 404
    
    # Validate required fields
    required_fields = ['start_time', 'duration_seconds', 'distance_km', 'average_pace_seconds_per_km']
    for field in required_fields:
        if field not in data:
            return jsonify({'message': f'Missing field: {field}'}), 400

    try:
        # Convert start_time string to datetime object
        start_time = datetime.fromisoformat(data['start_time'])

        # Convert split_paces list to JSON string
        split_paces_json_data = data.get('split_paces', [])
        split_paces_json_string = json.dumps(split_paces_json_data)

        new_activity = Activity(
            user_id=user_id,
            start_time=start_time,
            duration_seconds=data['duration_seconds'],
            distance_km=data['distance_km'],
            start_latitude=data.get('start_latitude'),
            start_longitude=data.get('start_longitude'),
            end_latitude=data.get('end_latitude'),
            end_longitude=data.get('end_longitude'),
            average_pace_seconds_per_km=data['average_pace_seconds_per_km'],
            split_paces_json=split_paces_json_string
        )
        db.session.add(new_activity)
        db.session.commit()
        return jsonify({'message': 'Activity added successfully', 'activity_id': new_activity.id}), 201
    except ValueError:
        return jsonify({'message': 'Invalid date format for start_time. Use ISO format (YYYY-MM-DDTHH:MM:SS)'}), 400
    except Exception as e:
        db.session.rollback()
        return jsonify({'message': f'Error adding activity: {str(e)}'}), 500

@app.route('/activities/<int:user_id>', methods=['GET'])
def get_user_activities(user_id):
    user = User.query.get(user_id)
    if not user:
        return jsonify({'message': 'User not found'}), 404

    activities = Activity.query.filter_by(user_id=user_id).order_by(Activity.start_time.desc()).all()

    output = []
    for activity in activities:
        # Convert split_paces_json back to list/object for frontend
        split_paces = json.loads(activity.split_paces_json) if activity.split_paces_json else []

        output.append({
            'id': activity.id,
            'user_id': activity.user_id,
            'start_time': activity.start_time.isoformat(),  # Convert datetime to ISO string
            'duration_seconds': activity.duration_seconds,
            'distance_km': activity.distance_km,
            'start_latitude': activity.start_latitude,
            'start_longitude': activity.start_longitude,
            'end_latitude': activity.end_latitude,
            'end_longitude': activity.end_longitude,
            'average_pace_seconds_per_km': activity.average_pace_seconds_per_km,
            'split_paces': split_paces,
            'created_at': activity.created_at.isoformat()
        })
    return jsonify(output), 200


if __name__ == '__main__':
    # You would typically run Flask apps using `flask run` or a WSGI server like Gunicorn.
    # The `flask init-db` command should be run separately via the CLI.
    app.run(host="127.0.0.1", port="5000", debug=True)