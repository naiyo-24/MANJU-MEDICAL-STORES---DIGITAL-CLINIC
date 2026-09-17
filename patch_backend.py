import re

file_path = '/Users/sayarpaul/Project/manju_medicine_backend/routes/shop_admin.py'
with open(file_path, 'r') as f:
    content = f.read()

# Replace get_inventory function signature
old_sig = """async def get_inventory(
    shop_id: UUID,
    search: str = None,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):"""

new_sig = """async def get_inventory(
    shop_id: UUID,
    search: str = None,
    start_date: str = None,
    end_date: str = None,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):"""
content = content.replace(old_sig, new_sig)

# Add date filtering logic
old_logic = """    if search:
        query = query.filter(InventoryItem.name.ilike(f"%{search}%") | InventoryItem.sku.ilike(f"%{search}%"))
        
    total = query.count()"""

new_logic = """    if search:
        query = query.filter(InventoryItem.name.ilike(f"%{search}%") | InventoryItem.sku.ilike(f"%{search}%"))
        
    if start_date:
        query = query.filter(InventoryItem.created_at >= start_date)
        
    if end_date:
        # Add 23:59:59 to end_date if it's just YYYY-MM-DD
        end_date_str = end_date if "T" in end_date else f"{end_date}T23:59:59"
        query = query.filter(InventoryItem.created_at <= end_date_str)
        
    total = query.count()"""
content = content.replace(old_logic, new_logic)

with open(file_path, 'w') as f:
    f.write(content)
print("Patched backend successfully!")
