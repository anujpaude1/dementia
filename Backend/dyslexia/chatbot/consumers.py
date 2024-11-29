import os
import sys
import json
import logging
from channels.generic.websocket import AsyncWebsocketConsumer
from QuickAgent.QuickAgent import LanguageModelProcessor
#gg
# Configure logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

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