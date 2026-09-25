with open('/Users/hypothticoder/manju_medicine_backend/main.py', 'r') as f:
    content = f.read()

if 'allow_origins=["*"],' in content and 'allow_credentials=True,' in content:
    content = content.replace('allow_origins=["*"],', 'allow_origins=["http://localhost:5194", "http://192.168.0.222:5194", "https://sirfapi.vwings247.me", "*"],')
    content = content.replace('allow_credentials=True,', 'allow_credentials=False,')

    with open('/Users/hypothticoder/manju_medicine_backend/main.py', 'w') as f:
        f.write(content)
    print("Patched CORS successfully")
else:
    print("Not found")
