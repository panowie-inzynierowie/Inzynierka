import os

from openai import OpenAI
from dotenv import load_dotenv

from pydantic import BaseModel

load_dotenv()

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
MODEL = os.getenv("MODEL")

if not OPENAI_API_KEY or not MODEL:
    raise Exception("OpenAI API Key and Model must be set in .env file")

client = OpenAI(api_key=OPENAI_API_KEY)


class Command(BaseModel):
    triggering_action: str
    device_affected: str
    action_to_perform: str


class CommandsResponse(BaseModel):
    commands: list[Command]


def get_structured_response(prompt, response_format=CommandsResponse):
    response = client.beta.chat.completions.parse(
        model=MODEL,
        messages=[
            {"role": "system", "content": "You are brain of home automation system."},
            {"role": "user", "content": prompt},
        ],
        response_format=response_format,
    )
    content = response.choices[0].message.parsed
    return content
