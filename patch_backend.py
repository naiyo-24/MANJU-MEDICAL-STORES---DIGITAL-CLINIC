import re

with open('/Users/hypothticoder/manju_medicine_backend/routes/shop_admin.py', 'r') as f:
    content = f.read()

# Replace the data parsing part
old_code = """
        for row in data_rows:
            # Expected columns: Name, SKU, Batch, Quantity, Price, Expiry (YYYY-MM-DD)
            if len(row) < 6:
                continue
                
            new_item = InventoryItem(
                tenant_id=admin_user.tenant_id,
                shop_id=shop_id,
                name=str(row[0]).strip(),
                sku=str(row[1]).strip(),
                batch_number=str(row[2]).strip(),
                stock_quantity=int(row[3]),
                unit_price=float(row[4]),
                expiry_date=row[5] 
            )
            db.add(new_item)
            items_added += 1
"""

new_code = """
        from datetime import datetime

        for row in data_rows:
            # Expected columns: Name, SKU, Batch, Quantity, Price, Expiry (YYYY-MM-DD)
            if len(row) < 6:
                continue
            
            try:
                stock_qty = int(row[3]) if str(row[3]).strip() else 0
            except ValueError:
                stock_qty = 0

            try:
                unit_price = float(row[4]) if str(row[4]).strip() else 0.0
            except ValueError:
                unit_price = 0.0

            exp = row[5]
            if isinstance(exp, str):
                try:
                    exp = datetime.strptime(exp.strip(), "%Y-%m-%d").date()
                except ValueError:
                    exp = datetime.utcnow().date()
            elif hasattr(exp, 'date'):
                exp = exp.date()
            elif hasattr(exp, 'to_pydatetime'):
                exp = exp.to_pydatetime().date()
            else:
                exp = datetime.utcnow().date()

            new_item = InventoryItem(
                tenant_id=admin_user.tenant_id,
                shop_id=shop_id,
                name=str(row[0]).strip() if row[0] else 'Unknown',
                sku=str(row[1]).strip() if row[1] else 'Unknown',
                batch_number=str(row[2]).strip() if row[2] else 'Unknown',
                stock_quantity=stock_qty,
                unit_price=unit_price,
                expiry_date=exp 
            )
            db.add(new_item)
            items_added += 1
"""

if old_code in content:
    content = content.replace(old_code, new_code)
    with open('/Users/hypothticoder/manju_medicine_backend/routes/shop_admin.py', 'w') as f:
        f.write(content)
    print("Patched successfully!")
else:
    print("Old code not found! Content preview:")
    print(content[content.find("for row in data_rows:") : content.find("for row in data_rows:") + 1000])

