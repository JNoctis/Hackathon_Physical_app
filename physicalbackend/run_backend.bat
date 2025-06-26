@echo off
REM 導航到後端目錄
cd /d C:\Users\853uj\VSproject\Hackathon_Physical_app\physicalbackend

echo Setting FLASK_APP environment variable...
set FLASK_APP=server.py

echo Initializing database... (This will drop existing data if uncommented in init_db_command)
flask init-db

echo Starting Flask server...
python server.py

pause