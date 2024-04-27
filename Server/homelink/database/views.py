from django.contrib.auth.models import User

from rest_framework.response import Response
from rest_framework import status
from rest_framework import viewsets


class UserViewSet(viewsets.ModelViewSet):

    def create_user(self, request):
        try:
            data = request.data
            user = User.objects.create_user(
                username=data["username"], password=data["password"]
            )
            return Response({"user_id": user.id}, status=status.HTTP_201_CREATED)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)
