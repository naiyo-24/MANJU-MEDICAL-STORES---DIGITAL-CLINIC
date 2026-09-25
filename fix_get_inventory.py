import re

routes_file = '/Users/hypothticoder/manju_medicine_backend/routes/shop_admin.py'
content = open(routes_file).read()

old_query = "query = db.query(InventoryItem).filter(InventoryItem.shop_id == shop_id)"
new_query = "query = db.query(InventoryItem).filter(InventoryItem.shop_id == shop_id, InventoryItem.is_deleted == 0)"

if old_query in content:
    content = content.replace(old_query, new_query)
    open(routes_file, 'w').write(content)
    print("Updated get_inventory successfully")
else:
    print("Could not find get_inventory query")
