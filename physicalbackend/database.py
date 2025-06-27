# database.py
from flask_sqlalchemy import SQLAlchemy
from werkzeug.security import generate_password_hash, check_password_hash
from datetime import datetime
from sqlalchemy.dialects.postgresql import JSON
from sqlalchemy.ext.mutable import MutableDict
import json

# Initialize SQLAlchemy outside of app context for flexibility
db = SQLAlchemy()

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
    end_latitude = db.Column(db.Float, nullable=True)
    end_longitude = db.Column(db.Float, nullable=True)
    average_pace_seconds_per_km = db.Column(db.Integer, nullable=False)
    # Using db.Text to store JSON string. For PostgreSQL, consider JSONB.
    split_paces_json = db.Column(db.Text, nullable=True)
    goal_state = db.Column(db.String, nullable=True)
    goal_dist = db.Column(db.Float, nullable=True)
    goal_pace = db.Column(db.Integer, nullable=True)
    
    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'start_time': self.start_time.isoformat(),  # datetime → string
            'duration_seconds': self.duration_seconds,
            'distance_km': self.distance_km,
            'end_latitude': self.end_latitude,
            'end_longitude': self.end_longitude,
            'average_pace_seconds_per_km': self.average_pace_seconds_per_km,
            'split_paces_json': json.loads(self.split_paces_json) if self.split_paces_json else None,
            'goal_state': self.goal_state,
            'goal_dist': self.goal_dist,
            'goal_pace': self.goal_pace,
        }

    def __repr__(self):
        return f'<Activity {self.id} for User {self.user_id}>'

def init_db_command():
    """Clear existing data and create new tables."""
    # db.drop_all() # Optional: Use with caution, it deletes all data!
    db.create_all()
    print("Initialized the database.")
        
class Trait(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False, unique=True)
    user_type = db.Column(db.String, nullable=True)
    long_goal = db.Column(MutableDict.as_mutable(JSON), nullable=True)
    curr_goal = db.Column(MutableDict.as_mutable(JSON), nullable=True)
    # ex 
    # goal = {
    #   "dist": 5.0, 
    #   "pace": 300,
    #   "weight": 60
    # }

    # current = {
    #   "dist": 5.0,  km
    #   "pace": 300,  s/km
    #   "weight": 60, kg
    #   "freq": 3.0         days between run
    # }
    usually_quit = db.Column(db.Boolean, default=False)
    now_quit = db.Column(db.Boolean, default=False)
    believe_ai = db.Column(db.Boolean, default=True)
  
class Analysis(db.Model):  
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False, unique=True)
    user_type = db.Column(db.String, nullable=True)
    done_week = db.Column(JSON, nullable=True)
    # done_week = {
    #   "round_week": 3,
    #   "dist_week": 5.0, 
    #   "avg_pace_week": 300,
    #   "complete_week": 0.5
    # }
    weight_praise_flag = db.Column(db.Boolean, default=False)  
    add_dist_flag = db.Column(db.Boolean, default=False)      
    weight_praise = db.Column(JSON, nullable=True)
    # done_week = {
    #   "add_dist": 0.5,
    #   "exp_weight_drop": 1
    # }
    time = db.Column(db.Integer, default=0)
    habit_level = db.Column(db.Integer, default=0)  
