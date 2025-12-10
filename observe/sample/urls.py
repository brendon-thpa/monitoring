from django.urls import path, include
from . import views

urlpatterns = [
    path('', views.create_sample_model, name='create_sample'),
]