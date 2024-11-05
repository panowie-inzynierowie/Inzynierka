from .models.models import Device
import django_filters


class DeviceFilter(django_filters.FilterSet):
    class Meta:
        model = Device
        fields = ["space"]
