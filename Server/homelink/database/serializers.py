import json

from rest_framework import serializers
from django.contrib.auth.models import User

from .models import *
from .llm import get_response


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
    space_id = serializers.IntegerField(write_only=True)
    owner = serializers.ReadOnlyField(source="owner.username")

    class Meta:
        model = Device
        fields = ["name", "description", "space_id", "owner"]

    def create(self, validated_data):
        space_id = validated_data.pop("space_id")
        space = Space.objects.get(id=space_id)
        validated_data["space"] = space
        device = Device.objects.create(**validated_data)

        create_command(validated_data, device)
        return device


class CommandSerializer(serializers.ModelSerializer):
    class Meta:
        model = Command
        fields = "__all__"

    def create(self, validated_data):
        command = Command.objects.create(**validated_data)
        return command


def create_command(validated_data, device):
    devices_data = [
        {"name": d.name, "description": d.description, "data": d.data}
        for d in validated_data["owner"].devices.all()
        if d.pk != device.pk
    ]

    prompt = (
        f"These are available devices with their descriptions and data: {json.dumps(devices_data)}"
        f"New device is being added, with data: {json.dumps({'name': validated_data['name'], 'description': validated_data['description']})}"
        f"can you create any commands based on current devices and new device being added?"
        "Command is an action that should be triggered in case of any event that matches criteria described in descriptions of devices provided by user,"
        "if you can't find any matching command return empty array in JSON format, if there are commands return them in JSON with fields: triggering_action, device_affected, action_to_perform."
        "Do not return anything else than valid JSON"
    )

    if data := get_response(prompt):
        data = json.loads(data)
        try:
            for command in data:
                new_command = Command.objects.create(
                    author=validated_data["owner"], description=command
                )
                new_command.devices.add(device)
        except Exception as e:
            print(e)
