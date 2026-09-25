import re

# 1. Update models/inventory.py
model_file = '/Users/hypothticoder/manju_medicine_backend/models/inventory.py'
content = open(model_file).read()
if 'is_deleted' not in content:
    content = content.replace('created_at = Column(DateTime, default=datetime.utcnow)', 
                              'created_at = Column(DateTime, default=datetime.utcnow)\n    is_deleted = Column(Integer, default=0)')
    content = content.replace('from sqlalchemy import Column, String, Float, Integer, Date, DateTime, ForeignKey',
                              'from sqlalchemy import Column, String, Float, Integer, Date, DateTime, ForeignKey, Boolean')
    # Actually wait, I used Integer instead of Boolean just in case SQLite prefers Integer, but Boolean is fine.
    open(model_file, 'w').read() if False else open(model_file, 'w').write(content)

# 2. Update routes/shop_admin.py
routes_file = '/Users/hypothticoder/manju_medicine_backend/routes/shop_admin.py'
content = open(routes_file).read()

# Update delete method to soft delete
delete_pattern = r'(@router\.delete\("/inventory/\{item_id\}/delete"\)\s*def delete_inventory_item\(.*?\):.*?)(?=@router|$)'
delete_match = re.search(delete_pattern, content, re.DOTALL)
if delete_match and 'is_deleted' not in delete_match.group(0):
    new_delete = delete_match.group(0).replace('db.delete(item)', 'item.is_deleted = 1')
    content = content[:delete_match.start()] + new_delete + content[delete_match.end():]

# Update get inventory method to filter out soft deleted items
get_pattern = r'(@router\.get\("/inventory"\)\s*def get_inventory\(.*?\):.*?)(?=@router|$)'
get_match = re.search(get_pattern, content, re.DOTALL)
if get_match and 'is_deleted' not in get_match.group(0):
    # Find the query
    query_pattern = r'query = db\.query\(InventoryItem\)\.filter\(InventoryItem\.shop_id == shop_id\)'
    if re.search(query_pattern, get_match.group(0)):
        new_get = get_match.group(0).replace('query = db.query(InventoryItem).filter(InventoryItem.shop_id == shop_id)',
                                             'query = db.query(InventoryItem).filter(InventoryItem.shop_id == shop_id, InventoryItem.is_deleted == 0)')
        content = content[:get_match.start()] + new_get + content[get_match.end():]

open(routes_file, 'w').write(content)
print("Updated successfully")
