import os
from flask import Flask, request, jsonify
from flask_cors import CORS
import json
from datetime import datetime
import click # Import click for custom commands
from sqlalchemy import desc, func
from flask_sqlalchemy import SQLAlchemy
import copy
import re # Import re for regular expressions to parse questionnaire answers
from datetime import datetime, timedelta

# Import db and models from database.py
from database import db, User, Activity, init_db_command, Trait
from flask_cors import CORS

# Constants for updating performance
PAST_ACCESS_ACT_NUM = 10
RATIO_UPGRADE_SPEED = 0.5
RATIO_UPGRADE_LENGTH = 0.7

# Define maximum allowed pace in seconds/km (9 min 59 sec/km)
MAX_PACE_SECONDS_PER_KM = 599

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
        if data['distance_km'] != 0 and data['average_pace_seconds_per_km'] != 0:
            update_trait_after_run(user_id)

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
            'end_latitude': activity.end_latitude,
            'end_longitude': activity.end_longitude,
            'average_pace_seconds_per_km': activity.average_pace_seconds_per_km,
            'split_paces': split_paces,
            'goal_state': activity.goal_state, # Include goal_state
            'goal_dist': activity.goal_dist,   # Include goal_dist
            'goal_pace': activity.goal_pace    # Include goal_pace
        })
    return jsonify(output), 200

@app.route('/activities/past_week/<int:user_id>', methods=['GET'])
def get_past_week_activities(user_id):
    user = User.query.get(user_id)
    if not user:
        return jsonify({'message': 'User not found'}), 404

    seven_days_ago = datetime.utcnow() - timedelta(days=7)

    activities = Activity.query.filter_by(user_id=user_id)\
        .filter(Activity.start_time >= seven_days_ago)\
        .order_by(desc(Activity.start_time)).all()

    output = [activity.to_dict() for activity in activities]
    print("📦 Returned Activities:", output)
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
        return jsonify({'message': 'Invalid date format. Use ISO-MM-DD'}), 400

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
            'end_latitude': activity.end_latitude,
            'end_longitude': activity.end_longitude,
            'average_pace_seconds_per_km': activity.average_pace_seconds_per_km,
            'split_paces': split_paces,
            'goal_state': activity.goal_state,
            'goal_dist': activity.goal_dist,
            'goal_pace': activity.goal_pace
        })
    return jsonify(output), 200


@app.route('/finish_questionare', methods=['POST'])
def finish_questionare():
    data = request.json
    user_id = int(data.get('user_id'))

    if not user_id:
        return jsonify({'error': 'Missing user_id'}), 400

    # If trait exists, delete old.
    old_trait = Trait.query.filter_by(user_id=user_id).first()
    if old_trait:
        db.session.delete(old_trait)
        db.session.commit()

    # Initialize goals with sensible defaults
    # These defaults are a starting point and will be adjusted based on answers.
    # Long-term goal: Half-marathon distance (21.0 km), 5 min/km pace (300 seconds/km), ideal weight 60kg
    long_goal = {"dist": 21.0, "pace": 300, "weight": 60.0}
    # Current goal: 5km distance, 7 min/km pace (420 seconds/km), current weight 70kg
    curr_goal = {"dist": 5.0, "pace": 420, "weight": 70.0, "freq": 3.0} # Added 'freq' with a default

    usually_quit = False
    now_quit = False # This field is typically updated by the performance logic in update_trait_after_run, not directly from questionnaire
    believe_ai = False

    # Helper function to parse additional input from answers string
    def parse_additional_input(answer_string):
        """Parses additional key=value pairs from an answer string like '(Additional: key1=val1, key2=val2)'."""
        match = re.search(r'\(Additional: (.*)\)', answer_string)
        if match:
            params_str = match.group(1)
            params = {}
            for pair in params_str.split(', '):
                key_val = pair.split('=')
                if len(key_val) == 2:
                    key, val = key_val[0], key_val[1]
                    try:
                        # Attempt to convert to float or int for numeric values
                        if key in ['distance', 'goal', 'weight']:
                            params[key] = float(val)
                        elif key == 'speed':
                            params[key] = int(val) # Speed is min/km, will be converted to seconds later
                        else:
                            params[key] = val # Keep as string if not numeric
                    except ValueError:
                        params[key] = val # Fallback to string if conversion fails
            return params
        return {}

    # --- Process answers from the questionnaire ---

    # g1: Why do you run?
    g1_answer = data.get('g1')

    # g2: Do you have a long term goal?
    g2_answer = data.get('g2')
    g2_has_specific_goal = False
    if g2_answer and g2_answer.startswith('Yes'):
        g2_has_specific_goal = True
        # User has a specific long-term goal
        g2_additional_input = parse_additional_input(g2_answer)
        if g1_answer == 'Faster speed':
            if 'distance' in g2_additional_input:
                long_goal['dist'] = g2_additional_input['distance']
            if 'speed' in g2_additional_input:
                # Convert min/km to seconds/km (e.g., 5 min/km -> 300 sec/km)
                long_goal['pace'] = int(g2_additional_input['speed'] * 60)
            long_goal['weight'] = curr_goal['weight'] # Keep current weight for speed goal unless specified
        elif g1_answer == 'Longer distance':
            if 'goal' in g2_additional_input:
                long_goal['dist'] = g2_additional_input['goal']
            # Set a reasonable default pace for longer distance goals if not explicitly given
            long_goal['pace'] = 360 # 6 min/km pace
            long_goal['weight'] = curr_goal['weight'] # Keep current weight for distance goal unless specified
        elif g1_answer == 'Healthier shape':
            if 'weight' in g2_additional_input:
                long_goal['weight'] = g2_additional_input['weight']
            # Set generic distance/pace goals for healthier shape if not specified
            long_goal['dist'] = 10.0 # A common distance for general health
            long_goal['pace'] = 420 # 7 min/km pace

    elif g2_answer == 'No':
        # User does not have a specific long-term goal, infer from g1
        if g1_answer == 'Faster speed':
            long_goal['pace'] = min(270, long_goal['pace']) # Aim for slightly faster than default (4.5 min/km)
            long_goal['dist'] = 10.0 # A good distance to work on speed
            long_goal['weight'] = curr_goal['weight'] # Keep current weight for speed goal
        elif g1_answer == 'Longer distance':
            long_goal['dist'] = max(25.0, long_goal['dist']) # Aim for longer than default (25 km)
            long_goal['pace'] = 390 # A bit slower pace for longer runs (6.5 min/km)
            long_goal['weight'] = curr_goal['weight'] # Keep current weight for distance goal
        elif g1_answer == 'Healthier shape':
            long_goal['dist'] = 10.0 # Keep general 10km goal
            long_goal['pace'] = 450 # Moderate pace (7.5 min/km)
            long_goal['weight'] = 65.0 # A general healthy weight goal

    # Determine a base current distance based on last run performance
    base_curr_dist_from_h2 = curr_goal['dist'] # Default to initialized curr_goal['dist']
    h2_answer = data.get('h2')
    if h2_answer == 'Less than 3km':
        base_curr_dist_from_h2 = 3.0
    elif h2_answer == '3~10km':
        base_curr_dist_from_h2 = 5.0
    elif h2_answer == 'More than 10km':
        base_curr_dist_from_h2 = 8.0

    # h1: How long has it been since you last ran? (Influences current goal's difficulty)
    h1_answer = data.get('h1')
    if h1_answer == 'More than a month':
        # If very long time, start with a truly short distance and slower pace
        curr_goal['dist'] = 2.0
        # Instead of always 599, use a range for "very slow" depending on other factors if any, or a more graduated step
        # For a truly new/restarting runner, 9:00-9:59 is still appropriate. Let's aim for 9:30 as a default.
        curr_goal['pace'] = 570 # 9 min 30 sec/km
        curr_goal['freq'] = 1.0 # 1 run per week suggested
    elif h1_answer == 'Within a month':
        # If some time, start with a slightly conservative distance, pace depends on h3 more
        curr_goal['dist'] = max(3.0, base_curr_dist_from_h2 * 0.75) # At least 3km, or 75% of last run if long
        curr_goal['pace'] = max(480, curr_goal['pace']) # At least 8 min/km, or existing pace
        curr_goal['freq'] = 2.0 # 2 runs per week suggested
    else: # Within a week
        curr_goal['dist'] = base_curr_dist_from_h2 # Use last run's distance as a strong indicator
        curr_goal['freq'] = 3.0 # 3 runs per week suggested
        # Pace will be refined by h3

    # Now refine curr_goal['dist'] based on relation to long_goal['dist']
    # Ensure current distance is a reasonable fraction of long-term distance if long_goal is high
    if long_goal['dist'] > 10.0 and curr_goal['dist'] < long_goal['dist'] * 0.2: # If long goal is high and current is too low
        curr_goal['dist'] = max(curr_goal['dist'], long_goal['dist'] * 0.2) # Ensure at least 20% of long goal
    # For intermediate users, if curr_goal['dist'] is significantly lower than a reasonable fraction of long_goal['dist'], adjust it upwards
    if long_goal['dist'] > 5.0 and curr_goal['dist'] < long_goal['dist'] * 0.5 and h1_answer != 'More than a month':
         curr_goal['dist'] = max(curr_goal['dist'], long_goal['dist'] * 0.3) # If active, aim for at least 30% of long goal

    # h3: How fast did you run last time? (min/km) (Adjusts current pace goal)
    h3_answer = data.get('h3')
    if h3_answer == 'Less than 5':
        curr_goal['pace'] = min(curr_goal['pace'], 270) # Aim for 4.5 min/km or faster
    elif h3_answer == '5~7':
        curr_goal['pace'] = max(curr_goal['pace'], 300) # At least 5 min/km
        curr_goal['pace'] = min(curr_goal['pace'], 420) # At most 7 min/km
    elif h3_answer == 'More than 7':
        curr_goal['pace'] = max(curr_goal['pace'], 480) # Aim for 8 min/km or slower
    # 'No idea' keeps the pace goal as is, influenced by h1/h2 and weight

    # Ensure pace does not exceed MAX_PACE_SECONDS_PER_KM and is not too slow
    long_goal['pace'] = min(long_goal['pace'], MAX_PACE_SECONDS_PER_KM)
    curr_goal['pace'] = min(curr_goal['pace'], MAX_PACE_SECONDS_PER_KM)


    # h4: What is your current weight? (Adjusts current weight goal and initial pace/distance if very heavy)
    h4_answer = data.get('h4')
    if h4_answer and h4_answer.startswith('kg'):
        h4_additional_input = parse_additional_input(h4_answer)
        if 'weight' in h4_additional_input:
            curr_goal['weight'] = h4_additional_input['weight']
            # If current weight is high, make initial distance/pace goals a bit easier, but not always 599
            if curr_goal['weight'] > 90: # Example threshold for higher weight
                curr_goal['dist'] = min(curr_goal['dist'], 3.0) # Cap initial distance
                # For high weight, aim for a slower but not the absolute slowest pace
                curr_goal['pace'] = max(curr_goal['pace'], 540) # 9 min/km pace
                curr_goal['pace'] = min(curr_goal['pace'], MAX_PACE_SECONDS_PER_KM) # Ensure within max allowed

    # m1: Have you started and quit running?
    m1_answer = data.get('m1')
    if m1_answer == 'Yes':
        usually_quit = True
    elif m1_answer == 'No':
        usually_quit = False

    # m2: Do you believe in the idea: "Don't think. Just run as AI tells you"?
    m2_answer = data.get('m2')
    if m2_answer == 'Yes':
        believe_ai = True
    elif m2_answer == 'No':
        believe_ai = False

    # Final consistency checks to ensure curr_goal is not harder than long_goal
    # Current distance should be less than or equal to long-term distance
    curr_goal['dist'] = min(curr_goal['dist'], long_goal['dist'])
    # Current pace should be slower than or equal to long-term pace (higher seconds/km means slower)
    curr_goal['pace'] = max(curr_goal['pace'], long_goal['pace'])
    # Current weight should be higher than or equal to long-term target weight
    curr_goal['weight'] = max(curr_goal['weight'], long_goal['weight'])
    
    # Ensure current pace does not exceed the overall MAX_PACE_SECONDS_PER_KM
    curr_goal['pace'] = min(curr_goal['pace'], MAX_PACE_SECONDS_PER_KM)

    # Determine user_type based on initial questionnaire responses
    user_type = "Beginner"
    if h1_answer == 'Within a week' and h3_answer != 'No idea':
        user_type = "Intermediate"
        if h3_answer == 'Less than 5' or long_goal['pace'] < 300: # 5 min/km
            user_type = "Advanced"
    elif h1_answer == 'More than a month' and usually_quit:
        user_type = "Returning"
    elif g1_answer == 'Healthier shape' and curr_goal['weight'] > 80: # Example for weight-focused users
        user_type = "WeightLossFocus"
    # You can add more complex logic here to define user_type

    # Create Trait instance
    trait = Trait(
        user_id=user_id,
        long_goal=long_goal,
        curr_goal=curr_goal,
        usually_quit=usually_quit,
        now_quit=now_quit,
        believe_ai=believe_ai,
        user_type=user_type # Store the determined user type
    )
    # Save to database
    db.session.add(trait)
    db.session.commit()

    return jsonify({'message': 'Trait created successfully'}), 201


def update_trait_after_run(user_id):
    trait = Trait.query.filter_by(user_id=user_id).first()
    if not trait or not trait.curr_goal:
        return

    original_goal = copy.deepcopy(trait.curr_goal) # Use deepcopy to keep original for comparison
    new_goal = trait.curr_goal
    curr_goal_pace = new_goal['pace']
    curr_goal_dist = new_goal['dist']

    long_goal_pace = trait.long_goal['pace']
    long_goal_dist = trait.long_goal['dist']

    if curr_goal_pace is None or curr_goal_dist is None:
        return

    # Fetch recent activities
    activities = Activity.query.filter_by(user_id=user_id)\
        .order_by(desc(Activity.start_time)).limit(PAST_ACCESS_ACT_NUM).all()

    if not activities:
        return

    faster_count = []
    longer_count = []

    for act in activities:
        if act.average_pace_seconds_per_km and act.distance_km:
            if act.average_pace_seconds_per_km < curr_goal_pace: # Faster means lower pace value
                faster_count.append(1)
            else:
                faster_count.append(0)
            if act.distance_km >= curr_goal_dist: # Longer means greater or equal distance
                longer_count.append(1)
            else:
                longer_count.append(0)

    # Adjusting Algorithm
    # Upgrade conditions
    # Pace
    if (sum(faster_count) / len(faster_count) >= RATIO_UPGRADE_SPEED) and (faster_count[0] == 1):
        # If today completed and success rate more than RATIO_UPGRADE_SPEED.
        # Reduce 15s until long-term goal is achieved.
        new_goal['pace'] = max(curr_goal_pace - 15, long_goal_pace)
    # Distance
    if (sum(longer_count) / len(longer_count) >= RATIO_UPGRADE_LENGTH) and (longer_count[0] == 1):
        # If today completed and success rate more than RATIO_UPGRADE_LENGTH.
        # Add 1km until long-term goal is achieved.
        new_goal['dist'] = min(round(curr_goal_dist + 1.0, 1), long_goal_dist)

    # Downgrade conditions
    # Pace
    # If fail continuously, be downgraded gradually.
    consecutive_failures_pace = 0
    for i in faster_count:
        if(i == 0): consecutive_failures_pace += 1
        else: break
    if(consecutive_failures_pace > 1):
        # Increase pace (slower) by 10s for each consecutive failure after the first
        new_goal['pace'] = min(curr_goal_pace + (consecutive_failures_pace - 1) * 10, MAX_PACE_SECONDS_PER_KM) # Cap at 9 min 59 sec/km

    # Distance
    # If fail continuously, be downgraded gradually.
    consecutive_failures_dist = 0
    for i in longer_count:
        if(i == 0): consecutive_failures_dist += 1
        else: break
    if(consecutive_failures_dist > 1):
        # Decrease distance by 0.5km for each consecutive failure after the first
        new_goal['dist'] = max(curr_goal_dist - (consecutive_failures_dist - 1) * 0.5, 1.0) # Minimum 1km

    print(f"Original Goal: {original_goal}, New Goal: {new_goal}")
    db.session.commit()

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
    
@app.route('/user_type/<int:user_id>', methods=['GET'])
def get_user_type(user_id):
    user = User.query.get(user_id)
    if not user:
        return jsonify({'message': 'User not found'}), 404

    trait = Trait.query.filter_by(user_id=user_id).first()
    if not trait:
        return jsonify({'message': 'Trait not found'}), 404

    weight = None
    freq = None # Initialize freq
    if trait.curr_goal and isinstance(trait.curr_goal, dict):
        weight = trait.curr_goal.get('weight')
        freq = trait.curr_goal.get('freq') # Retrieve freq

    return jsonify({
        'user_type': trait.user_type,
        'weight': weight,
        'freq': freq
    }), 200
    

if __name__ == '__main__':
    # Use Power Shell：run_server.ps1
    # Use CMD         ：run_backend.bat 

    # For Local 
    app.run(host="127.0.0.1", port="5000", debug=True)
    # For Workshop
    # app.run(debug=True)
