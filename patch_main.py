with open('/Users/sayarpaul/Project/manju_medicine_backend/main.py', 'r') as f:
    content = f.read()

import_line = "from routes.shop_admin import router as shop_admin_router"
new_import = import_line + "\nfrom routes.shop_settings import router as shop_settings_router"

mount_line = "app.include_router(shop_admin_router)"
new_mount = mount_line + "\napp.include_router(shop_settings_router)"

if "shop_settings_router" not in content:
    content = content.replace(import_line, new_import)
    content = content.replace(mount_line, new_mount)
    with open('/Users/sayarpaul/Project/manju_medicine_backend/main.py', 'w') as f:
        f.write(content)
    print("Patched main.py")
else:
    print("Already patched")
