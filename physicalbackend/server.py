import os
from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from werkzeug.security import generate_password_hash, check_password_hash
from datetime import datetime
import json
import click # Import click for custom commands
from flask_cors import CORS
from sqlalchemy.dialects.postgresql import JSON

# cd \Hackathon_Physical_app\physicalbackend
# set FLASK_APP=server.py
# flask init-db
# python server.py

# Initialize Flask app
app = Flask(__name__)
CORS(app)

# Database Configuration
# Use PostgreSQL for production, SQLite for development for simplicity
# Example for PostgreSQL: 'postgresql://user:password@host:port/database_name'
app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get('DATABASE_URL', 'sqlite:///site.db')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)


# --- Database Models ---
class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    password_hash = db.Column(db.String(128), nullable=False)
    third_party_id = db.Column(db.String(128), unique=True, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    # Establish a relationship with Activity.
    # 'backref' adds a .user property to Activity objects
    activities = db.relationship('Activity', backref='user', lazy=True)

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

    def __repr__(self):
        return f'<User {self.username}>'


class Activity(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    start_time = db.Column(db.DateTime, nullable=False)
    duration_seconds = db.Column(db.Integer, nullable=False)
    distance_km = db.Column(db.Float, nullable=False)
    start_latitude = db.Column(db.Float, nullable=True)
    start_longitude = db.Column(db.Float, nullable=True)
    end_latitude = db.Column(db.Float, nullable=True)
    end_longitude = db.Column(db.Float, nullable=True)
    average_pace_seconds_per_km = db.Column(db.Integer, nullable=False)
    # Using db.Text to store JSON string. For PostgreSQL, consider JSONB.
    split_paces_json = db.Column(db.Text, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def __repr__(self):
        return f'<Activity {self.id} for User {self.user_id}>'

class Trait(db.Model):
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    catagory = db.Colum(db.Text, default='healthy') # fast, long, healthy
    goal = db.Column(JSON, nullable=True)
    current = db.Column(JSON, nullable=True)
    
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

# @app.route('/goal', methods=['GET'])
# def goal():
#     data = request.get_json()  # 從 JSON 取得資料
#     if not data:
#         return jsonify({'error': 'No JSON data received'}), 400

#     new_goal = Activity(
#         user_id = data.request.get('user_id'),
#         start_time = db.Column(db.DateTime, nullable=False)
#         duration_seconds = db.Column(db.Integer, nullable=False)
#         distance_km = db.Column(db.Float, nullable=False)
#         average_pace_seconds_per_km = db.Column(db.Integer, nullable=False)
#         # Using db.Text to store JSON string. For PostgreSQL, consider JSONB.
#         split_paces_json = db.Column(db.Text, nullable=True)
#         created_at = db.Column(db.DateTime, default=datetime.utcnow)
#     )
    
#     # 示範資料處理（你可以根據需要儲存進資料庫）
#     goal_name = data.get('name')
#     score = data.get('score')
#     status = data.get('status')

#     # 印出收到的資料（開發除錯用）
#     print(f"Received goal: name={goal_name}, score={score}, status={status}")

#     # 回傳收到的資料
#     return jsonify({
#         'message': 'Goal received successfully',
#         'data': data
#     }), 200

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

# --- Custom Flask CLI Command for Database Initialization ---
@app.cli.command("init-db")
def init_db_command():
    """Clear existing data and create new tables."""
    db.drop_all() # Optional: Use with caution, it deletes all data!
    db.create_all()
    click.echo("Initialized the database.")

@app.route('/first_login', methods=['POST'])
def first_login():
    data = request.json
    user_id = data.get('user_id')

    if not user_id:
        return jsonify({'error': 'Missing user_id'}), 400

    # 從資料庫撈該使用者的所有紀錄
    activities = Activity.query.filter_by(user_id=user_id).all()

    if not activities:
        return jsonify({'error': 'No activities found'}), 404

    # 計算總距離與總時間
    total_distance = sum([a.distance_km for a in activities])
    total_time = sum([a.time_minute for a in activities])

    avg_pace = total_time / total_distance if total_distance > 0 else 0

    return jsonify({
        'total_distance_km': round(total_distance, 2),
        'total_time_min': round(total_time, 2),
        'average_pace_min_per_km': round(avg_pace, 2)
    })

@app.route('/run_complete', methods=['POST'])
def run_complete():
    data = request.json
    user_id = data.get('user_id')

    if not user_id:
        return jsonify({'error': 'Missing user_id'}), 400

    # 從資料庫撈該使用者的所有紀錄
    activities = Activity.query.filter_by(user_id=user_id).all()

    if not activities:
        return jsonify({'error': 'No activities found'}), 404

    # 計算總距離與總時間
    total_distance = sum([a.distance_km for a in activities])
    total_time = sum([a.time_minute for a in activities])

    avg_pace = total_time / total_distance if total_distance > 0 else 0

    return jsonify({
        'total_distance_km': round(total_distance, 2),
        'total_time_min': round(total_time, 2),
        'average_pace_min_per_km': round(avg_pace, 2)
    })

if __name__ == '__main__':
    # Removed db.create_all() from here, as it's now handled by the CLI command
    app.run(host="127.0.0.1", port="5000", debug=True)