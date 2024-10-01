from .models.models import *
from .models.auth import CustomUser
from django.contrib import admin


@admin.register(Space)
class SpaceAdmin(admin.ModelAdmin):
    list_display = ["name", "description", "created_at", "owner"]
    search_fields = ["name", "owner__username"]
    autocomplete_fields = ["owner", "users"]
    list_filter = ["owner", "name"]


@admin.register(Device)
class DeviceAdmin(admin.ModelAdmin):
    list_display = ["name", "description", "added_at", "owner", "space"]
    search_fields = ["name", "owner__username"]
    autocomplete_fields = ["owner", "space"]
    list_filter = ["owner", "space"]


@admin.register(Command)
class CommandAdmin(admin.ModelAdmin):
    list_display = ["author", "description", "repeat_interval", "scheduled_at"]
    search_fields = ["description", "author__username"]
    autocomplete_fields = ["author", "devices"]
    list_filter = ["author", "scheduled_at"]


@admin.register(CommandsLink)
class CommandsLink(admin.ModelAdmin):
    list_display = ["ttl"]


@admin.register(CustomUser)
class CustomUserAdmin(admin.ModelAdmin):
    list_display = ["username", "is_device"]
    search_fields = ["username"]
    list_filter = ["is_device"]
