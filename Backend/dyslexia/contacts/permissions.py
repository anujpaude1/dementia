from rest_framework.permissions import BasePermission


class IscaretakerOrReadOnly(BasePermission):
    """
    Custom permission to allow only caretakers full access,
    and patients read-only access.
    """

    def has_permission(self, request, view):
        if request.method in ['GET', 'HEAD', 'OPTIONS']:
            return True  
        return hasattr(request.user, 'caretaker')

    def has_object_permission(self, request, view, obj):
        if request.method in ['GET', 'HEAD', 'OPTIONS']:
            return obj.caretaker.user == request.user
        return obj.caretaker.user == request.user