import re

with open('/Users/hypothticoder/manju_medicine_backend/routes/shop_admin.py', 'r') as f:
    content = f.read()

old_code = """
    if not file.filename.endswith(('.xlsx', '.xls')):
        raise HTTPException(status_code=400, detail="Only Excel files are supported for bulk inventory.")

    try:
        # Load the spooled file into calamine (memory-safe)
        workbook = python_calamine.CalamineWorkbook.from_filelike(file.file)
        sheet_name = workbook.sheet_names[0]
        rows = workbook.get_sheet_by_name(sheet_name).to_python(skip_empty_area=True)

        # Skip header row
        data_rows = rows[1:]
"""

new_code = """
    if not file.filename.endswith(('.xlsx', '.xls', '.csv')):
        raise HTTPException(status_code=400, detail="Only Excel and CSV files are supported for bulk inventory.")

    try:
        if file.filename.endswith('.csv'):
            import csv
            file.file.seek(0)
            decoded_file = (line.decode('utf-8') for line in file.file)
            reader = csv.reader(decoded_file)
            rows = list(reader)
        else:
            # Load the spooled file into calamine (memory-safe)
            workbook = python_calamine.CalamineWorkbook.from_filelike(file.file)
            sheet_name = workbook.sheet_names[0]
            rows = workbook.get_sheet_by_name(sheet_name).to_python(skip_empty_area=True)

        # Skip header row
        data_rows = rows[1:] if len(rows) > 1 else []
"""

if old_code in content:
    content = content.replace(old_code, new_code)
    with open('/Users/hypothticoder/manju_medicine_backend/routes/shop_admin.py', 'w') as f:
        f.write(content)
    print("Patched CSV successfully!")
else:
    print("Old code not found! Check content.")
