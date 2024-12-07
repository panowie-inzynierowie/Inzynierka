import time
import threading

from django.db.models.signals import post_save
from django.dispatch import receiver
from django.contrib.auth import get_user_model
from django.utils import timezone
from rest_framework import viewsets, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from django.db.models import Q
from .mixins import MultiSerializerMixin

from .filters import DeviceFilter, CommandFilter
from .models.models import *
from .serializers import *
from django_filters.rest_framework import DjangoFilterBackend

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


class DeviceViewSet(viewsets.ModelViewSet, MultiSerializerMixin):
    default_serializer_class = DeviceSerializer
    serializer_classes = {
        "update": DeviceUpdateSerializer,
    }
    filter_backends = [DjangoFilterBackend]
    filterset_class = DeviceFilter

    def get_queryset(self):
        if self.request.query_params.get("spaceless", None):
            return Device.objects.filter(owner=self.request.user).filter(space=None)
        return Device.objects.filter(
            Q(owner=self.request.user) | Q(space__users=self.request.user)
        ).distinct()

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
    filter_backends = [DjangoFilterBackend]
    filterset_class = CommandFilter

    def get_serializer(self, *args, **kwargs):
        if self.request.query_params.get("all", None):
            return CommandSerializer(*args, **kwargs)
        else:
            return CommandForDeviceSerializer(*args, **kwargs)

    def get_queryset(self):
        xd = timezone.now() + timezone.timedelta(hours=1)
        qs = Command.objects.filter(
            Q(device__owner=self.request.user.pk)
            | Q(device__account=self.request.user.pk)
        )

        if self.request.query_params.get("all", None):
            return qs
        return qs.filter(executed=False).filter(
            Q(scheduled_at__isnull=True) | Q(scheduled_at__lte=xd)
        )

    def perform_create(self, serializer):
        serializer.save(
            author=(
                self.request.user.owner
                if self.request.user.is_device
                else self.request.user
            ),
            device=(
                serializer.validated_data["device"]
                if serializer.validated_data.get("device")
                else self.request.user.account_devices.first()
            ),
        )

    def perform_destroy(self, instance: Command):
        if self.request.query_params.get("cancel", None):
            instance.delete()
            return
        CommandsLink.check_triggers(instance.device.pk, instance.data)
        instance.executed = True
        instance.save()

    def list(self, request, *args, **kwargs):
        if request.query_params.get("all", None):
            return super().list(request, *args, **kwargs)
        try:
            timeout = 120
            result = []
            stop_event = threading.Event()

            def check_queryset():
                nonlocal result
                start_time = time.time()
                while time.time() - start_time < timeout:
                    queryset = self.filter_queryset(self.get_queryset())
                    if queryset.exists():
                        result = self.get_serializer(queryset, many=True).data
                        stop_event.set()
                        break
                    time.sleep(1)

            thread = threading.Thread(target=check_queryset)
            thread.start()

            thread.join(timeout)

            if not result:
                return Response([])

            return Response(result)
        except:
            return Response([])


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


# AddUserToSpaceView to add a user to a space
class AddUserToSpaceView(APIView):  # APIView is now imported
    permission_classes = [IsAuthenticated]

    def post(self, request, space_id):
        username = request.data.get("username")

        if not username:
            return Response(
                {"error": "Username is required"}, status=status.HTTP_400_BAD_REQUEST
            )

        try:
            user = User.objects.get(username=username)
        except User.DoesNotExist:
            return Response(
                {"error": "User does not exist"}, status=status.HTTP_404_NOT_FOUND
            )

        try:
            space = Space.objects.get(pk=space_id)
            space.users.add(user)
            return Response(
                {"message": f"User '{username}' added to space."},
                status=status.HTTP_200_OK,
            )
        except Space.DoesNotExist:
            return Response(
                {"error": "Space not found"}, status=status.HTTP_404_NOT_FOUND
            )


# RemoveUserFromSpaceView to remove a user from a space
class RemoveUserFromSpaceView(APIView):  # APIView is now imported
    permission_classes = [IsAuthenticated]

    def delete(self, request, space_id, user_id):
        try:
            user = User.objects.get(pk=user_id)
        except User.DoesNotExist:
            return Response(
                {"error": "User not found"}, status=status.HTTP_404_NOT_FOUND
            )

        try:
            space = Space.objects.get(pk=space_id)
            if user not in space.users.all():
                return Response(
                    {"error": "User not in this space"},
                    status=status.HTTP_400_BAD_REQUEST,
                )

            space.users.remove(user)
            return Response(
                {"message": f"User '{user.username}' removed from space."},
                status=status.HTTP_204_NO_CONTENT,
            )
        except Space.DoesNotExist:
            return Response(
                {"error": "Space not found"}, status=status.HTTP_404_NOT_FOUND
            )


class SpaceUsersView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, space_id):
        try:
            space = Space.objects.get(pk=space_id)
        except Space.DoesNotExist:
            return Response(
                {"error": "Space not found"}, status=status.HTTP_404_NOT_FOUND
            )

        users = space.users.all()  # Retrieve all users associated with the space
        serializer = UserSerializer(users, many=True)  # Serialize the list of users
        return Response(serializer.data, status=status.HTTP_200_OK)
