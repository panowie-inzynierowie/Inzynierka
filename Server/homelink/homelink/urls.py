from django.urls import path, include
from django.contrib import admin
from rest_framework.authtoken import views
from .views import CreateUserView, ChatGPTView, GenerateLinksView

from rest_framework import permissions
from drf_yasg.views import get_schema_view
from drf_yasg import openapi

schema_view = get_schema_view(
    openapi.Info(
        title="Snippets API",
        default_version="v1",
        description="",
        terms_of_service="",
    ),
    public=True,
    permission_classes=(permissions.AllowAny,),
)
urlpatterns = [
    path("login/", views.obtain_auth_token),
    path("register/", CreateUserView.as_view(), name="create-user"),
    path("admin/", admin.site.urls),
    path("api/chat/", ChatGPTView.as_view(), name="chat-gpt"),
    path("api/generate-links/", GenerateLinksView.as_view(), name="generate-links"),
    path("api/", include("database.urls")),
    path(
        "swagger/",
        schema_view.with_ui("swagger", cache_timeout=0),
        name="schema-swagger-ui",
    ),
]
