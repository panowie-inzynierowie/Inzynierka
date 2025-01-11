from django.test import TestCase
from django.contrib.auth import get_user_model
from django.utils import timezone
from datetime import timedelta, datetime
from ..models.models import Space, Device, Command, CommandsLink

User = get_user_model()

class ModelsTestCase(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(username="testuser", password="testpass")
        self.user2 = User.objects.create_user(username="owner2", password="testpass2")

        self.space = Space.objects.create(
            name="Living Room",
            description="Main living area",
            owner=self.user
        )
        self.space.users.add(self.user)
        self.space.users.add(self.user2)

        self.device = Device.objects.create(
            name="Smart LED",
            description="LED light in the living room",
            owner=self.user,
            space=self.space,
            data={
                "components": [
                    {
                        "name": "LED",
                        "actions": ["on", "off", "toggle"],
                        "has_input_action": True,
                        "is_output": False
                    }
                ]
            }
        )

        self.command = Command.objects.create(
            author=self.user,
            device=self.device,
            data={"name": "LED", "action": "on"},
            scheduled_at=timezone.now() + timedelta(minutes=5),
            repeat_interval=timedelta(minutes=10)
        )

        self.commands_link = CommandsLink.objects.create(
            triggers=[
                {
                    "device_id": self.device.id,
                    "component_name": "LED",
                    "action": "on",
                    "satisfied_at": None
                }
            ],
            results=[
                {
                    "device_id": self.device.id,
                    "data": {"name": "LED", "action": "off"}
                }
            ],
            owner=self.user
        )

    def test_space_str(self):
        expected_str = f"{self.space.name} {self.space.owner.username}"
        self.assertEqual(str(self.space), expected_str)

    def test_device_str(self):
        expected_str = f"{self.device.name} | {self.device.owner.username}"
        self.assertEqual(str(self.device), expected_str)

    def test_command_get_next_scheduled_at(self):
        expected = self.command.scheduled_at + self.command.repeat_interval
        self.assertEqual(self.command.get_next_scheduled_at(), expected)

    def test_commands_link_reset_triggers(self):
        self.commands_link.triggers[0]["satisfied_at"] = f"{timezone.now()}"
        self.commands_link.save()

        self.commands_link.reset_triggers()
        self.commands_link.refresh_from_db()
        self.assertIsNone(self.commands_link.triggers[0]["satisfied_at"])

    def test_commands_link_check_all_satisfied_without_ttl(self):
        self.commands_link.triggers[0]["satisfied_at"] = f"{timezone.now()}"
        self.commands_link.save()

        self.commands_link.check_all_satisfied()

        new_command = Command.objects.filter(
            author=self.user, device=self.device, data={"name": "LED", "action": "off"}
        ).first()
        self.assertIsNotNone(new_command)
        self.commands_link.refresh_from_db()
        self.assertIsNone(self.commands_link.triggers[0]["satisfied_at"])

    def test_commands_link_check_all_satisfied_with_ttl(self):
        self.commands_link.triggers = [
            {
                "device_id": self.device.id,
                "component_name": "LED",
                "action": "on",
                "satisfied_at": f"{(timezone.now()).isoformat()}"
            },
            {
                "device_id": self.device.id,
                "component_name": "LED",
                "action": "off",
                "satisfied_at": f"{(timezone.now() + timedelta(seconds=5)).isoformat()}"
            },
        ]
        self.commands_link.ttl = timedelta(seconds=10)
        self.commands_link.save()

        self.commands_link.check_all_satisfied()

        new_command = Command.objects.filter(
            author=self.user, device=self.device, data={"name": "LED", "action": "off"}
        ).first()
        self.assertIsNotNone(new_command)
