from rest_framework import generics, status
from rest_framework.views import APIView
from rest_framework.response import Response
from django.contrib.auth import login, authenticate
from .serializers import SignUpSerializer,NoteSerializer, LoginSerializer, PatientSerializer, CaretakerSerializer, AssignPatientSerializer,SignOutSerializer
from .models import caretaker, Patient,Note
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework.authtoken.models import Token
from rest_framework.permissions import AllowAny, IsAuthenticated
from users.permissions import Iscaretaker, IsPatient
from .permissions import IsCaretakerOrReadOnlyForCenter
import logging
import geopy
from geopy.distance import distance

logger = logging.getLogger(__name__)
# View to handle user registration (Sign Up)
class SignUpView(generics.CreateAPIView):
    permission_classes = [AllowAny]
    serializer_class = SignUpSerializer

    def create(self, request, *args, **kwargs):
        """
        Handle sign-up by creating a new user.
        """
        print("Request data")
        print(request.data)
        try:
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
            else:
                print("Serializer errors")
                print(serializer.errors)
                return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            print("An error occurred during user creation")
            print(str(e))
            return Response({"error": "An error occurred during user creation."}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


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
                {
                    "message": "Patient assigned successfully.",
                    "patient_details": PatientSerializer(patient, context={'request': request}).data
                },
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

    def post(self, request, *args, **kwargs):
        """
        Handle POST requests to set center coordinates for a patient.
        Only caretakers are allowed to set the center for their assigned patients.
        """
        user = request.user
        if not hasattr(user, 'caretaker') or not isinstance(user.caretaker, caretaker):
            return Response(
                {"error": "You are not authorized to set the center."},
                status=status.HTTP_403_FORBIDDEN
            )

        # Retrieve the patient ID and center coordinates from the request
        patient_id = request.data.get("patient_id")
        center_lat = request.data.get("center_coordinates_lat")
        center_long = request.data.get("center_coordinates_long")

        if not patient_id or not center_lat or not center_long:
            return Response(
                {"error": "Patient ID, latitude, and longitude are required."},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            # Check if the patient exists and if the caretaker is assigned to them
            patient = Patient.objects.get(id=patient_id, caretakers=user)
            patient.center_coordinates_lat = center_lat
            patient.center_coordinates_long = center_long
            patient.save()

            serializer = self.serializer_class(patient)
            return Response(
                {"message": "Center updated successfully.", "patient": serializer.data},
                status=status.HTTP_200_OK
            )
        except Patient.DoesNotExist:
            return Response({"error": "Patient not found or not assigned to you."}, status=status.HTTP_404_NOT_FOUND)
    

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

    def post(self, request, *args, **kwargs):
            """
            Handle updating caretaker details
            """
            instance = self.get_queryset().first()

            # Ensure the user is the caretaker
            if instance.id != request.user.id:
                return Response(
                    {"error": "You are not authorized to update this caretaker's details."},
                    status=status.HTTP_403_FORBIDDEN
                )

            serializer = self.serializer_class(instance, data=request.data, partial=True)
            if serializer.is_valid():
                serializer.save()
                return Response(serializer.data, status=status.HTTP_200_OK)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def get_queryset(self):
        """
        Return only the authenticated caretaker's details
        """
        return caretaker.objects.filter(id=self.request.user.id)
    
    
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

        distance_km = distance(center_point, current_point).km

        is_outside_geofence = distance_km > radius

        # Return user data
        serializer = PatientSerializer(patient)
        return Response({
            "is_outside_geofence": is_outside_geofence,
            "distance_from_center": distance_km
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

        # Calculate if the patient is outside the geofence
        center_point = (patient.center_coordinates_lat, patient.center_coordinates_long)
        current_point = (patient.current_coordinates_lat, patient.current_coordinates_long)
        radius = patient.radius
        distance_km = distance(center_point, current_point).km
        is_outside_geofence = distance_km > radius

        # Return patient's current location data along with geofence status
        location_data = {
            "current_coordinates_lat": patient.current_coordinates_lat,
            "current_coordinates_long": patient.current_coordinates_long,
            "radius": patient.radius,
            "center_coordinates_lat": patient.center_coordinates_lat,
            "center_coordinates_long": patient.center_coordinates_long,
            "is_outside_geofence": is_outside_geofence,
            "distance_from_center": distance_km
        }
        return Response(location_data, status=status.HTTP_200_OK)
        

    def post(self, request, patient_id):
        user = request.user
        if not hasattr(user, 'caretaker'):
            return Response({"error": "User is not a caretaker."}, status=status.HTTP_400_BAD_REQUEST)

        try:
            patient = Patient.objects.get(id=patient_id)
        except Patient.DoesNotExist:
            return Response({"error": "Patient not found."}, status=status.HTTP_404_NOT_FOUND)

        # Check if the caretaker is associated with the patient
        if not patient.caretakers.filter(id=user.id).exists():
            return Response({"error": "You are not authorized to update this patient's location."}, status=status.HTTP_403_FORBIDDEN)

        # Get new center location and radius from request data
        new_center_lat = request.data.get('center_coordinates_lat')
        new_center_long = request.data.get('center_coordinates_long')
        new_radius = request.data.get('radius')

        if new_center_lat is None or new_center_long is None or new_radius is None:
            return Response({"error": "Center coordinates and radius are required."}, status=status.HTTP_400_BAD_REQUEST)

        # Update patient's center location and radius in the database
        patient.center_coordinates_lat = new_center_lat
        patient.center_coordinates_long = new_center_long
        patient.radius = new_radius
        patient.save()

        return Response({"message": "Patient center location and radius updated successfully."}, status=status.HTTP_200_OK)



    

    



