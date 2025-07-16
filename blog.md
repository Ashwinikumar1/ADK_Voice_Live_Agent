# Rethinking Voice AI: A Practical Guide to Building Assistants with Gemini 2.5's Native Audio

For years, the blueprint for voice assistants has been the same: a rigid, three-step dance of Speech-to-Text (STT), Large Language Model (LLM) processing, and finally, Text-to-Speech (TTS). This pipeline, while functional, is clumsy. The noticeable lag, the robotic cadence, and the inability to grasp emotional nuance are all symptoms of a system that's translating, not truly understanding.

The traditional approach creates a bottleneck, adding latency and stripping the conversation of its natural flow. Gemini 2.5 Flash with native audio processing changes the game.

By processing audio end-to-end in a single, unified model, Gemini eliminates the clumsy shuffle, resulting in a fluid, low-latency interaction that feels less like a command-and-response and more like a genuine conversation.

## The Native Audio Advantage (In Brief)

*   **Natural Conversation:** Experience remarkably fluid, low-latency interactions with appropriate expressivity and rhythm.
*   **Powerful Tool Integration:** The model can use tools like Google Search or your own custom functions during a live conversation to fetch real-time information.
*   **Audio-Video Understanding:** Go beyond voice. Converse with the AI about what it sees via a live video feed or screen sharing.
*   **Affective & Context-Aware Dialog:** The AI responds to your tone of voice and intelligently ignores background noise, understanding when to speak and when to listen.

## Building NaviGo AI: A Step-by-Step Guide

Let's walk through how to build "NaviGo AI," a voice-first AI travel agent, using the Google Agent Development Kit (ADK) and a simple web interface.

### Part 1: The Backend Agent (`streaming_service.py`)

The Python backend uses WebSockets to manage the real-time conversation stream with the browser.

#### Step 1.1: Define the Agent and Its Tools

First, we instantiate an `Agent`, defining its "NaviGo AI" persona via a system instruction and equipping it with tools for web search and Google Maps.

```python
# From streaming_service.py

# Your Google Maps API key is needed for the MCPToolset
maps_api_key = os.environ.get("GOOGLE_MAPS_API_KEY")

self.agent = Agent(
    name="voice_assistant_agent",
    model=MODEL, # "gemini-2.5-flash-preview-native-audio-dialog"
    instruction=SYSTEM_INSTRUCTION, # Defines the "NaviGo AI" persona
    tools=[
        google_search,
        MCPToolset( # Google Maps tool
            connection_params=StdioServerParameters(
                command='npx',
                args=["-y", "@modelcontextprotocol/server-google-maps"],
                env={"GOOGLE_MAPS_API_KEY": maps_api_key}
            ),
        )
    ],
)
```

** Supercharging the Agent with Tools**

Defining the agent is just the start. The real power comes from the tools we provide. This is what transforms our voice model from a conversationalist into a capable assistant. By integrating tools, the agent can break out of its pre-trained knowledge and interact with the real world in real-time.

Our NaviGo agent is equipped with two powerful tools:

*   **Google Search (`google_search`):** This is the agent's window to the world. It gives NaviGo the ability to look up anything on the web during the conversation.
*   **Google Maps (`MCPToolset`):** For a travel agent, this tool is indispensable. It connects the agent directly to Google Maps' powerful APIs.

#### Step 1.2: Configure the Live Session

The `RunConfig` object tells the agent how to handle the stream. We configure it for bidirectional (BIDI) audio, specify that we want audio responses, and request transcriptions for both what the user says and what the model speaks.

```python
# From streaming_service.py

run_config = RunConfig(
    streaming_mode=StreamingMode.BIDI, # Bidirectional streaming
    speech_config=types.SpeechConfig(
        voice_config=types.VoiceConfig(
            prebuilt_voice_config=types.PrebuiltVoiceConfig(
                voice_name=VOICE_NAME # e.g., "Puck"
            )
        )
    ),
    response_modalities=["AUDIO"], # We want audio back from the model
    output_audio_transcription=types.AudioTranscriptionConfig(),
    input_audio_transcription=types.AudioTranscriptionConfig(),
)
```

#### Step 1.3: Handle the Real-time Data Flow

We use an `asyncio.TaskGroup` to run multiple tasks concurrently, ensuring we can send and receive data simultaneously without blocking. This architecture is key to a low-latency experience.

```python
# From streaming_service.py

async with asyncio.TaskGroup() as tg:
    # Task 1: Listens for audio messages from the browser client
    tg.create_task(receive_client_messages(), name="ClientMessageReceiver")
    
    # Task 2: Sends audio from the client to the Gemini service
    tg.create_task(send_audio_to_service(), name="AudioSender")
    
    # Task 3: Listens for responses from the Gemini service
    tg.create_task(receive_service_responses(), name="ServiceResponseReceiver")
```

#### Step 1.4: Process Streaming Responses

In `receive_service_responses`, we iterate through events from the agent. A key challenge in streaming is handling partial responses to avoid duplicating text on the frontend. We check a flag in the event string to process only the final streaming chunks of text.

```python
# From streaming_service.py, inside receive_service_responses

async for event in runner.run_live(...):
    event_str = str(event) # For checking partial flags

    if event.content and event.content.parts:
        for part in event.content.parts:
            # Handle audio output from the model
            if hasattr(part, "inline_data") and part.inline_data:
                b64_audio = base64.b64encode(part.inline_data.data).decode("utf-8")
                await websocket.send(json.dumps({"type": "audio", "data": b64_audio}))

            # Handle text output
            if hasattr(part, "text") and part.text:
                if "partial=True" in event_str: # Check for streaming chunks
                    await websocket.send(json.dumps({"type": "text", "data": part.text}))
    
    # Let the client know when the model is done with its turn
    if event.turn_complete:
        await websocket.send(json.dumps({"type": "turn_complete"}))
```

### Part 2: The Frontend Client (`interface.html` & `sound_handler.js`)

The frontend captures microphone audio and plays back the agent's spoken response.

#### Step 2.1: Connecting to the Server

The client connects to the WebSocket server using the URL provided to the `StreamManager` constructor.

```javascript
// From interface.html

const stream = new StreamManager('ws://localhost:8765');
```

#### Step 2.2: Capture and Send User Audio

When the user clicks the mic button, `sound_handler.js` uses a `ScriptProcessorNode` to capture raw audio. Each chunk is converted from the browser's 32-bit float format to the 16-bit PCM format the model expects, Base64 encoded, and sent to the server via WebSocket.

```javascript
// From sound_handler.js

processor.onaudioprocess = (e) => {
    if (!this.isRecording) return;

    const inputData = e.inputBuffer.getChannelData(0);

    // Convert float32 to int16
    const int16Data = new Int16Array(inputData.length);
    for (let i = 0; i < inputData.length; i++) {
        int16Data[i] = Math.max(-32768, Math.min(32767, Math.floor(inputData[i] * 32768)));
    }

    const audioBuffer = new Uint8Array(int16Data.buffer);
    const base64Audio = this._arrayBufferToBase64(audioBuffer);

    // Send the audio chunk to the server
    this.ws.send(JSON.stringify({
        type: 'audio',
        data: base64Audio
    }));
};
```

#### Step 2.3: Ensure Smooth Audio Playback

To avoid choppy audio, incoming audio chunks from the server are added to a queue. The `playNext` function plays them sequentially using the Web Audio API, creating a smooth, uninterrupted stream of speech.

```javascript
// From sound_handler.js

async playSound(base64Audio) {
    // Decode and add the new audio data to the queue
    const audioData = this._base64ToArrayBuffer(base64Audio);
    this.audioQueue.push(audioData);

    // If not already playing, start the playback process
    if (!this.isPlaying) {
        this.playNext();
    }
}

playNext() {
    if (this.audioQueue.length === 0) {
        this.isPlaying = false;
        return;
    }

    this.isPlaying = true;
    const audioData = this.audioQueue.shift(); // Get next chunk from queue

    // ... code to decode and play the audioData using Web Audio API ...

    source.onended = () => {
        this.playNext(); // When one chunk finishes, play the next
    };

    source.start(0);
}
```

#### Step 2.4: Wire Events to the UI

Finally, in `interface.html`, we set up event listeners on our `stream` object. These listeners take the data received from the server and use the `updateTranscript` function to dynamically render the conversation in the browser, providing a complete, interactive experience.

```javascript
// From interface.html

stream.onUserTranscript = (text) => {
    if (text && text.trim()) {
        updateTranscript(text, 'user', true); // Display partial user transcript
    }
};

stream.onTextReceived = (text) => {
    if (text && text.trim()) {
        currentResponseText += text;
        updateTranscript(currentResponseText, "assistant", true); // Update assistant's partial response
    }
};

stream.onTurnComplete = () => {
    // Mark the last message as complete
    const lastMessage = transcriptContainer.lastElementChild;
    if (lastMessage && lastMessage.dataset.partial === 'true') {
        delete lastMessage.dataset.partial;
    }
};
```

## Get Started

This guide provides a practical walkthrough for building a real-time voice assistant using the Google Agent Development Kit (ADK). The complete source code for this project, along with official documentation, is available at the links below.

*   Project Source Code
*   Official Google AI Documentation
*   Google ADK Sample Projects
