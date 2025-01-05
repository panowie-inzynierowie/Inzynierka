# your_django_app/tests/test_serializers.py

from django.test import TestCase
from django.contrib.auth import get_user_model
from ..serializers import UserSerializer

User = get_user_model()

class UserSerializerTest(TestCase):
    def test_create_user(self):
        data = {
            "username": "testuser",
            "password": "testpass123"
        }
        serializer = UserSerializer(data=data)
        self.assertTrue(serializer.is_valid(), serializer.errors)

        user = serializer.save()
        self.assertIsInstance(user, User)
        self.assertEqual(user.username, "testuser")
        self.assertTrue(user.check_password("testpass123"))

    def test_create_user_missing_password(self):
        data = {
            "username": "testuser"
        }
        serializer = UserSerializer(data=data)
        self.assertFalse(serializer.is_valid())
        self.assertIn('password', serializer.errors)
