# Generated by Django 4.2.11 on 2024-10-10 19:17

from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ("database", "0006_remove_command_devices_command_device"),
    ]

    operations = [
        migrations.AddField(
            model_name="commandslink",
            name="owner",
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                to=settings.AUTH_USER_MODEL,
            ),
        ),
    ]
