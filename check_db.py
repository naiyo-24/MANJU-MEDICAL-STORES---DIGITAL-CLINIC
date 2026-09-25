from sqlalchemy import create_engine, text
from dotenv import load_dotenv
import os

load_dotenv('/Users/hypothticoder/manju_medicine_backend/.env')

DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "postgres")
DB_HOST = os.getenv("DB_HOST", "db")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "manju_medicine")
url = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

engine = create_engine(url)
with engine.connect() as conn:
    result = conn.execute(text("SELECT id, name, is_deleted FROM inventory_items LIMIT 5;"))
    for row in result:
        print(row)
