from django.urls import path
from .views import *
from rest_framework.routers import DefaultRouter

router = DefaultRouter()

router.register("commands", CommandViewSet, basename="routed-commands")
router.register("commands-links", CommandsLinkViewSet, basename="commands-links")

urlpatterns = [
    path("user/add/", UserViewSet.as_view({"post": "create"})),
    path("devices/add/", DeviceViewSet.as_view({"post": "create"})),
    path("devices/get/", DeviceViewSet.as_view({"get": "list"})),
    path("spaces/add/", SpaceViewSet.as_view({"post": "create"})),
    path("spaces/get/", SpaceViewSet.as_view({"get": "list"})),
    path(
        "spaces/<int:space_id>/devices/",
        SpaceDevicesView.as_view({"get": "list", "post": "create"}),
    ),
    path("commands/add/", CommandViewSet.as_view({"post": "create"})),
    path("commands/get/", CommandViewSet.as_view({"get": "list"})),
]

urlpatterns += router.urls
