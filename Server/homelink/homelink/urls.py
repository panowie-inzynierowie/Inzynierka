from django.urls import path, include
from django.contrib import admin
from rest_framework.authtoken import views

urlpatterns = [
    path("login/", views.obtain_auth_token),
    path("admin/", admin.site.urls),
    path("api/", include("database.urls")),
]
