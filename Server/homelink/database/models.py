from django.db import models
from django.contrib.auth.models import User


class Space(models.Model):
    name = models.TextField()
    description = models.TextField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    owner = models.ForeignKey(User, on_delete=models.CASCADE)
    users = models.ManyToManyField(User, related_name="spaces")

    def __str__(self):
        return self.name


class Device(models.Model):
    name = models.TextField()
    description = models.TextField(null=True, blank=True)
    data = models.JSONField(null=True, blank=True)
    added_at = models.DateTimeField(auto_now_add=True)

    owner = models.ForeignKey(User, on_delete=models.CASCADE)
    space = models.ForeignKey(Space, on_delete=models.SET_NULL, null=True, blank=True)

    def __str__(self):
        return self.name
