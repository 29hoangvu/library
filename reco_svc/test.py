import os
from dotenv import load_dotenv

print("=== Before load_dotenv ===")
print(f"GOOGLE_API_KEY: {os.getenv('GOOGLE_API_KEY', 'NOT SET')}")

load_dotenv()

print("\n=== After load_dotenv ===")
print(f"GOOGLE_API_KEY: {os.getenv('GOOGLE_API_KEY', 'NOT SET')}")

# Check if .env file exists
import pathlib
env_path = pathlib.Path('.env')
print(f"\n.env exists: {env_path.exists()}")

if env_path.exists():
    print("\n=== .env content ===")
    with open('.env', 'r') as f:
        for line in f:
            if 'GOOGLE_API_KEY' in line or 'API_KEY' in line:
                print(line.strip())