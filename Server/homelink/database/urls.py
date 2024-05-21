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
]
