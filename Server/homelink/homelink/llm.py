import os
import json

from openai import OpenAI
from dotenv import load_dotenv

from typing import List, Optional
from pydantic import BaseModel

from database.serializers import DeviceSerializer
from database.models.models import Command, Device

from datetime import datetime

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
    scheduled_at: Optional[str]
    repeat_interval: Optional[str]


class ModelResponse(BaseModel):
    text: str
    commands_to_execute: List[CommandClass]


def get_structured_response(
    messages, response_format=ModelResponse, devices=None, user=None
):
    d = DeviceSerializer(devices, many=True).data
    response = client.beta.chat.completions.parse(
        model=MODEL,
        messages=[
            {
                "role": "system",
                "content": "You are a chatbot helping user with custom smart home system. "
                "Actions to perform on user's request put in commands_to_execute field."
                "Here are the devices user can access: "
                + json.dumps(d)
                + "If device has has_input_action flag set to True, you can provide any string input value in the action field "
                "If you want to schedule command, set scheduled_at and repeat_interval if it should repeat "
                f"current time is: {datetime.now()}",
            },
            *messages,
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
            scheduled_at=command.scheduled_at,
            repeat_interval=command.repeat_interval,
        )

    print(text_response)
    return text_response


class Trigger(BaseModel):
    device_id: int
    component_name: str
    action: str
    satisfied_at: Optional[str]


class ResultData(BaseModel):
    name: str
    action: str


class Result(BaseModel):
    device_id: int
    data: ResultData


class CommandsLink(BaseModel):
    triggers: List[Trigger]
    results: List[Result]
    ttl: int


class LinkResponse(BaseModel):
    links: List[CommandsLink]

    def to_dict(self):
        return {
            "links": [
                {
                    "triggers": [t.model_dump() for t in link.triggers],
                    "results": [
                        {"device_id": r.device_id, "data": r.data.model_dump()}
                        for r in link.results
                    ],
                    "ttl": link.ttl if link.ttl else None,
                }
                for link in self.links
            ]
        }


def generate_suggested_links_for_user(user):
    devices = user.get_user_devices()
    response = client.beta.chat.completions.parse(
        model=MODEL,
        messages=[
            {
                "role": "system",
                "content": "You are a chatbot helping user with custom smart home system. "
                "Here are the devices user can access: "
                + json.dumps(DeviceSerializer(devices, many=True).data)
                + "If device has has_input_action flag set to True, you can provide any string input value in the action field "
                "Keep satisfied_at as None",
            },
            {
                "role": "user",
                "content": "Suggest me some links that make sense for smart home system, "
                "links are automations that can make home smarter by chaining performed actions if certain conditions are met. "
                "set ttl if there is more than one trigger "
                "(ttl (saved as number of seconds) defines time between first and last trigger to execute the linked commands)",
            },
        ],
        response_format=LinkResponse,
    )
    return response.choices[0].message.parsed.to_dict()
