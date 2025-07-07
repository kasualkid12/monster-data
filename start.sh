#!/bin/bash

# Startup script for Monster Data
# Set FLASK_ENV=production to use Gunicorn, otherwise uses Flask dev server

if [ "$FLASK_ENV" = "production" ]; then
    echo "Starting production server with Gunicorn..."
    exec gunicorn -c gunicorn.conf.py app:app
else
    echo "Starting development server with Flask..."
    exec python app.py
fi 