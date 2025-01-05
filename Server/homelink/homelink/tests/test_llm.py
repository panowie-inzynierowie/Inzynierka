# your_django_app/tests/test_llm.py

from unittest.mock import patch, MagicMock
from django.test import TestCase
from django.contrib.auth import get_user_model
from database.models.models import Device, Command
from ..llm import get_structured_response, generate_suggested_links_for_user

User = get_user_model()

class LlmTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(username='bob', password='bobpass')
        self.device = Device.objects.create(id=1, owner=self.user, data={})
        # Załóżmy, że user ma metodę get_user_devices() zwracającą [self.device]
        # Można np. zrobić patch do user.get_user_devices w samym teście,
        # ale prostsze jest nadpisanie metody w klasie user, żeby zwracała to:
        self.user.get_user_devices = MagicMock(return_value=[self.device])

    @patch('homelink.llm.client.beta.chat.completions.parse')
    def test_generate_suggested_links_for_user(self, mock_parse):
        """
        Sprawdzamy czy generate_suggested_links_for_user zwraca poprawny słownik
        na podstawie mockowanej odpowiedzi OpenAI.
        """
        mock_response = MagicMock()
        mock_response.choices = [
            MagicMock(
                message=MagicMock(
                    parsed=MagicMock(
                        to_dict=lambda: {
                            "links": [
                                {
                                    "triggers": [{"device_id": 1, "component_name": "Light", "action": "on", "satisfied_at": None}],
                                    "results": [{"device_id": 1, "data": {"name": "turn_off", "action": "off"}}],
                                    "ttl": 60
                                }
                            ]
                        }
                    )
                )
            )
        ]
        mock_parse.return_value = mock_response

        result = generate_suggested_links_for_user(self.user)
        self.assertIn("links", result)
        self.assertEqual(len(result["links"]), 1)
        link = result["links"][0]
        self.assertEqual(link["ttl"], 60)
        self.assertEqual(link["triggers"][0]["action"], "on")
        self.assertEqual(link["results"][0]["data"]["action"], "off")

'''    @patch('homelink.llm.client.beta.chat.completions.parse')
    def test_get_structured_response_creates_command(self, mock_parse):
        # Przygotowujemy mockowaną odpowiedź z OpenAI
        mock_response = MagicMock()
        mock_response.choices = [
            MagicMock(
                message=MagicMock(
                    parsed={
                        "text": "Hello from mock LLM",
                        "commands_to_execute": [
                            {
                                "device_id": 1,
                                "data": {"name": "turn_on", "action": "on"},
                                "scheduled_at": None,
                                "repeat_interval": None
                            }
                        ],
                        "device_data_to_everride": None
                    }
                )
            )
        ]
        mock_parse.return_value = mock_response

        messages = [{"role": "user", "content": "Turn on the device please"}]
        response_text = get_structured_response(messages, devices=self.user.get_user_devices(), user=self.user)

        self.assertEqual(response_text, "Hello from mock LLM")
        # Sprawdź, czy utworzył się Command w bazie
        cmd = Command.objects.filter(author=self.user).first()
        self.assertIsNotNone(cmd)
        self.assertEqual(cmd.description, "turn_on on")
        self.assertEqual(cmd.device, self.device)

    @patch('homelink.llm.client.beta.chat.completions.parse')
    def test_get_structured_response_device_override(self, mock_parse):
        # Testujemy override device data
        mock_response = MagicMock()
        mock_response.choices = [
            MagicMock(
                message=MagicMock(
                    parsed={
                        "text": "Overridden device data",
                        "commands_to_execute": [],
                        "device_data_to_everride": {
                            "id": 1,
                            "components": [
                                {
                                    "name": "Light",
                                    "actions": ["on", "off"],
                                    "is_output": True,
                                    "has_input_action": False,
                                }
                            ]
                        }
                    }
                )
            )
        ]
        mock_parse.return_value = mock_response

        messages = [{"role": "user", "content": "Override device data"}]
        response_text = get_structured_response(messages, devices=self.user.get_user_devices(), user=self.user)
        self.assertEqual(response_text, "Overridden device data")

        self.device.refresh_from_db()
        self.assertIn("components", self.device.data)
        self.assertEqual(len(self.device.data["components"]), 1)
        self.assertEqual(self.device.data["components"][0]["name"], "Light")
'''