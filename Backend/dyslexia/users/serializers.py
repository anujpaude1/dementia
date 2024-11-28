from rest_framework import serializers
from django.utils import timezone
from .models import caretaker, Patient, Note
from django.contrib.auth import get_user_model, authenticate
from django.contrib.auth.password_validation import validate_password

# SignUpSerializer for creating caretaker or Patient
class SignUpSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=True, validators=[validate_password])
    user_type = serializers.ChoiceField(choices=['caretaker', 'patient'], write_only=True)
    photo = serializers.ImageField(required=False, allow_null=True)

    class Meta:
        model = get_user_model()  # Using custom user model
        fields = ['email', 'username', 'password', 'user_type', 'photo']

    def create(self, validated_data):
        user_type = validated_data.pop('user_type')
        # Create the user based on the provided type
        if user_type == 'caretaker':
            user = caretaker.objects.create_user(**validated_data)
        else:
            user = Patient.objects.create_user(**validated_data)

        return user


# Login Serializer for authentication
class LoginSerializer(serializers.Serializer):
    username = serializers.CharField()
    password = serializers.CharField(write_only=True)

    def validate(self, data):
        username = data.get('username')
        password = data.get('password')

        if not username or not password:
            raise serializers.ValidationError("Must include 'username' and 'password'")

        # Authenticate user
        user = authenticate(username=username, password=password)
        
        if not user:
            raise serializers.ValidationError("Invalid credentials")

        # Additional check to ensure user is either caretaker or patient
        is_caretaker = hasattr(user, 'caretaker') and isinstance(user.caretaker, caretaker)
        is_patient = hasattr(user, 'patient') and isinstance(user.patient, Patient)

        if not (is_caretaker or is_patient):
            raise serializers.ValidationError("Only caretakers and patients can log in")

        data['user'] = user
        return data

# Caretaker Serializer
class CaretakerSerializer(serializers.ModelSerializer):
    class Meta:
        model = caretaker
        fields = ['id', 'email', 'username', 'name', 'qualifications', 'experience_years', 'patients','photo']

# Patient Serializer

class PatientSerializer(serializers.ModelSerializer):
    class Meta:
        model = Patient
        fields = [
            'pk',
            'id', 
            'email', 
            'username', 
            'name', 
            'photo',
            
            # Physical details
            'height', 
            'weight', 
            'age',
            
            # Existing fields
            'medical_conditions', 
            'emergency_contact', 
            'goals',
            
            # Structured fields
            'medicines', 
            'appointments', 
            'notes'
        ]

    def validate_medicines(self, value):
        """
        Validate medicines data structure
        """
        if not isinstance(value, list):
            raise serializers.ValidationError("Medicines must be a list of dictionaries")
        
        for med in value:
            if not isinstance(med, dict):
                raise serializers.ValidationError("Each medicine must be a dictionary")
            
            required_keys = ['name', 'dosage', 'frequency']
            for key in required_keys:
                if key not in med:
                    raise serializers.ValidationError(f"Medicine must include {key}")
        
        return value

    def validate_appointments(self, value):
        """
        Validate appointments data structure
        """
        if not isinstance(value, list):
            raise serializers.ValidationError("Appointments must be a list of dictionaries")
        
        for appt in value:
            if not isinstance(appt, dict):
                raise serializers.ValidationError("Each appointment must be a dictionary")
            
            required_keys = ['date', 'time', 'description']
            for key in required_keys:
                if key not in appt:
                    raise serializers.ValidationError(f"Appointment must include {key}")
        
        return value

    def validate_notes(self, value):
        """
        Validate notes data structure
        """
        if not isinstance(value, list):
            raise serializers.ValidationError("Notes must be a list of dictionaries")
        
        for note in value:
            if not isinstance(note, dict):
                raise serializers.ValidationError("Each note must be a dictionary")
            
            required_keys = ['date', 'title', 'description']
            for key in required_keys:
                if key not in note:
                    raise serializers.ValidationError(f"Note must include {key}")
        
        return value

class AssignPatientSerializer(serializers.Serializer):
    patient_username = serializers.CharField(max_length=150)

class SignOutSerializer(serializers.Serializer):
    pass

class NoteSerializer(serializers.ModelSerializer):
    class Meta:
        model = Note
        fields = [
            'id',
            'title',
            'date', 
            'description',  
            'created_at', 
            'updated_at'
        ]
        read_only_fields = ['created_at', 'updated_at', 'id', 'date']
    
    def validate_date(self, value):
        """
        Ensure the date is not in the future
        """
        if value > timezone.now().date():
            raise serializers.ValidationError("Note date cannot be in the future.")
        return value
    
    def validate(self, data):
        """
        Additional cross-field validations
        """
        # If medication_related is True, ensure mode is appropriate
        if data.get('medication_related') and data.get('mode') not in ['medication', 'medical']:
            raise serializers.ValidationError({
                'medication_related': 'Medication-related notes should have mode as "medication" or "medical".'
            })
        
        # Ensure title and description are different
        if data.get('title') and data.get('description'):
            if data['title'].lower() == data['description'].lower():
                raise serializers.ValidationError({
                    'description': 'Description cannot be the same as the title.'
                })
        
        return data
    
    def create(self, validated_data):
        """
        Automatically assign the current patient
        """
        patient = self.context['request'].user.patient
        validated_data['patient'] = patient
        return super().create(validated_data)