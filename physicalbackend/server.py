# server.py
import os
from flask import Flask, request, jsonify
from flask_cors import CORS
import json
from datetime import datetime
import click # Import click for custom commands
from sqlalchemy import desc, func # Import func for date filtering
import copy

# Import db and models from database.py
from database import db, User, Activity, init_db_command, Trait
from flask_cors import CORS

# Constants for updating performance
PAST_ACCESS_ACT_NUM = 10
RATIO_UPDATE_SPEED = 0.5
RATIO_UPDATE_LENGTH = 0.7

# Initialize Flask app
app = Flask(__name__)
CORS(app) # Enable CORS for all routes

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

# add one act at once
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
            # 不再從請求中獲取 start_latitude 和 start_longitude，因為模型中沒有它們
            end_latitude=data.get('end_latitude'),
            end_longitude=data.get('end_longitude'),
            average_pace_seconds_per_km=data['average_pace_seconds_per_km'],
            split_paces_json=split_paces_json_string,
            goal_state = data.get('goal_state'),
            goal_dist = data.get('goal_dist'),
            goal_pace = data.get('goal_pace')
        )
        db.session.add(new_activity)
        db.session.commit()
        # update goal
        update_trait_after_run()
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
            # 移除回傳 start_latitude 和 start_longitude
            'end_latitude': activity.end_latitude,
            'end_longitude': activity.end_longitude,
            'average_pace_seconds_per_km': activity.average_pace_seconds_per_km,
            'split_paces': split_paces,
            # 移除 'created_at'，因為 Activity 模型中沒有這個欄位
            # 'created_at': activity.created_at.isoformat() if activity.created_at else None, 
            'goal_state': activity.goal_state, # Include goal_state
            'goal_dist': activity.goal_dist,   # Include goal_dist
            'goal_pace': activity.goal_pace    # Include goal_pace
        })
    return jsonify(output), 200

# NEW API: Get activities for a specific user and date
@app.route('/activities_by_date/<int:user_id>/<string:date_str>', methods=['GET'])
def get_activities_by_date(user_id, date_str):
    user = User.query.get(user_id)
    if not user:
        return jsonify({'message': 'User not found'}), 404

    try:
        # Parse the date string into a datetime object for comparison
        # Assuming date_str is in 'YYYY-MM-DD' format
        target_date = datetime.strptime(date_str, '%Y-%m-%d').date()
    except ValueError:
        return jsonify({'message': 'Invalid date format. Use YYYY-MM-DD'}), 400

    # Query activities for the specific user and date
    activities = Activity.query.filter(
        Activity.user_id == user_id,
        func.date(Activity.start_time) == target_date
    ).order_by(Activity.start_time.desc()).all()

    output = []
    for activity in activities:
        split_paces = json.loads(activity.split_paces_json) if activity.split_paces_json else []

        output.append({
            'id': activity.id,
            'user_id': activity.user_id,
            'start_time': activity.start_time.isoformat(),
            'duration_seconds': activity.duration_seconds,
            'distance_km': activity.distance_km,
            # 移除回傳 start_latitude 和 start_longitude
            'end_latitude': activity.end_latitude,
            'end_longitude': activity.end_longitude,
            'average_pace_seconds_per_km': activity.average_pace_seconds_per_km,
            'split_paces': split_paces,
            # 移除 'created_at'，因為 Activity 模型中沒有這個欄位
            # 'created_at': activity.created_at.isoformat() if activity.created_at else None, 
            'goal_state': activity.goal_state,
            'goal_dist': activity.goal_dist,
            'goal_pace': activity.goal_pace
        })
    return jsonify(output), 200


@app.route('/finish_questionare', methods=['POST'])
def finish_questionare():
    data = request.json
    user_id = data.get('user_id')

    if not user_id:
        return jsonify({'error': 'Missing user_id'}), 400

    # 防止重複建立 Trait
    if Trait.query.filter_by(user_id=user_id).first():
        return jsonify({'message': 'Trait already exists'}), 409

    # 擷取問卷資料
    long_goal = data.get('long_goal', {})
    curr_goal = data.get('curr_goal', {})
    usually_quit = data.get('usually_quit', False)
    now_quit = data.get('now_quit', False)
    believe_ai = data.get('believe_ai', True)

    # 建立 Trait 實例
    trait = Trait(
        user_id=user_id,
        long_goal=long_goal,
        curr_goal=curr_goal,
        usually_quit=usually_quit,
        now_quit=now_quit,
        believe_ai=believe_ai
    )

    # 儲存到資料庫
    db.session.add(trait)
    db.session.commit()

    return jsonify({'message': 'Trait created successfully'}), 201



@app.route('/update_trait_after_run', methods=['POST'])
def update_trait_after_run():
    data = request.json
    user_id = data.get('user_id')

    if not user_id:
        return jsonify({'error': 'Missing user_id'}), 400

    trait = Trait.query.filter_by(user_id=user_id).first()
    if not trait or not trait.curr_goal:
        return jsonify({'error': 'Trait or curr_goal not found'}), 404

    curr_goal = copy.deepcopy(trait.curr_goal)
    curr_speed_sec = curr_goal.get("speed") * 60  # 使用秒來比對（speed 是 min/km）
    curr_length = curr_goal.get("length")  # 單位：km

    if curr_speed_sec is None or curr_length is None:
        return jsonify({'error': 'curr_goal missing speed or length'}), 400

    # 抓最近 n 次活動
    activities = Activity.query.filter_by(user_id=user_id)\
        .order_by(desc(Activity.start_time)).limit(PAST_ACCESS_ACT_NUM).all()

    if not activities:
        return jsonify({'message': 'No recent activities'}), 200

    faster_count = 0
    longer_count = 0

    for act in activities:
        if act.average_pace_seconds_per_km and act.distance_km:
            if act.average_pace_seconds_per_km < curr_speed_sec:
                faster_count += 1
            if act.distance_km >= curr_length:
                longer_count += 1

    updated = False

    if faster_count / len(activities) >= RATIO_UPDATE_SPEED:
        print(faster_count / len(activities))
        new_speed = curr_goal["speed"] - 30  # 減少 30 秒（0.5 分）
        curr_goal["speed"] = max(new_speed, 160)  # 不讓配速過快
        updated = True

    if longer_count / len(activities) >= RATIO_UPDATE_LENGTH:
        curr_goal["length"] = round(curr_goal["length"] + 1.0, 1)
        updated = True

    if updated:
        print (trait.curr_goal, curr_goal)
        trait.curr_goal = curr_goal
        db.session.commit()
        return jsonify({
            'message': 'Trait updated',
            'updated_curr_goal': trait.curr_goal
        }), 200
    else:
        return jsonify({'message': 'No update needed'}), 200

# get today goal
@app.route('/goal/<int:user_id>', methods=['GET'])
def get_goal(user_id):
    user = User.query.get(user_id)
    if not user:
        return jsonify({'message': 'User not found'}), 404

    goal = Trait.query.filter_by(user_id=user_id).first()

    if goal and goal.curr_goal:
        dist = goal.curr_goal.get('dist', -1)
        pace = goal.curr_goal.get('pace', -1)
    else:
        # if not finish questionare
        dist = -1
        pace = -1

    return jsonify({
        'goal_dist': dist,
        'goal_pace': pace
    }), 200

if __name__ == '__main__':
    # Use Power Shell：run_server.ps1
    # Use CMD         ：run_backend.bat 

    # For Local 
    app.run(host="127.0.0.1", port="5000", debug=True)
    # For Workshop
    # app.run(debug=True)
