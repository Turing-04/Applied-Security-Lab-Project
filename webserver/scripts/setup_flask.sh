#!/bin/bash

# setup flask webserver

FLASK_DIR="/var/www/webserver"

cd $FLASK_DIR/app

# Create a virtual environment for the flask app
python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install -r requirements.txt

# start the flask app
# python3 app.py
# Should probably be run with gunicorn or something similar

# migt also need to generate secret session key for the flask app
export SECRET_KEY=$(python3 -c 'import os; print(os.urandom(16))')

echo "Python virtual environment created and flask app ready"