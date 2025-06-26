# database.py
from flask_sqlalchemy import SQLAlchemy
from werkzeug.security import generate_password_hash, check_password_hash
from datetime import datetime
from sqlalchemy.dialects.postgresql import JSON

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

def init_db_command():
    """Clear existing data and create new tables."""
    db.drop_all() # Optional: Use with caution, it deletes all data!
    db.create_all()
    print("Initialized the database.")
        
class Trait(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False, unique=True)
    long_goal = db.Column(JSON, nullable=True)
    curr_goal = db.Column(JSON, nullable=True)
    # ex 
    # goal = {
    #   "length": 5000,
    #   "speed": 10,
    #   "weight": 60
    # }

    # current = {
    #   "length": 3000,
    #   "speed": 8,
    #   "weight": 65
    # }
    usually_quit = db.Column(db.Boolean, default=False)
    now_quit = db.Column(db.Boolean, default=False)
    believe_ai = db.Column(db.Boolean, default=True)
    

    def __repr__(self):
        return f'<Activity {self.id} for User {self.user_id}>'
