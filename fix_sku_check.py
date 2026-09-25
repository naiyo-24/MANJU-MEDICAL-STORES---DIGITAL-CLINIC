import re

routes_file = '/Users/hypothticoder/manju_medicine_backend/routes/shop_admin.py'
content = open(routes_file).read()

# Replace the or_ logic to handle empty SKUs gracefully
old_query = """from sqlalchemy import or_
    existing_item = db.query(InventoryItem).filter(
        InventoryItem.shop_id == item_in.shop_id,
        or_(InventoryItem.sku == item_in.sku, InventoryItem.name == item_in.name)
    ).first()"""

new_query = """from sqlalchemy import or_, and_
    conditions = [InventoryItem.name == item_in.name]
    # Only check for duplicate SKU if the SKU actually contains a value (ignoring common defaults like '-' or empty)
    if item_in.sku and item_in.sku.strip() not in ["", "-"]:
        conditions.append(InventoryItem.sku == item_in.sku)
        
    existing_item = db.query(InventoryItem).filter(
        InventoryItem.shop_id == item_in.shop_id,
        or_(*conditions)
    ).first()"""

content = content.replace(old_query, new_query)

open(routes_file, 'w').write(content)
print("Updated successfully")
