# Real-Time Voice Assistant with Google ADK

This project implements a real-time, multimodal voice assistant using the Google Assistant "Diamond" Kit (ADK). It features a Python-based server that handles audio and video streaming, and a web-based client for user interaction.

## Features

- **Real-Time Audio Streaming**: Captures microphone input and streams it to the server for processing.
- **Multimodal Capabilities**: Supports both audio and video data streams.
- **Google ADK Integration**: Leverages the Google ADK for conversational AI, including speech-to-text and text-to-speech.
- **Function Calling**: Integrated with Google Maps for location-based queries.
- **Web-Based Client**: Simple HTML and JavaScript client for interacting with the assistant.

## Project Structure

```
.
├── client/
│   ├── interface.html       # The main HTML file for the client UI
│   ├── sound_handler.js     # Manages audio playback
│   └── stream_manager.js    # Handles WebSocket connection and data streaming
├── server/
│   ├── streaming_service.py # Main Python server using WebSockets and Google ADK
│   ├── core_utils.py        # Core utilities and configurations
│   ├── requirements.txt     # Python dependencies
│   └── start_servers.sh     # Script to start the server
└── README.md                # This file
```

## Setup and Installation

### Prerequisites

- Python 3.8+
- `pip` for package management
- An active Google Cloud project with the required APIs enabled.

### 1. Set Up Environment Variables

Create a `.env` file in the `server/` directory and add your Google Maps API key:

```
GOOGLE_MAPS_API_KEY="YOUR_API_KEY_HERE"
```

### 2. Install Dependencies

It is recommended to use a virtual environment to manage the project's dependencies.

```bash
# Navigate to the server directory
cd server

# Create a virtual environment
python3 -m venv .venv

# Activate the virtual environment
# On macOS and Linux:
source .venv/bin/activate
# On Windows:
# .\.venv\Scripts\activate

# Install the required Python packages
pip install -r requirements.txt
```

## Running the Application

1.  **Start the Server**:
    Open a terminal, navigate to the `server/` directory, and run the start script:

    ```bash
    cd server
    ./start_servers.sh
    ```

    The server will start on `http://localhost:8080`.

2.  **Open the Client**:
    Open the [`client/interface.html`](client/interface.html) file in your web browser. The client will automatically connect to the WebSocket server.

3.  **Interact with the Assistant**:
    - Click the "Start Streaming" button to begin capturing audio.
    - The assistant will respond with both text and audio.

## Configuration

- **Server Port**: The WebSocket server port can be configured in [`server/streaming_service.py`](server/streaming_service.py). The default is `8080`.
- **Google ADK Model**: The model and voice settings can be adjusted in [`server/core_utils.py`](server/core_utils.py).
