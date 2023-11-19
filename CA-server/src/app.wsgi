"""
See: https://flask.palletsprojects.com/en/3.0.x/deploying/mod_wsgi/
"""
import sys
server_path = "/var/www/ca-server/src"
if server_path not in sys.path:
    sys.path.insert(0, server_path)

# https://stackoverflow.com/a/62097197
sys.path.insert(0,"/var/www/ca-server/src/.venv/lib/python3.11/site-packages")

from ca_server import app

application = app