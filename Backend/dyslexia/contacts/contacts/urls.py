from django.urls import path
from . import views
urlpatterns = [
    path('caretaker/', views.CaretakerContactView.as_view(), name='caretaker-contacts'),
    path('caretaker/<int:pk>/', views.CaretakerContactDetailView.as_view(), name='caretaker-contact-detail'),
    path('patient/', views.PatientContactListView.as_view(), name='patient-contacts'),
]