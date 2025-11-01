"""
Start Django with Daphne for WebSocket support
This uses Daphne ASGI server which supports both HTTP and WebSocket
"""
import os
import sys

# Add project to path
BASE_DIR = r'c:\Users\Windows.11\Desktop\fullapp1\Full_App-main\Buses_BACK_END-main'
sys.path.insert(0, BASE_DIR)
os.chdir(BASE_DIR)

# Set Django settings
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'BusTrackingSystem.settings')

print("=" * 60)
print("  Starting Django with Daphne (WebSocket Support)")
print("=" * 60)
print()

# Run Daphne
from daphne.cli import CommandLineInterface

# Daphne command line arguments
sys.argv = [
    'daphne',
    '-b', '0.0.0.0',
    '-p', '8000',
    '--verbosity', '2',
    'BusTrackingSystem.asgi:application'
]

CommandLineInterface().run(sys.argv[1:])
