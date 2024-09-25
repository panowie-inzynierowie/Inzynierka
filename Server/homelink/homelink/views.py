from rest_framework import permissions, status
from rest_framework.generics import CreateAPIView
from rest_framework.response import Response
from rest_framework.authtoken.models import Token
from django.contrib.auth import get_user_model

from .serializers import UserSerializer


class CreateUserView(CreateAPIView):
    model = get_user_model()
    permission_classes = [permissions.AllowAny]
    serializer_class = UserSerializer

    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        headers = self.get_success_headers(serializer.data)
        token, _ = Token.objects.get_or_create(
            user=get_user_model().objects.get(username=serializer.data["username"])
        )
        if request.data.get("user"):
            created = serializer.instance
            created.owner = get_user_model().objects.get(username=request.data["user"])
            created.is_device = True
            created.save()

        return Response(
            {**serializer.data, "token": token.key},
            status=status.HTTP_201_CREATED,
            headers=headers,
        )
