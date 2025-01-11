from django.test import TestCase
from rest_framework.test import APIRequestFactory
from django.contrib.auth import get_user_model
from datetime import timedelta
from ..models.models import Space, Device, Command, CommandsLink
from ..serializers import (
    UserSerializer,
    SpaceSerializer,
    DeviceSerializer,
    DeviceUpdateSerializer,
    CommandSerializer,
    CommandForDeviceSerializer,
    CommandsLinkSerializer,
)

User = get_user_model()


class UserSerializerTest(TestCase):
    def test_user_serializer(self):
        user = User.objects.create_user(username="testuser", email="test@example.com", password="testpassword")
        serializer = UserSerializer(user)
        expected_data = {
            "id": user.id,
            "username": "testuser",
            "email": "test@example.com",
            "pk": user.pk,
        }
        self.assertEqual(serializer.data, expected_data)


class SpaceSerializerTest(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(username="owner", password="password")
        self.factory = APIRequestFactory()

    def test_create_space(self):
        data = {"name": "Test Space", "description": "A test space"}
        request = self.factory.post("/spaces/", data)
        request.user = self.user
        context = {"request": request}
        serializer = SpaceSerializer(data=data, context=context)
        self.assertTrue(serializer.is_valid())
        space = serializer.save()

        self.assertEqual(space.name, "Test Space")
        self.assertEqual(space.description, "A test space")
        self.assertIn(self.user, space.users.all())
        self.assertEqual(space.owner, self.user)


class DeviceSerializerTest(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(username="owner", password="password")
        self.space = Space.objects.create(name="Living Room", owner=self.user)
        self.device = Device.objects.create(name="Lamp", owner=self.user, space=self.space)

    def test_device_serializer(self):
        serializer = DeviceSerializer(self.device)
        self.assertEqual(serializer.data["name"], "Lamp")
        self.assertEqual(serializer.data["space"]["name"], "Living Room")
        self.assertEqual(serializer.data["owner"], "owner")


class DeviceUpdateSerializerTest(TestCase):
    def test_device_update_serializer(self):
        data = {"name": "Updated Device", "description": "Updated description"}
        serializer = DeviceUpdateSerializer(data=data)
        self.assertTrue(serializer.is_valid())
        self.assertEqual(serializer.validated_data["name"], "Updated Device")
        self.assertEqual(serializer.validated_data["description"], "Updated description")


class CommandSerializerTest(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(username="owner", password="password")
        self.device = Device.objects.create(name="Lamp", owner=self.user)

    def test_command_serializer(self):
        command = Command.objects.create(
            author=self.user,
            device=self.device,
            description="Turn on the lamp",
            executed=False,
            data={"action": "turn_on"},
        )
        serializer = CommandSerializer(command)
        self.assertEqual(serializer.data["description"], "Turn on the lamp")
        self.assertEqual(serializer.data["device__name"], "Lamp")



class CommandForDeviceSerializerTest(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(username="owner", password="password")
        self.device = Device.objects.create(name="Lamp", owner=self.user)

    def test_command_for_device_serializer(self):
        command = Command.objects.create(
            author=self.user,
            device=self.device,
            data={"action": "turn_on"}
        )
        serializer = CommandForDeviceSerializer(command)
        self.assertEqual(serializer.data["data"], {"action": "turn_on"})



class CommandsLinkSerializerTest(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(username="owner", password="password")

    def test_commands_link_serializer(self):
        commands_link = CommandsLink.objects.create(
            owner=self.user, triggers=[], results=[], ttl=timedelta(seconds=3600)
        )
        serializer = CommandsLinkSerializer(commands_link)
        self.assertEqual(serializer.data["ttl"], "01:00:00")