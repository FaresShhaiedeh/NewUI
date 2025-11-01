# bus_tracking/admin.py

from django.contrib import admin
from .models import Bus, BusLine, BusStop, Location, BusLocationLog, Alert, BusLineStop

# Register your models here.
admin.site.register(Bus)
admin.site.register(BusLine)
admin.site.register(BusStop)
admin.site.register(Location)
admin.site.register(BusLocationLog) # New log model
admin.site.register(Alert)
admin.site.register(BusLineStop)