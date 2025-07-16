#!/bin/bash

# Start the ADK multimodal server
echo "Starting the streaming service on port 8080..."
cd "$(dirname "$0")"
python3 streaming_service.py &
ADK_PID=$!

# Wait a moment to ensure the server starts properly
sleep 2

echo "Streaming service is now active with PID: $ADK_PID"
echo ""
echo "To stop the server, press Ctrl+C."

# Trap Ctrl+C to properly shut down server
trap "echo 'Shutting down the streaming service...'; kill $ADK_PID; exit 0" INT

# Wait until the user presses Ctrl+C
wait