from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone

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

    # {
    # "components":
    # [{
    # "name": "LED", "actions": ["on", "off", "toggle"]
    # }]
    # }
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
    device = models.ForeignKey(Device, on_delete=models.SET_NULL, null=True, blank=True)

    description = models.TextField(null=True, blank=True)

    # {"name": componentName, "action": action}
    data = models.JSONField()

    scheduled_at = models.DateTimeField(null=True, blank=True, db_index=True)
    repeat_interval = models.DurationField(null=True, blank=True)

    def get_next_scheduled_at(self):
        return self.scheduled_at + self.repeat_interval


class CommandsLink(models.Model):
    # [{
    #     "device_id": deviceId,
    #     "component_name": componentName,
    #     "action": action,
    #     "satisfied_at": None,
    # }]
    triggers = models.JSONField()

    # if multiple triggers, define the maximum time that can pass between the first and the last being satisfied
    ttl = models.DurationField(null=True, blank=True)
    started_at = models.DateTimeField(null=True, blank=True)
    owner = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)

    # [{
    #     "device_id": deviceId,
    #     "data": {"name": componentName, "action": action}
    # }]
    results = models.JSONField()

    def check_all_satisfied(self):
        all_satisfied = all(
            trigger.get("satisfied_at") is not None for trigger in self.triggers
        )

        if all_satisfied:
            if self.ttl:
                first_satisfied = min(
                    trigger["satisfied_at"] for trigger in self.triggers
                )
                last_satisfied = max(
                    trigger["satisfied_at"] for trigger in self.triggers
                )
                time_diff = last_satisfied - first_satisfied

                if time_diff <= self.ttl:
                    self.execute_linked_commands()
                else:  # TODO keep satisfied triggers that are within the ttl
                    self.reset_triggers()
            else:
                self.execute_linked_commands()

    def execute_linked_commands(self):
        for result in self.results:
            device = Device.objects.get(id=result["device_id"])
            Command.objects.create(
                author=device.owner, device=device, data=result["data"]
            )

        self.reset_triggers()

    def reset_triggers(self):
        for trigger in self.triggers:
            trigger["satisfied_at"] = None
        self.save()

    @classmethod
    def check_triggers(cls, device_id, data):
        for cl in CommandsLink.objects.filter(
            triggers__contains=[
                {
                    "device_id": device_id,
                    "component_name": data["name"],
                    "action": data["action"],
                    "satisfied_at": None,
                }
            ]
        ):
            for t in cl.triggers:
                if (
                    t["component_name"] == data["name"]
                    and t["action"] == data["action"]
                    and not t["satisfied_at"]
                ):
                    t["satisfied_at"] = f"{timezone.now()}"
                    cl.save()
                    break
            else:
                continue
            cl.check_all_satisfied()
