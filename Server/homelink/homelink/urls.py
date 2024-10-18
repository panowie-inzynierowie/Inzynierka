from django.urls import path, include
from django.contrib import admin
from rest_framework.authtoken import views
from .views import CreateUserView
from .views import ChatGPTView

urlpatterns = [
    path("login/", views.obtain_auth_token),
    path("register/", CreateUserView.as_view()),
    path("admin/", admin.site.urls),
    path('api/chat/', ChatGPTView.as_view(), name='chat-gpt'),
    path("api/", include("database.urls")),
]
