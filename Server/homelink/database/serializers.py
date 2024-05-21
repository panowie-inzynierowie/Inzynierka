from .models import *
from rest_framework import serializers
from django.contrib.auth.models import User


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ["username", "email", "pk"]


class SpaceSerializer(serializers.ModelSerializer):
    users = UserSerializer(many=True)

    class Meta:
        model = Space
        fields = "__all__"


class DeviceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Device
        fields = "__all__"


class CommandSerializer(serializers.ModelSerializer):
    class Meta:
        model = Command
        fields = "__all__"
