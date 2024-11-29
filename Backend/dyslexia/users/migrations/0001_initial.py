# Generated by Django 5.1.3 on 2024-11-29 09:44

import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
    ]

    operations = [
        migrations.CreateModel(
            name='BaseUser',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('password', models.CharField(max_length=128, verbose_name='password')),
                ('last_login', models.DateTimeField(blank=True, null=True, verbose_name='last login')),
                ('email', models.EmailField(max_length=254, unique=True)),
                ('username', models.CharField(max_length=255, unique=True)),
                ('name', models.CharField(blank=True, max_length=255, null=True)),
                ('is_active', models.BooleanField(default=True)),
                ('is_superuser', models.BooleanField(default=False)),
                ('is_staff', models.BooleanField(default=False)),
                ('photo', models.ImageField(blank=True, null=True, upload_to='media/profile_pics/')),
            ],
            options={
                'abstract': False,
            },
        ),
        migrations.CreateModel(
            name='Patient',
            fields=[
                ('baseuser_ptr', models.OneToOneField(auto_created=True, on_delete=django.db.models.deletion.CASCADE, parent_link=True, primary_key=True, serialize=False, to=settings.AUTH_USER_MODEL)),
                ('medical_conditions', models.TextField(blank=True, null=True)),
                ('emergency_contact', models.CharField(blank=True, max_length=255, null=True)),
                ('height', models.FloatField(blank=True, help_text='Height in centimeters', null=True)),
                ('weight', models.FloatField(blank=True, help_text='Weight in kilograms', null=True)),
                ('age', models.IntegerField(blank=True, null=True)),
                ('current_coordinates_lat', models.FloatField(blank=True, null=True)),
                ('current_coordinates_long', models.FloatField(blank=True, null=True)),
                ('center_coordinates_lat', models.FloatField(blank=True, null=True)),
                ('center_coordinates_long', models.FloatField(blank=True, null=True)),
                ('radius', models.FloatField(default=5.0)),
                ('goals', models.JSONField(blank=True, default=list, null=True)),
                ('medicines', models.JSONField(blank=True, default=list, null=True)),
                ('notes', models.JSONField(blank=True, default=list, null=True)),
                ('appointments', models.JSONField(blank=True, default=list, null=True)),
            ],
            options={
                'abstract': False,
            },
            bases=('users.baseuser',),
        ),
        migrations.CreateModel(
            name='Note',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('date', models.DateField(auto_now_add=True)),
                ('title', models.CharField(max_length=255)),
                ('description', models.TextField()),
                ('created_at', models.DateTimeField(auto_now_add=True, null=True)),
                ('updated_at', models.DateTimeField(auto_now=True, null=True)),
                ('patient', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='patient_notes', to='users.patient')),
            ],
            options={
                'verbose_name': 'Patient Note',
                'verbose_name_plural': 'Patient Notes',
                'ordering': ['-created_at'],
            },
        ),
        migrations.CreateModel(
            name='caretaker',
            fields=[
                ('baseuser_ptr', models.OneToOneField(auto_created=True, on_delete=django.db.models.deletion.CASCADE, parent_link=True, primary_key=True, serialize=False, to=settings.AUTH_USER_MODEL)),
                ('qualifications', models.CharField(blank=True, max_length=255, null=True)),
                ('experience_years', models.IntegerField(blank=True, null=True)),
                ('patients', models.ManyToManyField(blank=True, related_name='caretakers', to='users.patient')),
            ],
            options={
                'abstract': False,
            },
            bases=('users.baseuser',),
        ),
    ]
