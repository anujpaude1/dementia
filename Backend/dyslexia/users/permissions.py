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