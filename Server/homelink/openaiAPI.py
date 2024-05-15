from openai import OpenAI

OPENAI_API_KEY="" # Api key from OpenAI

client = OpenAI(api_key=OPENAI_API_KEY)

completion = client.chat.completions.create(
  model="gpt-3.5-turbo",
  messages=[
    {"role": "system", "content": "You are a poetic assistant, skilled in explaining complex programming concepts with creative flair."},
    {"role": "user", "content": "Diffrence between dog and a cat."}
  ]
)

print(completion.choices[0].message)