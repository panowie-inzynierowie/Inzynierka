from django.test import TestCase, RequestFactory
from rest_framework.test import APITestCase
from django.contrib.auth import get_user_model
from database.models.models import Space, Device, Command, CommandsLink
from database.serializers import (
    UserSerializer,
    SpaceSerializer,
    DeviceUpdateSerializer,
    DeviceSerializer,
    CommandSerializer,
    CommandForDeviceSerializer,
    CommandsLinkSerializer,
)

User = get_user_model()

class UserSerializerTest(TestCase):
    def test_user_serializer_fields(self):
        user = User(username="testuser", email="test@example.com", pk=123)
        serializer = UserSerializer(user)
        data = serializer.data
        self.assertIn("id", data)
        self.assertIn("username", data)
        self.assertIn("email", data)
        self.assertIn("pk", data)
        self.assertEqual(data["username"], "testuser")
        self.assertEqual(data["email"], "test@example.com")
        self.assertEqual(data["pk"], 123)


class SpaceSerializerTest(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(username="user1", password="pass1")
        self.factory = RequestFactory()
        self.request = self.factory.post("/fake-url/")
        self.request.user = self.user

    def test_space_serializer_create(self):
        # Sprawdzamy czy serializer tworzy poprawnie Space przypisując ownera i dodając go do users
        serializer = SpaceSerializer(
            data={"name": "Living Room", "description": "Main living area"},
            context={"request": self.request},
        )
        self.assertTrue(serializer.is_valid(), serializer.errors)
        space = serializer.save()
        self.assertEqual(space.name, "Living Room")
        self.assertEqual(space.owner, self.user)
        self.assertIn(self.user, space.users.all())

    def test_space_serializer_read(self):
        space = Space.objects.create(name="Kitchen", owner=self.user)
        space.users.add(self.user)
        serializer = SpaceSerializer(space)
        data = serializer.data
        self.assertEqual(data["name"], "Kitchen")
        self.assertEqual(len(data["users"]), 1)
        self.assertEqual(data["users"][0]["username"], "user1")


class DeviceUpdateSerializerTest(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(username="owner", password="pass")
        self.space = Space.objects.create(name="Office", owner=self.user)
        self.device = Device.objects.create(
            name="Sensor",
            owner=self.user,
            space=self.space,
            data={"components": []}
        )

    def test_device_update_serializer_partial_update(self):
        serializer = DeviceUpdateSerializer(
            self.device,
            data={"name": "New Sensor Name"},
            partial=True
        )
        self.assertTrue(serializer.is_valid(), serializer.errors)
        updated_device = serializer.save()
        self.assertEqual(updated_device.name, "New Sensor Name")


class DeviceSerializerTest(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(username="owner", password="pass")
        self.space = Space.objects.create(name="Garage", owner=self.user)
        self.space.users.add(self.user)
        self.device = Device.objects.create(
            name="Lightbulb",
            owner=self.user,
            space=self.space,
            data={"components": [{"name": "LED", "actions": ["on", "off"]}]}
        )
        self.factory = RequestFactory()
        self.request = self.factory.post("/fake-url/")
        self.request.user = self.user

    def test_device_serializer_read(self):
        serializer = DeviceSerializer(self.device, context={"request": self.request})
        data = serializer.data
        self.assertEqual(data["name"], "Lightbulb")
        self.assertEqual(data["owner"], "owner")
        self.assertIn("space", data)
        self.assertIn("data", data)
        self.assertEqual(data["space"]["name"], "Garage")

    def test_device_serializer_write_space_id(self):
        new_space = Space.objects.create(name="Garden", owner=self.user)
        new_space.users.add(self.user)
        serializer = DeviceSerializer(
            self.device,
            data={"space_id": new_space.id, "name": "Garden Lamp"},
            partial=True,
            context={"request": self.request}
        )
        self.assertTrue(serializer.is_valid(), serializer.errors)
        device = serializer.save()
        self.assertEqual(device.space, new_space)
        self.assertEqual(device.name, "Garden Lamp")


class CommandSerializerTest(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(username="cmduser", password="pass")
        self.space = Space.objects.create(name="Hall", owner=self.user)
        self.device = Device.objects.create(
            name="Door Lock",
            owner=self.user,
            space=self.space,
            data={"components": [{"name": "Lock", "actions": ["lock", "unlock"]}]}
        )
        self.command = Command.objects.create(
            author=self.user,
            device=self.device,
            data={"name": "Lock", "action": "lock"},
            executed=False
        )

    def test_command_serializer_read(self):
        serializer = CommandSerializer(self.command)
        data = serializer.data
        self.assertEqual(data["device__name"], "Door Lock")
        self.assertEqual(data["data"], {"name": "Lock", "action": "lock"})
        self.assertEqual(data["executed"], False)


class CommandForDeviceSerializerTest(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(username="devcmd", password="pass")
        self.space = Space.objects.create(name="TestSpace", owner=self.user)
        self.device = Device.objects.create(
            name="Fan",
            owner=self.user,
            space=self.space,
            data={"components": [{"name": "Fan", "actions": ["on", "off"]}]}
        )
        self.command = Command.objects.create(
            author=self.user,
            device=self.device,
            data={"name": "Fan", "action": "on"}
        )

    def test_command_for_device_serializer(self):
        serializer = CommandForDeviceSerializer(self.command)
        data = serializer.data
        self.assertIn("id", data)
        self.assertIn("data", data)
        self.assertEqual(data["data"], {"name": "Fan", "action": "on"})


class CommandsLinkSerializerTest(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(username="linkuser", password="pass")
        self.link = CommandsLink.objects.create(
            triggers=[{"device_id": 1, "component_name": "LED", "action": "on", "satisfied_at": None}],
            results=[{"device_id": 1, "data": {"name": "LED", "action": "off"}}],
            owner=self.user
        )

    def test_commands_link_serializer(self):
        serializer = CommandsLinkSerializer(self.link)
        data = serializer.data
        self.assertIn("id", data)
        self.assertIn("triggers", data)
        self.assertIn("results", data)
        self.assertIn("ttl", data)
        self.assertIn("owner", data)
        self.assertEqual(data["owner"], self.user.id)  # Assuming fields = ["owner"] return owner id
