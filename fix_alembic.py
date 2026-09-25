import sys
import os
import subprocess
from sqlalchemy import create_engine, text
from dotenv import load_dotenv

load_dotenv('/Users/hypothticoder/manju_medicine_backend/.env')

DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "postgres")
DB_HOST = os.getenv("DB_HOST", "db")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "manju_medicine")
url = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

# 1. Drop from DB so Alembic can detect it
engine = create_engine(url)
with engine.connect() as conn:
    conn.execute(text("DROP INDEX IF EXISTS idx_inventory_shop_name;"))
    conn.execute(text("DROP INDEX IF EXISTS idx_inventory_shop_sku;"))
    conn.execute(text("ALTER TABLE inventory_items DROP COLUMN IF EXISTS is_deleted;"))
    conn.commit()

# 2. Add Index to models/inventory.py
model_file = '/Users/hypothticoder/manju_medicine_backend/models/inventory.py'
content = open(model_file).read()
if 'Index(' not in content:
    content = content.replace('from sqlalchemy import Column', 'from sqlalchemy import Column, Index')
    
    # find __tablename__ = "inventory_items"
    replacement = """    __tablename__ = "inventory_items"
    
    __table_args__ = (
        Index('idx_inventory_shop_name', 'shop_id', 'name'),
        Index('idx_inventory_shop_sku', 'shop_id', 'sku'),
    )"""
    content = content.replace('    __tablename__ = "inventory_items"', replacement)
    
    # Also add index=True to is_deleted if not there
    content = content.replace('is_deleted = Column(Integer, default=0)', 'is_deleted = Column(Integer, default=0, index=True)')
    
    open(model_file, 'w').write(content)

