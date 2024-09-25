from django.db import models
from django.contrib.auth.models import AbstractUser


class CustomUser(AbstractUser):
    is_device = models.BooleanField(default=False)
    owner = models.ForeignKey("self", on_delete=models.CASCADE, null=True, blank=True)
