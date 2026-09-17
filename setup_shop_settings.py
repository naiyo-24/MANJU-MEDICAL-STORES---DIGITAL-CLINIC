import os

# 1. Create Model
model_content = """from sqlalchemy import Column, String, Text
from sqlalchemy.dialects.postgresql import UUID
import uuid
from models.base import Base

class ShopSettings(Base):
    __tablename__ = "shop_settings"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    shop_id = Column(UUID(as_uuid=True), nullable=True) # If null, applies globally for now
    shop_name = Column(String, nullable=True)
    tagline = Column(String, nullable=True)
    address = Column(Text, nullable=True)
    phone = Column(String, nullable=True)
    landline = Column(String, nullable=True)
    email = Column(String, nullable=True)
    gst_number = Column(String, nullable=True)
    
    bank_name = Column(String, nullable=True)
    branch_name = Column(String, nullable=True)
    ac_holder_name = Column(String, nullable=True)
    ac_number = Column(String, nullable=True)
    ifsc_code = Column(String, nullable=True)
    
    terms_1 = Column(Text, nullable=True)
    terms_2 = Column(Text, nullable=True)
    terms_3 = Column(Text, nullable=True)
    
    logo_url = Column(String, nullable=True)
    qr_url = Column(String, nullable=True)
"""
with open('/Users/sayarpaul/Project/manju_medicine_backend/models/shop_settings.py', 'w') as f:
    f.write(model_content)

# Update models/__init__.py
with open('/Users/sayarpaul/Project/manju_medicine_backend/models/__init__.py', 'a') as f:
    f.write("\nfrom .shop_settings import ShopSettings\n")

# 2. Create Schema
schema_content = """from pydantic import BaseModel
from typing import Optional
from uuid import UUID

class ShopSettingsBase(BaseModel):
    shop_name: Optional[str] = None
    tagline: Optional[str] = None
    address: Optional[str] = None
    phone: Optional[str] = None
    landline: Optional[str] = None
    email: Optional[str] = None
    gst_number: Optional[str] = None
    bank_name: Optional[str] = None
    branch_name: Optional[str] = None
    ac_holder_name: Optional[str] = None
    ac_number: Optional[str] = None
    ifsc_code: Optional[str] = None
    terms_1: Optional[str] = None
    terms_2: Optional[str] = None
    terms_3: Optional[str] = None
    logo_url: Optional[str] = None
    qr_url: Optional[str] = None

class ShopSettingsUpdate(ShopSettingsBase):
    pass

class ShopSettingsOut(ShopSettingsBase):
    id: UUID
    
    class Config:
        orm_mode = True
"""
with open('/Users/sayarpaul/Project/manju_medicine_backend/schemas/shop_settings.py', 'w') as f:
    f.write(schema_content)

# 3. Create Routes
route_content = """from fastapi import APIRouter, Depends, UploadFile, File, HTTPException
from sqlalchemy.orm import Session
from models import ShopSettings
from schemas.shop_settings import ShopSettingsOut, ShopSettingsUpdate
from dependencies import get_db
import shutil
import os

router = APIRouter(prefix="/api/admin/shop-settings", tags=["Shop Settings"])

@router.get("/", response_model=ShopSettingsOut)
def get_settings(db: Session = Depends(get_db)):
    settings = db.query(ShopSettings).first()
    if not settings:
        settings = ShopSettings()
        db.add(settings)
        db.commit()
        db.refresh(settings)
    return settings

@router.put("/", response_model=ShopSettingsOut)
def update_settings(data: ShopSettingsUpdate, db: Session = Depends(get_db)):
    settings = db.query(ShopSettings).first()
    if not settings:
        settings = ShopSettings()
        db.add(settings)
        
    for key, value in data.dict(exclude_unset=True).items():
        setattr(settings, key, value)
        
    db.commit()
    db.refresh(settings)
    return settings

@router.post("/upload/logo")
async def upload_logo(file: UploadFile = File(...), db: Session = Depends(get_db)):
    os.makedirs("uploads/shop", exist_ok=True)
    file_path = f"uploads/shop/logo_{file.filename}"
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    
    settings = db.query(ShopSettings).first()
    if not settings:
        settings = ShopSettings()
        db.add(settings)
    
    settings.logo_url = f"/{file_path}"
    db.commit()
    return {"url": settings.logo_url}

@router.post("/upload/qr")
async def upload_qr(file: UploadFile = File(...), db: Session = Depends(get_db)):
    os.makedirs("uploads/shop", exist_ok=True)
    file_path = f"uploads/shop/qr_{file.filename}"
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    
    settings = db.query(ShopSettings).first()
    if not settings:
        settings = ShopSettings()
        db.add(settings)
    
    settings.qr_url = f"/{file_path}"
    db.commit()
    return {"url": settings.qr_url}
"""
with open('/Users/sayarpaul/Project/manju_medicine_backend/routes/shop_settings.py', 'w') as f:
    f.write(route_content)
    
print("Created files successfully.")
