from django.urls import path
from .views import UserViewSet

urlpatterns = [
    path("user/add/", UserViewSet.as_view({"post": "create_user"})),
]
