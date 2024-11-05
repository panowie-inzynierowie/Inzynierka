import os
import json

from openai import OpenAI
from dotenv import load_dotenv

from typing import List
from pydantic import BaseModel

from database.serializers import DeviceSerializer
from database.models.models import Command, Device

load_dotenv()

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
MODEL = os.getenv("MODEL")

if not OPENAI_API_KEY or not MODEL:
    raise Exception("OpenAI API Key and Model must be set in .env file")

client = OpenAI(api_key=OPENAI_API_KEY)


class CommandData(BaseModel):
    name: str
    action: str


class CommandClass(BaseModel):
    device_id: int
    data: CommandData


class ModelResponse(BaseModel):
    text: str
    commands_to_execute: List[CommandClass]


def get_structured_response(
    prompt, response_format=ModelResponse, devices=None, user=None
):
    d = DeviceSerializer(devices, many=True).data
    response = client.beta.chat.completions.parse(
        model=MODEL,
        messages=[
            {
                "role": "system",
                "content": "You are a chatbot helping user with custom smart home system. "
                "Actions to perform on user's request put in commands_to_execute field."
                "Here are the devices user can access: " + json.dumps(d),
            },
            {"role": "user", "content": prompt},
        ],
        response_format=response_format,
    )
    response: ModelResponse = response.choices[0].message.parsed
    text_response = response.text

    for command in response.commands_to_execute:
        device = Device.objects.get(id=command.device_id)
        Command.objects.create(
            author=user,
            device=device,
            description=f"{command.data.name} {command.data.action}",
            data=command.data.model_dump(),
        )

    return text_response
