from django.urls import path, include
from django.contrib import admin
from rest_framework.authtoken import views
from .views import CreateUserView

urlpatterns = [
    path("login/", views.obtain_auth_token),
    path("register/", CreateUserView.as_view()),
    path("admin/", admin.site.urls),
    path("api/", include("database.urls")),
]
