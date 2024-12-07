from .models.models import Device, Command
import django_filters


class DeviceFilter(django_filters.FilterSet):
    class Meta:
        model = Device
        fields = ["space"]


class CommandFilter(django_filters.FilterSet):
    executed = django_filters.BooleanFilter()

    class Meta:
        model = Command
        fields = ["executed"]
