from django.urls import path
from .views import *


urlpatterns = [
    # add user (username, password, email)
    path("user/add/", UserViewSet.as_view({"post": "create"})),
    # owner id: number
    path("devices/add/", DeviceViewSet.as_view({"post": "create"})),
    # returns devices for authorized user
    path("devices/get/", DeviceViewSet.as_view({"get": "list"})),
    path("spaces/add/", SpaceViewSet.as_view({"post": "create"})),
    # returns spaces authorized user participates in
    path("spaces/get/", SpaceViewSet.as_view({"get": "list"})),
    # return devices in a space
    path('spaces/<int:space_id>/devices/', SpaceDevicesView.as_view({'get': 'list', 'post': 'create'})),
    # add command to device
    path("commands/add/", CommandViewSet.as_view({"post": "create"})),
    # get commands for user
    path("commands/get/", CommandViewSet.as_view({"get": "list"})),
]
