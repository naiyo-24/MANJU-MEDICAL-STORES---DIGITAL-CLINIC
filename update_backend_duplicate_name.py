import re

routes_file = '/Users/hypothticoder/manju_medicine_backend/routes/shop_admin.py'
content = open(routes_file).read()

# Update add_inventory_item to check name as well as SKU
pattern = r'(existing_item = db\.query\(InventoryItem\)\.filter\(\s*InventoryItem\.shop_id == item_in\.shop_id,\s*)(InventoryItem\.sku == item_in\.sku)(\s*\)\.first\(\))'
match = re.search(pattern, content)

if match:
    # We will use sqlalchemy "or_" so we need to import it if not imported, or just use | operator
    new_query = "from sqlalchemy import or_\n    existing_item = db.query(InventoryItem).filter(\n        InventoryItem.shop_id == item_in.shop_id,\n        or_(InventoryItem.sku == item_in.sku, InventoryItem.name == item_in.name)\n    ).first()"
    content = content[:match.start()] + new_query + content[match.end():]
    
    # Also update the error message to mention name or SKU
    err_msg_pattern = r'detail="Medicine with this SKU already exists in this shop\."'
    content = re.sub(err_msg_pattern, 'detail="Medicine with this name or SKU already exists in this shop."', content)

    open(routes_file, 'w').write(content)
    print("Updated successfully")
else:
    print("Pattern not found")

