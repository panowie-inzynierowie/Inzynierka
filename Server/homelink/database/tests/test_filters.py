from django.test import TestCase
from django.contrib.auth import get_user_model
from django.utils import timezone
from database.models.models import Device, Space, Command
from database.filters import DeviceFilter, CommandFilter

User = get_user_model()

class FiltersTestCase(TestCase):
    def setUp(self):
        # Tworzymy użytkownika
        self.user = User.objects.create_user(username="user1", password="pass1")

        # Tworzymy dwa obiekty Space
        self.space1 = Space.objects.create(
            name="Living Room",
            owner=self.user
        )
        self.space2 = Space.objects.create(
            name="Bedroom",
            owner=self.user
        )

        # Tworzymy dwa urządzenia, każde w innej przestrzeni
        self.device1 = Device.objects.create(
            name="Lamp",
            owner=self.user,
            space=self.space1,
            data={"components": []}
        )

        self.device2 = Device.objects.create(
            name="LED Strip",
            owner=self.user,
            space=self.space2,
            data={"components": []}
        )

        # Tworzymy polecenia: jedno wykonane, drugie niewykonane
        self.command_executed = Command.objects.create(
            author=self.user,
            device=self.device1,
            data={"name": "LED", "action": "on"},
            executed=True
        )

        self.command_not_executed = Command.objects.create(
            author=self.user,
            device=self.device2,
            data={"name": "LED", "action": "off"},
            executed=False
        )

    def test_device_filter_by_space(self):
        # Filtrujemy urządzenia po space
        # Kryterium: space = self.space1.id
        filtered = DeviceFilter({"space": self.space1.id}, queryset=Device.objects.all())
        self.assertEqual(len(filtered.qs), 1)
        self.assertIn(self.device1, filtered.qs)
        self.assertNotIn(self.device2, filtered.qs)

        # Filtrujemy po space2
        filtered = DeviceFilter({"space": self.space2.id}, queryset=Device.objects.all())
        self.assertEqual(len(filtered.qs), 1)
        self.assertIn(self.device2, filtered.qs)
        self.assertNotIn(self.device1, filtered.qs)

    def test_command_filter_executed_true(self):
        # Filtrujemy komendy po executed=True
        filtered = CommandFilter({"executed": "true"}, queryset=Command.objects.all())
        self.assertEqual(len(filtered.qs), 1)
        self.assertIn(self.command_executed, filtered.qs)
        self.assertNotIn(self.command_not_executed, filtered.qs)

    def test_command_filter_executed_false(self):
        # Filtrujemy komendy po executed=False
        filtered = CommandFilter({"executed": "false"}, queryset=Command.objects.all())
        self.assertEqual(len(filtered.qs), 1)
        self.assertIn(self.command_not_executed, filtered.qs)
        self.assertNotIn(self.command_executed, filtered.qs)

    def test_command_filter_no_criteria(self):
        # Jeśli nie podamy kryteriów, powinny zwrócić wszystkie komendy
        filtered = CommandFilter({}, queryset=Command.objects.all())
        self.assertEqual(len(filtered.qs), 2)
        self.assertIn(self.command_executed, filtered.qs)
        self.assertIn(self.command_not_executed, filtered.qs)
