from django.urls import path, include
from django.contrib import admin
from rest_framework.authtoken import views
from .views import CreateUserView, ChatGPTView, GenerateLinksView

urlpatterns = [
    path("login/", views.obtain_auth_token),
    path("register/", CreateUserView.as_view()),
    path("admin/", admin.site.urls),
    path("api/chat/", ChatGPTView.as_view(), name="chat-gpt"),
    path("api/generate-links/", GenerateLinksView.as_view(), name="generate-links"),
    path("api/", include("database.urls")),
]
