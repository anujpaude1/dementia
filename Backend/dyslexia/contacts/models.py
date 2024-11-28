from django.db import models
from users.models import Patient

class Contact(models.Model):
    patient = models.ForeignKey(
        Patient, 
        on_delete=models.CASCADE, 
        related_name="contacts"
    )
    name = models.CharField(max_length=100)
    phone_number = models.CharField(max_length=15)
    photo = models.ImageField(upload_to="contacts/photo", blank=True, null=True)
    relationship = models.CharField(max_length=50)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.name} ({self.relationship})"
