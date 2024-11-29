from rest_framework import permissions

class Iscaretaker(permissions.BasePermission):
    """
    Custom permission to only allow caretakers to access certain views.
    """
    def has_permission(self, request, view):
        return request.user.is_authenticated and hasattr(request.user, 'caretaker')

class IsPatient(permissions.BasePermission):
    """
    Custom permission to only allow patients to access certain views.
    """
    def has_permission(self, request, view):
        return request.user.is_authenticated and hasattr(request.user, 'patient')
    

class IsCaretakerOrReadOnlyForCenter(permissions.BasePermission):
    """
    Custom permission to allow only caretakers to modify center coordinates.
    """

    def has_permission(self, request, view):
        # Allow safe methods (GET, HEAD, OPTIONS) for all users
        if request.method in ['GET', 'HEAD', 'OPTIONS']:
            return True
        # Allow all users to create or update without center coordinates
        return True

    def has_object_permission(self, request, view, obj):
        # Check if user is a caretaker when modifying center coordinates
        center_fields = ['center_coordinates_lat', 'center_coordinates_long']
        if any(field in request.data for field in center_fields):
            if not request.user.is_caretaker:
                raise PermissionDenied("Only caretakers can set center coordinates.")
        return True