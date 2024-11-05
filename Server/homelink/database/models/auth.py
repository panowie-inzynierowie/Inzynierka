from django.db import models
from django.contrib.auth.models import AbstractUser
from django.apps import apps


class CustomUser(AbstractUser):
    is_device = models.BooleanField(default=False)
    owner = models.ForeignKey("self", on_delete=models.CASCADE, null=True, blank=True)

    def get_user_devices(self):
        Device = apps.get_model("database", "Device")
        Space = apps.get_model("database", "Space")

        result = list(Device.objects.filter(owner=self))
        for s in Space.objects.filter(users=self):
            for d in s.device_set.all():
                result.append(d)

        return list(set(result))
