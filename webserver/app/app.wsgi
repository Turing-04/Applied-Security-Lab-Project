"""
See: https://flask.palletsprojects.com/en/3.0.x/deploying/mod_wsgi/
"""
import sys
SERVER_SRC_PATH = "/var/www/webserver/app"
if SERVER_SRC_PATH not in sys.path:
    sys.path.insert(0, SERVER_SRC_PATH)

sys.path.insert(0,f"{SERVER_SRC_PATH}/.venv/lib/python3.11/site-packages")

from app import app

application = app
