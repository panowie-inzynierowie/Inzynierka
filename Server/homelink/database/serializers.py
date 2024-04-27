from .models import HomeLinkUser, Space, Device
from rest_framework import serializers


class HomeLinkUserSerializer(serializers.ModelSerializer):
    class Meta:
        model = HomeLinkUser
        fields = "__all__"
