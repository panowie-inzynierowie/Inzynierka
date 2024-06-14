from .models import *
from rest_framework import serializers
from django.contrib.auth.models import User


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ["username", "email", "pk"]


class SpaceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Space
        fields = ['id', 'name', 'description']  # Include 'id' field

    def create(self, validated_data):
        user = self.context['request'].user
        space = Space.objects.create(owner=user, **validated_data)
        space.users.add(user)
        return space


class DeviceSerializer(serializers.ModelSerializer):
    space_id = serializers.IntegerField(write_only=True)
    owner = serializers.ReadOnlyField(source='owner.username')

    class Meta:
        model = Device
        fields = ['name', 'description', 'space_id', 'owner']

    def create(self, validated_data):
        space_id = validated_data.pop('space_id')
        space = Space.objects.get(id=space_id)
        validated_data['space'] = space
        device = Device.objects.create(**validated_data)
        return device


class CommandSerializer(serializers.ModelSerializer):
    class Meta:
        model = Command
        fields = "__all__"
    
    def create(self, validated_data):
        command = Command.objects.create(**validated_data)
        return command
