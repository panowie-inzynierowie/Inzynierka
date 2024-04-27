from rest_framework.response import Response

from rest_framework import status
from .models import HomeLinkUser, Space, Device
from .serializers import HomeLinkUserSerializer
from rest_framework import viewsets


class UserViewSet(viewsets.ModelViewSet):
    queryset = HomeLinkUser.objects.all()
    serializer_class = HomeLinkUserSerializer
