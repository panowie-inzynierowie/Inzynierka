# Generated by Django 4.2.11 on 2024-10-19 12:18

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("database", "0008_command_self_execute"),
    ]

    operations = [
        migrations.AddField(
            model_name="command",
            name="executed",
            field=models.BooleanField(default=False),
        ),
    ]
