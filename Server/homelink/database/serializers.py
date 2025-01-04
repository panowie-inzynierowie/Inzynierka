import json

from rest_framework import serializers

from .models.models import *

User = get_user_model()


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ["id", "username", "email", "pk"]
        ref_name = "UserSerializer"


class SpaceSerializer(serializers.ModelSerializer):
    users = UserSerializer(many=True, read_only=True)  # Add this line to include users

    class Meta:
        model = Space
        fields = ["id", "name", "description", "users"]

    def create(self, validated_data):
        user = self.context["request"].user
        space = Space.objects.create(owner=user, **validated_data)
        space.users.add(user)
        return space


class DeviceUpdateSerializer(serializers.ModelSerializer):
    name = serializers.CharField(required=False)
    description = serializers.CharField(required=False)

    class Meta:
        model = Device
        fields = ["space", "name", "description"]


class DeviceSerializer(serializers.ModelSerializer):
    space = SpaceSerializer(read_only=True)
    space_id = serializers.IntegerField(
        write_only=True, required=False, allow_null=True
    )
    owner = serializers.ReadOnlyField(source="owner.username")

    class Meta:
        model = Device
        fields = [
            "id",
            "name",
            "description",
            "space",
            "space_id",
            "owner",
            "data",
            "account",
        ]


class CommandSerializer(serializers.ModelSerializer):
    device__name = serializers.CharField(source="device.name")

    class Meta:
        model = Command
        fields = [
            "id",
            "description",
            "scheduled_at",
            "device",
            "data",
            "self_execute",
            "executed",
            "device__name",
        ]


class CommandForDeviceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Command
        fields = ["id", "data"]


class CommandsLinkSerializer(serializers.ModelSerializer):
    class Meta:
        model = CommandsLink
        fields = ["id", "triggers", "results", "ttl", "owner"]
