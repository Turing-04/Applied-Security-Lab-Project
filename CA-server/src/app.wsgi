"""
See: https://flask.palletsprojects.com/en/3.0.x/deploying/mod_wsgi/
"""
import sys
SERVER_SRC_PATH = "/var/www/ca-server/src"
if SERVER_SRC_PATH not in sys.path:
    sys.path.insert(0, SERVER_SRC_PATH)

# https://stackoverflow.com/a/62097197
sys.path.insert(0,f"{SERVER_SRC_PATH}/.venv/lib/python3.11/site-packages")

from ca_server import app

application = app