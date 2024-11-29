import os
import sys
import json
import logging
from channels.generic.websocket import AsyncWebsocketConsumer
from QuickAgent.QuickAgent import LanguageModelProcessor, get_audio_data
import asyncio
from dotenv import load_dotenv
from deepgram import DeepgramClient, DeepgramClientOptions, LiveTranscriptionEvents, LiveOptions
import websockets, ssl
import requests
import threading
# Configure logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

load_dotenv()

DEEPGRAM_API_KEY = os.getenv("DEEPGRAM_API_KEY")
print(f"DEEPGRAM_API_KEY: {DEEPGRAM_API_KEY}")
DEEPGRAM_WEBSOCKET_URL = f"wss://api.deepgram.com/v1/listen"
DEEPGRAM_API_URL = "https://api.deepgram.com/v1/listen"

HEADERS = {
    "Authorization": f"Token {DEEPGRAM_API_KEY}",
    "Content-Type": "audio/wav"  # Change this according to the format you're using
}


from deepgram import (
    DeepgramClient,
    DeepgramClientOptions,
    LiveTranscriptionEvents,
    LiveOptions,
)

class ChatConsumer(AsyncWebsocketConsumer):

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        

    async def connect(self):
        logger.debug("WebSocket connection attempt.")
        self.llm_processor = LanguageModelProcessor()
        await self.accept()
        logger.debug("WebSocket connection accepted.")
        await self.send(text_data=json.dumps({'type': 'Connection Successful'}))

    async def disconnect(self, close_code):
        logger.debug(f"WebSocket disconnected with close code: {close_code}")

    async def receive(self, text_data):
        logger.debug(f"Received message: {text_data}")
        try:
            user_prompt = json.loads(text_data)['prompt']
            response = self.llm_processor.process(user_prompt)
            await self.send(text_data=json.dumps({'response': response}))
        except Exception as e:
            logger.error(f"Error processing message: {e}")
            await self.send(text_data=json.dumps({'error': str(e)}))


class TranscriptCollector:
    """Collects transcript parts and forms a full sentence."""
    def __init__(self):
        self.parts = []

    def add_part(self, part):
        self.parts.append(part)

    def get_full_transcript(self):
        return " ".join(self.parts)

    def reset(self):
        self.parts = []

class DeepgramConsumer(AsyncWebsocketConsumer):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.transcript_collector = TranscriptCollector()

    async def connect(self):
        logger.debug("WebSocket connection attempt.")
        await self.accept()
        logger.debug("WebSocket connection accepted.")
        self.deepgram = DeepgramClient()
        self.dg_connection = self.deepgram.listen.websocket.v("1")
        self.dg_connection.on(LiveTranscriptionEvents.Transcript, self.on_message)
        
        options = LiveOptions(model="nova-2")
        if self.dg_connection.start(options) is False:
            print("Failed to start connection")
            return
        self.lock_exit = threading.Lock()
        self.exit = False


        await self.send(text_data=json.dumps({'type': 'Connection Successful'}))

    async def disconnect(self, close_code):
        logger.debug(f"WebSocket disconnected with close code: {close_code}")

    async def receive(self, bytes_data):
        logger.debug(f"Received message: {bytes_data}")
        try:

            # If you need to iterate over bytes in chunks:
            chunk_size = 1024  # Define your chunk size
            for i in range(0, len(bytes_data), chunk_size):
                chunk = bytes_data[i:i + chunk_size]
                self.lock_exit.acquire()
                if self.exit:
                    break
                self.lock_exit.release()

                self.dg_connection.send(chunk)

        except Exception as e:
            logger.error(f"Error processing message: {e}")
            await self.send(text_data=json.dumps({'error': str(e)}))

    async def on_message(self, result, **kwargs):
            sentence = result.channel.alternatives[0].transcript
            if len(sentence) == 0:
                return
            print(f"speaker: {sentence}")