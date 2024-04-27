from django.db import models


class HomeLinkUser(models.Model):
    username = models.TextField(unique=True)
    email = models.EmailField(unique=True)
    password = models.CharField(max_length=50)  # TODO secret
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.username


class Space(models.Model):
    name = models.TextField()
    description = models.TextField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    owner = models.ForeignKey(HomeLinkUser, on_delete=models.CASCADE)
    users = models.ManyToManyField(HomeLinkUser, related_name="spaces")

    def __str__(self):
        return self.name


class Device(models.Model):
    name = models.TextField()
    description = models.TextField(null=True, blank=True)
    data = models.JSONField(null=True, blank=True)
    added_at = models.DateTimeField(auto_now_add=True)

    owner = models.ForeignKey(HomeLinkUser, on_delete=models.CASCADE)
    space = models.ForeignKey(Space, on_delete=models.SET_NULL, null=True, blank=True)

    def __str__(self):
        return self.name
