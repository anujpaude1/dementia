from rest_framework import generics, status
from rest_framework.response import Response
from django.contrib.auth import login, authenticate
from .serializers import SignUpSerializer,NoteSerializer, LoginSerializer, PatientSerializer, CaretakerSerializer, AssignPatientSerializer,SignOutSerializer
from .models import caretaker, Patient,Note
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework.authtoken.models import Token
from rest_framework.permissions import AllowAny, IsAuthenticated
from users.permissions import Iscaretaker, IsPatient
import logging
import geopy

logger = logging.getLogger(__name__)
# View to handle user registration (Sign Up)
class SignUpView(generics.CreateAPIView):
    permission_classes = [AllowAny]
    serializer_class = SignUpSerializer

    def create(self, request, *args, **kwargs):
        """
        Handle sign-up by creating a new user.
        """
        print(request.data)
        serializer = self.get_serializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            # Generate token
            token, created = Token.objects.get_or_create(user=user)
            return Response({
                "message": "User created successfully. Please login.",
                "user_type": request.data.get('user_type'),
                "token": token.key,
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class LoginView(generics.GenericAPIView):
    serializer_class = LoginSerializer
    permission_classes = [AllowAny]

    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        user = authenticate(
            username=serializer.validated_data['username'],
            password=serializer.validated_data['password']
        )
        
        if user is not None:
            # Determine user type
            user_type = None
            if hasattr(user, 'caretaker') and isinstance(user.caretaker, caretaker):
                user_type = 'caretaker'
            elif hasattr(user, 'patient') and isinstance(user.patient, Patient):
                user_type = 'patient'
            
            # Ensure user is either a caretaker or patient
            if user_type is None:
                return Response(
                    {"error": "Invalid user type. Only caretakers and patients can log in."},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            # Generate or retrieve token
            token, created = Token.objects.get_or_create(user=user)
            
            return Response({
                'message': "Logged in successfully",
                'token': token.key,
                'user_id': user.pk,
                'email': user.email,
                'user_type': user_type
            }, status=status.HTTP_200_OK)
        else:
            return Response(
                {"error": "Invalid credentials"}, 
                status=status.HTTP_400_BAD_REQUEST
            )


class SignOutView(generics.GenericAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = SignOutSerializer

    def get(self, request, *args, **kwargs):
        """
        Handle user sign-out by deleting the authentication token.
        """
        try:
            # Get the token associated with the authenticated user
            token = Token.objects.get(user=request.user)
            token.delete()  # Delete the token to log out
            logger.debug(f"Token for user {request.user} deleted.")
            return Response({"message": "Successfully logged out."}, status=status.HTTP_200_OK)
        except Token.DoesNotExist:
            logger.debug(f"Token for user {request.user} not found.")
            return Response({"error": "Token not found."}, status=status.HTTP_400_BAD_REQUEST)

class AssignPatientView(generics.GenericAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = AssignPatientSerializer

    def post(self, request, *args, **kwargs):
        """
        Handle assigning a patient to a caretaker.
        """
        patient_username = request.data.get("patient_username")
        if not patient_username:
            return Response(
                {"error": "Patient ID is required."},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            patient = Patient.objects.get(username=patient_username)
            if patient.caretakers.filter(id=request.user.id).exists():
                return Response(
                    {"error": "Patient is already assigned to you."},
                    status=status.HTTP_400_BAD_REQUEST
                )
            patient.caretakers.add(request.user.id)
            return Response(
                {"message": "Patient assigned successfully."},
                status=status.HTTP_200_OK
            )
        except Patient.DoesNotExist:
            return Response(
                {"error": "Patient not found."},
                status=status.HTTP_404_NOT_FOUND
            )
        

class PatientListView(generics.ListAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = PatientSerializer
    
class PatientListView(generics.ListAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = PatientSerializer
    
    def get_queryset(self):
        """
        Return the list of patients for the authenticated user.
        If the user is a caretaker, return all patients assigned to them.
        If the user is a patient, return only their own details.
        """
        user = self.request.user
        try:
            # Check if the user is a Caretaker
            if hasattr(user, 'caretaker') and isinstance(user.caretaker, caretaker):
                return Patient.objects.filter(caretakers=user)
            
            # Check if the user is a Patient
            elif hasattr(user, 'patient') and isinstance(user.patient, Patient):
                return Patient.objects.filter(id=user.id)
            
            # Fallback for users with neither role
            print("User is neither caretaker nor patient")
            return Patient.objects.none()
        
        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    
    

class CaretakerDetailView(generics.RetrieveAPIView):
    permission_classes = [IsAuthenticated, Iscaretaker]
    serializer_class = CaretakerSerializer

    def get(self, request, *args, **kwargs):
        """
        Retrieve the caretaker details for the authenticated user.
        """
        try:
            caretaker_instance = caretaker.objects.get(id=request.user.id)
            serializer = self.get_serializer(caretaker_instance)
            return Response(serializer.data, status=status.HTTP_200_OK)
        except caretaker.DoesNotExist:
            return Response({"error": "Caretaker not found."}, status=status.HTTP_404_NOT_FOUND)


class UpdatePatientDetailsView(generics.UpdateAPIView):
    permission_classes = [IsAuthenticated, Iscaretaker]
    serializer_class = PatientSerializer

    def get_queryset(self):
        """
        Return only patients associated with the caretaker
        """
        return Patient.objects.filter(caretakers=self.request.user)

    def update(self, request, *args, **kwargs):
        """
        Handle updating patient details
        """
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        
        # Ensure the caretaker is associated with this patient
        if not instance.caretakers.filter(id=request.user.id).exists():
            return Response(
                {"error": "You are not authorized to update this patient's details."},
                status=status.HTTP_403_FORBIDDEN
            )

        serializer = self.get_serializer(instance, data=request.data, partial=True)
        if serializer.is_valid():
            self.perform_update(serializer)
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
class NoteListCreateView(generics.ListCreateAPIView):
    """
    View to list and create notes for a patient
    """
    permission_classes = [IsAuthenticated, IsPatient]
    serializer_class = NoteSerializer
    
    def get_queryset(self):
        """
        Return notes only for the authenticated patient
        """
        patient = self.request.user.patient
        return Note.objects.filter(patient=patient)

class NoteDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    View to retrieve, update, and delete a specific note
    """
    permission_classes = [IsAuthenticated, IsPatient]
    serializer_class = NoteSerializer
    
    def get_queryset(self):
        """
        Ensure only the patient's own notes can be accessed
        """
        patient = self.request.user.patient
        return Note.objects.filter(patient=patient)
    
class GeofenceView(generics.GenericAPIView):
    permission_classes = [IsAuthenticated, IsPatient]

    def post(self, request):
        user = request.user
        if not hasattr(user, 'patient'):
            return Response({"error": "User is not a patient."}, status=status.HTTP_400_BAD_REQUEST)

        patient = user.patient

        # Get current location from request data
        current_lat = request.data.get('current_lat')
        current_long = request.data.get('current_long')

        if current_lat is None or current_long is None:
            return Response({"error": "Current location is required."}, status=status.HTTP_400_BAD_REQUEST)

        # Update current location in the database
        patient.current_coordinates_lat = current_lat
        patient.current_coordinates_long = current_long
        patient.save()

        # Check if the user is outside the geofence
        center_point = (patient.center_coordinates_lat, patient.center_coordinates_long)
        current_point = (current_lat, current_long)
        radius = patient.radius

        distance = geopy.distance.distance(center_point, current_point).km

        is_outside_geofence = distance > radius

        # Return user data
        serializer = PatientSerializer(patient)
        return Response({
            "user_data": serializer.data,
            "is_outside_geofence": is_outside_geofence,
            "distance_from_center": distance
        }, status=status.HTTP_200_OK)


class PatientLocationView(generics.GenericAPIView):
    permission_classes = [IsAuthenticated, Iscaretaker]

    def get(self, request, patient_id):
        user = request.user
        if not hasattr(user, 'caretaker'):
            return Response({"error": "User is not a caretaker."}, status=status.HTTP_400_BAD_REQUEST)

        try:
            patient = Patient.objects.get(id=patient_id)
        except Patient.DoesNotExist:
            return Response({"error": "Patient not found."}, status=status.HTTP_404_NOT_FOUND)

        # Check if the caretaker is associated with the patient
        if not patient.caretakers.filter(id=user.id).exists():
            return Response({"error": "You are not authorized to view this patient's location."}, status=status.HTTP_403_FORBIDDEN)

        # Return patient's current location data
        location_data = {
            "current_coordinates_lat": patient.current_coordinates_lat,
            "current_coordinates_long": patient.current_coordinates_long,
            "radius": patient.radius,
            "center_coordinates_lat": patient.center_coordinates_lat,
            "center_coordinates_long": patient.center_coordinates_long
        }
        return Response(location_data, status=status.HTTP_200_OK)