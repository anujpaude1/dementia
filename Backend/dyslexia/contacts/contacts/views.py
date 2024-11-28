from rest_framework import generics, status, serializers
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import Contact
from .serializers import ContactSerializer
from users.models import Patient
from users.permissions import Iscaretaker, IsPatient
import logging

logger = logging.getLogger(__name__)
class CaretakerContactView(generics.ListCreateAPIView):
    permission_classes = [IsAuthenticated, Iscaretaker]
    serializer_class = ContactSerializer

    def get_queryset(self):
        # Get patients associated with the current caretaker
        return Contact.objects.filter(patient__caretakers=self.request.user)

    def get_serializer_context(self):
        # Pass request to serializer context for validation
        context = super().get_serializer_context()
        context['request'] = self.request
        return context

class CaretakerContactDetailView(generics.RetrieveUpdateDestroyAPIView):
    permission_classes = [IsAuthenticated, Iscaretaker]
    serializer_class = ContactSerializer

    def get_queryset(self):
        # Ensure caretaker can only access contacts of their patients
        return Contact.objects.filter(patient__caretakers=self.request.user)

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['request'] = self.request
        return context

class PatientContactListView(generics.ListAPIView):
    permission_classes = [IsAuthenticated, IsPatient]
    serializer_class = ContactSerializer

    def get_queryset(self):
        # Patient can only see their own contacts
        return Contact.objects.filter(patient=self.request.user)