#!/usr/bin/env python
"""
Simple script to run Django with basic HTTP server (no ASGI/Daphne)
This fixes the timeout issue with Daphne
"""
import os
import sys

# Set working directory
os.chdir(r'c:\Users\Windows.11\Desktop\fullapp1\Full_App-main\Buses_BACK_END-main')

# Set Django settings
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'BusTrackingSystem.settings')

# Temporarily disable ASGI
os.environ['DJANGO_USE_ASGI'] = 'False'

# Run Django with simple HTTP server
from django.core.management import execute_from_command_line

print("=" * 50)
print("  Starting Django with Simple HTTP Server")
print("=" * 50)

execute_from_command_line(['manage.py', 'runserver', '0.0.0.0:8000', '--noreload', '--insecure'])
