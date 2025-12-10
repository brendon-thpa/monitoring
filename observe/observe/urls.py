"""
URL configuration for observe project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/6.0/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path, include
from . import views

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', include('django_prometheus.urls')),
    path('sample/', include('sample.urls')),
    path('hello/', views.hello, name='hello'),
    path('fetch/', views.fetch, name='fetch'),
    path('health/', views.health, name='health'),
    path('error-500/', views.error_500, name='error_500'),
    path('raise-error/', views.raise_error, name='raise_error'),
    path('random-error/', views.random_error, name='random_error'),
    path('timeout/', views.timeout, name='timeout'),
    path('bad-request/', views.bad_request, name='bad_request'),
    path('redirect/', views.redirect, name='redirect'),
]
