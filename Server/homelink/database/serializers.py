import json

from rest_framework import serializers

from .models.models import *
from .llm import get_structured_response, CommandsResponse


User = get_user_model()


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ["username", "email", "pk"]


class SpaceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Space
        fields = ["id", "name", "description"]

    def create(self, validated_data):
        user = self.context["request"].user
        space = Space.objects.create(owner=user, **validated_data)
        space.users.add(user)
        return space


class DeviceSerializer(serializers.ModelSerializer):
    space = SpaceSerializer(read_only=True)
    space_id = serializers.IntegerField(write_only=True, required=False)
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
    class Meta:
        model = Command
        fields = ["id", "description", "scheduled_at", "device", "data", "self_execute"]


def create_command(validated_data, device):
    devices_data = [
        {"name": d.name, "description": d.description, "data": d.data}
        for d in validated_data["owner"].devices.all()
        if d.pk != device.pk
    ]

    prompt = (
        f"These are available devices with their descriptions and data: {json.dumps(devices_data)}"
        f"New device is being added, with data: {json.dumps({'name': validated_data['name'], 'description': validated_data['description']})} "
        f"Can you create any commands based on current devices and new device being added?"
        "Command is an action that should be triggered in case of any event that matches criteria described in descriptions of devices provided by user. "
        "Return possible commands."
    )

    if data := get_structured_response(prompt, CommandsResponse):
        data: CommandsResponse
        for command in data.commands:
            c = Command.objects.create(
                author=validated_data["owner"],
                description=f"{command.triggering_action} -> {command.action_to_perform} ({command.device_affected})",
            )
            c.devices.add(device)


class CommandsLinkSerializer(serializers.ModelSerializer):
    class Meta:
        model = CommandsLink
        fields = ["id", "triggers", "results", "ttl", "owner"]
