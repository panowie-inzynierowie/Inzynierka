from django.urls import path
from .views import *


urlpatterns = [
    path("user/add/", UserViewSet.as_view({"post": "create"})),
    path("user/get/<int:pk>/", UserViewSet.as_view({"get": "retrieve"})),
]
