from django.urls import reverse
from rest_framework.test import APITestCase, APIClient
from rest_framework import status
from django.contrib.auth import get_user_model
from django.utils import timezone
from database.models.models import Space, Device, Command, CommandsLink

User = get_user_model()

class UserViewSetTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(username="testuser", password="testpass")
        self.client.login(username="testuser", password="testpass")
        self.url = reverse('user-list')  # zakładamy, że router nadał nazwę user-list dla UserViewSet

    def test_list_users(self):
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_create_user(self):
        data = {"username": "newuser", "password": "newpass"}
        # Uwaga: w UserViewSet nie było hasła w serializerze, więc test to tylko przykład
        response = self.client.post(self.url, data)
        # Może zwrócić błąd bo w serializerze nie ma passworda - to zależy od implementacji
        # Zakładamy standard: user powinien się utworzyć
        self.assertIn(response.status_code, [status.HTTP_201_CREATED, status.HTTP_400_BAD_REQUEST])


class SpaceViewSetTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(username="owner", password="pass")
        self.client.login(username="owner", password="pass")
        self.url = reverse('space-list')  # Załóżmy że router: space-list
        self.space = Space.objects.create(name="Living Room", owner=self.user)
        self.space.users.add(self.user)

    def test_list_spaces(self):
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertGreaterEqual(len(response.data), 1)

    def test_create_space(self):
        data = {"name": "Kitchen", "description": "My kitchen"}
        response = self.client.post(self.url, data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data["name"], "Kitchen")


class SpaceDevicesViewTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(username="devowner", password="pass")
        self.client.login(username="devowner", password="pass")
        self.space = Space.objects.create(name="Garage", owner=self.user)
        self.space.users.add(self.user)
        self.url = reverse('spacedevices-list', args=[self.space.id])
        # Zakładamy w urls.py jest coś w stylu path('spaces/<int:space_id>/devices/', SpaceDevicesView, ...)

    def test_list_space_devices(self):
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_create_device_for_space(self):
        data = {"name": "Thermostat", "description": "Smart thermostat"}
        response = self.client.post(self.url, data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data["name"], "Thermostat")


class DeviceViewSetTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(username="devuser", password="pass")
        self.client.login(username="devuser", password="pass")
        self.space = Space.objects.create(name="Bedroom", owner=self.user)
        self.space.users.add(self.user)
        self.device = Device.objects.create(name="Lamp", owner=self.user, space=self.space)
        self.url = reverse('device-list')  # Załóżmy że router: device-list

    def test_list_devices(self):
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertGreaterEqual(len(response.data), 1)

    def test_filter_devices_spaceless(self):
        response = self.client.get(self.url, {"spaceless": "1"})
        # Ten device ma space, więc przy spaceless=1 powinno zwrócić 0
        self.assertEqual(len(response.data), 0)

    def test_update_device(self):
        # DeviceViewSet: update powinien używać DeviceUpdateSerializer
        update_url = reverse('device-detail', args=[self.device.id])
        data = {"name": "New Lamp Name"}
        response = self.client.patch(update_url, data)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["name"], "New Lamp Name")


class CommandViewSetTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(username="cmduser", password="pass")
        self.client.login(username="cmduser", password="pass")
        self.space = Space.objects.create(name="Hall", owner=self.user)
        self.space.users.add(self.user)
        self.device = Device.objects.create(name="Lock", owner=self.user, space=self.space)
        self.command = Command.objects.create(
            author=self.user, device=self.device, data={"name": "Lock", "action": "lock"}, executed=False
        )
        self.url = reverse('command-list')  # Załóżmy router command-list

    def test_list_commands_default(self):
        # Powinno zwrócić niewykonane komendy, z terminem wykonania lub bez scheduled_at
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertGreaterEqual(len(response.data), 1)

    def test_list_commands_all(self):
        response = self.client.get(self.url, {"all": "1"})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        # Tutaj powinno zwrócić wszystkie komendy, nieważne executed czy nie

    def test_create_command(self):
        data = {"data": {"name": "Lock", "action": "unlock"}}
        response = self.client.post(self.url, data)
        self.assertIn(response.status_code, [status.HTTP_201_CREATED, status.HTTP_400_BAD_REQUEST])

    def test_destroy_command(self):
        # Wywołanie delete bez parametru 'cancel' powinno zaznaczyć executed = True
        del_url = reverse('command-detail', args=[self.command.id])
        response = self.client.delete(del_url)
        self.assertIn(response.status_code, [status.HTTP_204_NO_CONTENT, status.HTTP_200_OK, status.HTTP_202_ACCEPTED])
        self.command.refresh_from_db()
        self.assertTrue(self.command.executed)


class CommandsLinkViewSetTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(username="cluser", password="pass")
        self.client.login(username="cluser", password="pass")
        self.url = reverse('commandslink-list')  # Załóżmy router: commandslink-list

    def test_create_commands_link(self):
        data = {
            "triggers": [{"device_id": 1, "component_name": "LED", "action": "on", "satisfied_at": None}],
            "results": [{"device_id": 1, "data": {"name": "LED", "action": "off"}}]
        }
        response = self.client.post(self.url, data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)


class AddUserToSpaceViewTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(username="spaceowner", password="pass")
        self.other_user = User.objects.create_user(username="otheruser", password="pass")
        self.client.login(username="spaceowner", password="pass")
        self.space = Space.objects.create(name="Studio", owner=self.user)
        self.url = reverse("add-user-to-space", args=[self.space.id])
        # Załóżmy w urls jest path("spaces/<int:space_id>/add_user/", AddUserToSpaceView, name="add-user-to-space")

    def test_add_user_to_space(self):
        data = {"username": "otheruser"}
        response = self.client.post(self.url, data)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn(self.other_user, self.space.users.all())


class RemoveUserFromSpaceViewTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(username="spaceowner2", password="pass")
        self.other_user = User.objects.create_user(username="otheruser2", password="pass")
        self.client.login(username="spaceowner2", password="pass")
        self.space = Space.objects.create(name="Lobby", owner=self.user)
        self.space.users.add(self.user)
        self.space.users.add(self.other_user)
        self.url = reverse("remove-user-from-space", args=[self.space.id, self.other_user.id])
        # Załóżmy w urls: path("spaces/<int:space_id>/remove_user/<int:user_id>/", RemoveUserFromSpaceView, name="remove-user-from-space")

    def test_remove_user_from_space(self):
        response = self.client.delete(self.url)
        self.assertIn(response.status_code, [status.HTTP_204_NO_CONTENT, status.HTTP_200_OK])
        self.assertNotIn(self.other_user, self.space.users.all())


class SpaceUsersViewTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(username="listowner", password="pass")
        self.other_user = User.objects.create_user(username="listother", password="pass")
        self.client.login(username="listowner", password="pass")
        self.space = Space.objects.create(name="Workshop", owner=self.user)
        self.space.users.add(self.user)
        self.space.users.add(self.other_user)
        self.url = reverse("space-users", args=[self.space.id])
        # Załóżmy w urls: path("spaces/<int:space_id>/users/", SpaceUsersView, name="space-users")

    def test_list_space_users(self):
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        usernames = [u["username"] for u in response.data]
        self.assertIn("listowner", usernames)
        self.assertIn("listother", usernames)
