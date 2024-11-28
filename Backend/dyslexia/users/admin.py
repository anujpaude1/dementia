from django.contrib import admin
from .models import caretaker, Patient

class PatientAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'medical_conditions', 'emergency_contact')  # Add 'id' here
    # You can customize other fields you want to display

# Register your models here.
admin.site.register(caretaker)
admin.site.register(Patient, PatientAdmin)