from django.db import models
from django.contrib.auth import get_user_model

User = get_user_model()


class Space(models.Model):
    name = models.TextField()
    description = models.TextField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    owner = models.ForeignKey(User, on_delete=models.CASCADE)
    users = models.ManyToManyField(User, related_name="spaces")

    def __str__(self):
        return f"{self.name} {self.owner.username}"


class Device(models.Model):
    name = models.TextField()
    description = models.TextField(null=True, blank=True)
    data = models.JSONField(null=True, blank=True)

    account = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="account_devices",
        null=True,
        blank=True,
    )
    added_at = models.DateTimeField(auto_now_add=True)

    owner = models.ForeignKey(User, on_delete=models.CASCADE, related_name="devices")
    space = models.ForeignKey(Space, on_delete=models.SET_NULL, null=True, blank=True)

    def __str__(self):
        return f"{self.name} | {self.owner.username}"


class Command(models.Model):
    author = models.ForeignKey(User, on_delete=models.CASCADE)
    devices = models.ManyToManyField(Device, related_name="commands")

    description = models.TextField(null=True, blank=True)
    data = models.JSONField()

    scheduled_at = models.DateTimeField(null=True, blank=True, db_index=True)
    repeat_interval = models.DurationField(null=True, blank=True)

    def get_next_scheduled_at(self):
        return self.scheduled_at + self.repeat_interval