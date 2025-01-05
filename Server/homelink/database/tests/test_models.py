from django.test import TestCase
from django.contrib.auth import get_user_model
from django.utils import timezone
from datetime import timedelta, datetime
from database.models.models import Space, Device, Command, CommandsLink

User = get_user_model()

class ModelsTestCase(TestCase):
    def setUp(self):
        # Tworzymy użytkownika
        self.user = User.objects.create_user(username="testuser", password="testpass")
        self.user2 = User.objects.create_user(username="owner2", password="testpass2")

        # Tworzymy obiekt Space
        self.space = Space.objects.create(
            name="Living Room",
            description="Main living area",
            owner=self.user
        )
        self.space.users.add(self.user)
        self.space.users.add(self.user2)

        # Tworzymy obiekt Device
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

        # Tworzymy obiekt Command
        self.command = Command.objects.create(
            author=self.user,
            device=self.device,
            data={"name": "LED", "action": "on"},
            scheduled_at=timezone.now() + timedelta(minutes=5),
            repeat_interval=timedelta(minutes=10)
        )

        # Tworzymy CommandsLink
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
        # Sprawdzenie poprawności metody __str__ w Space
        expected_str = f"{self.space.name} {self.space.owner.username}"
        self.assertEqual(str(self.space), expected_str)

    def test_device_str(self):
        # Sprawdzenie poprawności metody __str__ w Device
        expected_str = f"{self.device.name} | {self.device.owner.username}"
        self.assertEqual(str(self.device), expected_str)

    def test_command_get_next_scheduled_at(self):
        # Sprawdzenie metody get_next_scheduled_at w Command
        expected = self.command.scheduled_at + self.command.repeat_interval
        self.assertEqual(self.command.get_next_scheduled_at(), expected)

    def test_commands_link_reset_triggers(self):
        # Sprawdzamy czy reset_triggers ustawia satisfied_at na None
        # Początkowo pierwszy trigger ma None, ustawimy go, a potem zresetujemy
        self.commands_link.triggers[0]["satisfied_at"] = f"{timezone.now()}"
        self.commands_link.save()

        self.commands_link.reset_triggers()
        self.commands_link.refresh_from_db()
        self.assertIsNone(self.commands_link.triggers[0]["satisfied_at"])

    def test_commands_link_check_all_satisfied_without_ttl(self):
        # Jeśli wszystkie trigger'y zostaną zaspokojone i nie ma TTL,
        # to wyniki (results) zostaną wykonane od razu
        self.commands_link.triggers[0]["satisfied_at"] = f"{timezone.now()}"
        self.commands_link.save()

        # Po zaspokojeniu check_all_satisfied powinien wywołać execute_linked_commands
        self.commands_link.check_all_satisfied()

        # Sprawdzamy czy Command został utworzony zgodnie z results
        new_command = Command.objects.filter(
            author=self.user, device=self.device, data={"name": "LED", "action": "off"}
        ).first()
        self.assertIsNotNone(new_command)
        # Po wykonaniu reset_triggers triggers znowu powinne być None
        self.commands_link.refresh_from_db()
        self.assertIsNone(self.commands_link.triggers[0]["satisfied_at"])

    def test_commands_link_check_all_satisfied_with_ttl(self):
        # Test sprawdza działanie TTL. Dodamy kilka triggerów i TTL.
        # Załóżmy, że mamy dwa triggery, ustawimy oba jako zaspokojone w oknie czasu krótszym niż TTL.
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

        # Po spełnieniu check_all_satisfied wykona commands
        self.commands_link.check_all_satisfied()

        # Sprawdzenie, czy polecenia zostały utworzone
        new_command = Command.objects.filter(
            author=self.user, device=self.device, data={"name": "LED", "action": "off"}
        ).first()
        self.assertIsNotNone(new_command)

    def test_commands_link_check_triggers(self):
        # Sprawdza czy wywołanie check_triggers ustawia satisfied_at i następnie check_all_satisfied jest sprawdzane
        # Początkowo satisfied_at = None
        self.assertIsNone(self.commands_link.triggers[0]["satisfied_at"])

        # Wywołujemy check_triggers
        CommandsLink.check_triggers(self.device.id, {"name": "LED", "action": "on"})

        self.commands_link.refresh_from_db()
        self.assertIsNotNone(self.commands_link.triggers[0]["satisfied_at"])

        # Ponieważ mamy tylko jeden trigger i jest zaspokojony, od razu powinno się wykonać results
        new_command = Command.objects.filter(
            author=self.user, device=self.device, data={"name": "LED", "action": "off"}
        ).first()
        self.assertIsNotNone(new_command)
