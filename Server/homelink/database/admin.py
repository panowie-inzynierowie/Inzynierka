from django.contrib import admin
from .models import HomeLinkUser, Space, Device


@admin.register(HomeLinkUser)
class HomeLinkUserAdmin(admin.ModelAdmin):
    list_display = ["username", "email", "created_at"]
    search_fields = ["username", "email"]
