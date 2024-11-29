from django.urls import path
import users.views as views

urlpatterns = [
    path('login/', views.LoginView.as_view(), name='login'),
    path('signup/', views.SignUpView.as_view(), name='signout'),
    path('logout/', views.SignOutView.as_view(), name='logout'),  # User logout
    path('assign/', views.AssignPatientView.as_view(), name='assign'),  # Assign patient to caretaker
    path('patient/', views.PatientListView.as_view(), name='patient-list'),  # List patients for caretaker
    path('caretaker/', views.CaretakerDetailView.as_view(), name='caretaker-detail'),  # Caretaker detail
    path('patient/<int:pk>/', views.UpdatePatientDetailsView.as_view(), name='update-patient'), 
    path('patient/notes/', views.NoteListCreateView.as_view(), name='update-patient'),
    path('patient/notes/<int:pk>', views.NoteDetailView.as_view(), name='update-patient'), 
    path('geofence/', views.GeofenceView.as_view(), name='geofence'),  # Geofence view for patients
    path('patient/<int:patient_id>/location/', views.PatientLocationView.as_view(), name='patient-location'), 
    # Get patient location
    
]