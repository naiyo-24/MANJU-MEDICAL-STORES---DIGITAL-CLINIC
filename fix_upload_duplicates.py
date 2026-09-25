import re

routes_file = '/Users/hypothticoder/manju_medicine_backend/routes/shop_admin.py'
content = open(routes_file).read()

# Let's replace the bulk upload logic to pre-fetch existing items and skip them
old_bulk_logic = """        items_added = 0
        batch_size = 1000 # Process in manageable batches
        
        from datetime import datetime

        for row in data_rows:"""

new_bulk_logic = """        items_added = 0
        batch_size = 1000 # Process in manageable batches
        
        from datetime import datetime
        
        # Pre-fetch existing names and SKUs for this shop to prevent bulk duplicates
        existing_records = db.query(InventoryItem.name, InventoryItem.sku).filter(
            InventoryItem.shop_id == shop_id
        ).all()
        
        existing_names = {r.name for r in existing_records if r.name}
        existing_skus = {r.sku for r in existing_records if r.sku and str(r.sku).strip() not in ["", "-"]}

        for row in data_rows:
            name_val = str(row[0]).strip() if row[0] else 'Unknown'
            sku_val = str(row[1]).strip() if row[1] else 'Unknown'
            
            # Skip if name or SKU is already in the database (or was added in a previous row of this sheet)
            if name_val in existing_names:
                continue
            if sku_val not in ["", "-", "Unknown"] and sku_val in existing_skus:
                continue
                
            # Add to set so we catch duplicates *within* the excel file itself
            existing_names.add(name_val)
            if sku_val not in ["", "-", "Unknown"]:
                existing_skus.add(sku_val)"""

# In the item creation, we need to use name_val and sku_val
old_creation = """            new_item = InventoryItem(
                tenant_id=admin_user.tenant_id,
                shop_id=shop_id,
                name=str(row[0]).strip() if row[0] else 'Unknown',
                sku=str(row[1]).strip() if row[1] else 'Unknown',"""

new_creation = """            new_item = InventoryItem(
                tenant_id=admin_user.tenant_id,
                shop_id=shop_id,
                name=name_val,
                sku=sku_val,"""

if old_bulk_logic in content:
    content = content.replace(old_bulk_logic, new_bulk_logic)
    content = content.replace(old_creation, new_creation)
    open(routes_file, 'w').write(content)
    print("Updated bulk upload successfully")
else:
    print("Bulk upload logic not found")
