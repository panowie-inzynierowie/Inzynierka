from django.db.models.signals import post_save
from django.dispatch import receiver
from django.contrib.auth import get_user_model
from rest_framework import viewsets
from rest_framework import viewsets, status
from rest_framework.response import Response
from django.db.models import Q

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
        try:
            serializer.save(owner=serializer.validated_data["account"].owner)
        except Exception as e:
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
        return Command.objects.filter(
            Q(device__owner=self.request.user.pk)
            | Q(device__account=self.request.user.pk)
        )

    def perform_create(self, serializer):
        serializer.save(
            author=(
                self.request.user.owner
                if self.request.user.is_device
                else self.request.user
            ),
            device=(  # device is creating command -> it doesn't know its PK -> go through account to get Device reference
                serializer.validated_data["device"]
                if serializer.validated_data.get("device")
                else self.request.user.account_devices.first()
            ),
        )

    def perform_destroy(self, instance):
        CommandsLink.check_triggers(instance.device.pk, instance.data)
        return super().perform_destroy(
            instance
        )  # TODO add `executed` flag or something instead of deleting


@receiver(post_save, sender=Command)
def command_post_save(sender, instance, created, **kwargs):
    if created and instance.self_execute:
        CommandViewSet().perform_destroy(instance)


class CommandsLinkViewSet(viewsets.ModelViewSet):
    serializer_class = CommandsLinkSerializer

    def get_queryset(self):
        return CommandsLink.objects.filter(owner=self.request.user.pk)

    def create(self, request, *args, **kwargs):
        request.data["owner"] = request.user.pk
        return super().create(request, *args, **kwargs)
