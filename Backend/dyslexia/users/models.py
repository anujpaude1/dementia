from django.db import models
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager

# Custom manager for user creation
class CustomUserManager(BaseUserManager):
    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError("The Email field must be set")
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('is_staff', True)
        return self.create_user(email, password, **extra_fields)

# Abstract User model
class BaseUser(AbstractBaseUser):
    email = models.EmailField(unique=True)
    username = models.CharField(max_length=255, unique=True)
    name = models.CharField(max_length=255, blank=True, null=True)
    is_active = models.BooleanField(default=True)
    is_superuser = models.BooleanField(default=False)
    is_staff = models.BooleanField(default=False)  # Required for admin access
    photo = models.ImageField(upload_to='profile_pics/', blank=True, null=True)
    
    USERNAME_FIELD = 'username'
    REQUIRED_FIELDS = ['email']

    objects = CustomUserManager()

    def has_module_perms(self, app_label):
        return True

    def has_perm(self, perm, obj=None):
        return True

# Caretaker User
class caretaker(BaseUser):
    qualifications = models.CharField(max_length=255, blank=True, null=True)
    experience_years = models.IntegerField(null=True, blank=True)
    patients = models.ManyToManyField('Patient', related_name='caretakers', blank=True)

# Patient User
class Patient(BaseUser):
    medical_conditions = models.TextField(null=True, blank=True)
    emergency_contact = models.CharField(max_length=255, null=True, blank=True)
    height = models.FloatField(null=True, blank=True, help_text="Height in centimeters")
    weight = models.FloatField(null=True, blank=True, help_text="Weight in kilograms")
    age = models.IntegerField(null=True, blank=True)
    current_coordinates_lat = models.FloatField(null=True, blank=True)
    current_coordinates_long = models.FloatField(null=True, blank=True)
    center_coordinates_lat = models.FloatField(null=True, blank=True)
    center_coordinates_long = models.FloatField(null=True, blank=True)
    radius = models.FloatField(default=5.0)

    # JSON structured fields
    goals = models.JSONField(default=list, blank=True, null=True)
    medicines = models.JSONField(default=list, blank=True, null=True)
    notes = models.JSONField(default=list, blank=True, null=True)
    appointments = models.JSONField(default=list, blank=True, null=True)

    # Enforcing specific structure for JSON fields
    def save(self, *args, **kwargs):
        self.medicines = self.validate_medicines(self.medicines)
        self.appointments = self.validate_appointments(self.appointments)
        self.notes = self.validate_notes(self.notes)
        super().save(*args, **kwargs)

    @staticmethod
    def validate_medicines(medicines):
        if not isinstance(medicines, list):
            raise ValueError("Medicines must be a list of dictionaries")
        for medicine in medicines:
            if not isinstance(medicine, dict):
                raise ValueError("Each medicine must be a dictionary")
            required_keys = ['name', 'dosage', 'frequency']
            for key in required_keys:
                if key not in medicine:
                    raise ValueError(f"Each medicine must include {key}")
        return medicines

    @staticmethod
    def validate_appointments(appointments):
        if not isinstance(appointments, list):
            raise ValueError("Appointments must be a list of dictionaries")
        for appointment in appointments:
            if not isinstance(appointment, dict):
                raise ValueError("Each appointment must be a dictionary")
            required_keys = ['date', 'time', 'description']
            for key in required_keys:
                if key not in appointment:
                    raise ValueError(f"Each appointment must include {key}")
        return appointments

    @staticmethod
    def validate_notes(notes):
        if not isinstance(notes, list):
            raise ValueError("Notes must be a list of dictionaries")
        for note in notes:
            if not isinstance(note, dict):
                raise ValueError("Each note must be a dictionary")
            required_keys = ['date', 'title', 'description', 'created_at','updated_at']
            for key in required_keys:
                if key not in note:
                    raise ValueError(f"Each note must include {key}")
                
        return notes
    
class Note(models.Model):
    patient = models.ForeignKey(
        Patient, 
        on_delete=models.CASCADE, 
        related_name='patient_notes'
    )
    date = models.DateField(auto_now_add = True)
    title = models.CharField(max_length=255)
    description = models.TextField()
    
    created_at = models.DateTimeField(auto_now_add=True, null=True, blank=True)
    updated_at = models.DateTimeField(auto_now=True, null=True, blank=True)
    
    def __str__(self):
        return f"{self.patient.username} - {self.title}"
    
    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Patient Note'
        verbose_name_plural = 'Patient Notes'
