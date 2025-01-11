from ..serializers import UserSerializer
from django.test import TestCase
from django.contrib.auth import get_user_model
from rest_framework.exceptions import ValidationError

UserModel = get_user_model()


class UserSerializerTest(TestCase):
    def test_create_user_successfully(self):
        data = {
            "username": "testuser",
            "password": "testpassword",
        }
        serializer = UserSerializer(data=data)
        self.assertTrue(serializer.is_valid())
        user = serializer.save()

        self.assertIsInstance(user, UserModel)
        self.assertEqual(user.username, "testuser")
        self.assertNotEqual(user.password, "testpassword")
        self.assertTrue(user.check_password("testpassword"))

    def test_create_user_missing_username(self):
        data = {
            "password": "testpassword",
        }
        serializer = UserSerializer(data=data)

        with self.assertRaises(ValidationError):
            serializer.is_valid(raise_exception=True)

    def test_create_user_missing_password(self):
        data = {
            "username": "testuser",
        }
        serializer = UserSerializer(data=data)

        with self.assertRaises(ValidationError):
            serializer.is_valid(raise_exception=True)