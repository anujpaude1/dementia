from rest_framework import serializers
from .models import Contact
from users.models import Patient, caretaker

class ContactSerializer(serializers.ModelSerializer):
    class Meta:
        model = Contact
        fields = ['id', 'name', 'phone_number', 'photo', 'relationship', 'created_at']
        read_only_fields = ['id', 'created_at']

    def create(self, validated_data):
        # Get the patient username from the request data
        patient_username = self.context.get('request').data.get('patient_username')
        
        # Get the current user (caretaker)
        caretaker = self.context.get('request').user

        try:
            # Fetch the patient
            patient = Patient.objects.get(username=patient_username)
            
            # Check if the caretaker is associated with this patient
            if not patient.caretakers.filter(id=caretaker.id).exists():
                raise serializers.ValidationError("You are not authorized to create contacts for this patient.")
            
            # Create contact and associate with patient
            contact = Contact.objects.create(patient=patient, **validated_data)
            return contact
        
        except Patient.DoesNotExist:
            raise serializers.ValidationError("Patient does not exist.")
