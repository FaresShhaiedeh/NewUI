#!/usr/bin/env python
import requests
import json

API_URL = "http://localhost:8000/api/buses/"

try:
    print("[*] Testing GET /api/buses/")
    response = requests.get(API_URL, timeout=5)
    print(f"    Status Code: {response.status_code}")
    print(f"    Response Length: {len(response.content)} bytes")
    
    if response.status_code == 200:
        data = response.json()
        print(f"    ✓ SUCCESS - Returned {len(data)} buses")
        if len(data) > 0:
            print(f"    First bus: {data[0]}")
    else:
        print(f"    ✗ FAILED - Status {response.status_code}")
        print(f"    Response: {response.text[:200]}")
        
except requests.exceptions.ConnectionError as e:
    print(f"    ✗ CONNECTION ERROR: {e}")
except requests.exceptions.Timeout:
    print(f"    ✗ TIMEOUT: Server took too long to respond")
except Exception as e:
    print(f"    ✗ ERROR: {e}")
