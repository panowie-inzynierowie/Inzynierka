import json

from django.contrib.auth import get_user_model
from rest_framework import viewsets
from rest_framework import viewsets, status
from rest_framework.response import Response

from .models.models import *
from .serializers import *


User = get_user_model()


class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer


class SpaceDevicesView(viewsets.ModelViewSet):
    serializer_class = DeviceSerializer

    def get_queryset(self):
        space_id = self.kwargs["space_id"]
        return Device.objects.filter(space_id=space_id)

    def perform_create(self, serializer):
        space_id = self.kwargs["space_id"]
        try:
            space = Space.objects.get(id=space_id)
            serializer.save(space=space, owner=self.request.user)
        except Space.DoesNotExist:
            return Response(
                {"error": "Space not found"}, status=status.HTTP_404_NOT_FOUND
            )


class DeviceViewSet(viewsets.ModelViewSet):
    serializer_class = DeviceSerializer

    def get_queryset(self):
        return Device.objects.filter(owner=self.request.user)

    def perform_create(self, serializer):
        space_id = self.request.data.get("space_id")
        print(f"Received space_id: {space_id}")

        try:
            space = Space.objects.get(id=space_id)
            print(f"Found space: {space}")
            serializer.save(owner=self.request.user)
        except Space.DoesNotExist:
            print(f"Space with id {space_id} does not exist")
            return Response(
                {"error": "Invalid space ID"}, status=status.HTTP_400_BAD_REQUEST
            )
        except Exception as e:
            print(f"An error occurred: {e}")  # Log any other exceptions
            return Response(
                {"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class SpaceViewSet(viewsets.ModelViewSet):
    serializer_class = SpaceSerializer

    def get_queryset(self):
        return Space.objects.filter(users=self.request.user)

    def perform_create(self, serializer):
        serializer.save()


class CommandViewSet(viewsets.ModelViewSet):
    serializer_class = CommandSerializer

    def get_queryset(self):
        return Command.objects.filter(devices__owner=self.request.user)

    def perform_create(self, serializer):
        serializer.save(author=self.request.user)
