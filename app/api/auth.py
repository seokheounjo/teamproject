from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.deps import get_db
from app.models.user import User
from app.services.auth import hash_pw, verify_pw, create_token

router = APIRouter()

@router.post("/register")
def register(email: str, name: str, password: str, db: Session = Depends(get_db)):
	if db.query(User).filter(User.email == email).first():
		raise HTTPException(400, "email exists")
	u = User(email=email, name=name, password_hash=hash_pw(password))
	db.add(u)
	db.commit()
	return {"ok": True}

@router.post("/login")
def login(email: str, password: str, db: Session = Depends(get_db)):
	u = db.query(User).filter(User.email == email).first()
	if not u or not verify_pw(password, u.password_hash):
		raise HTTPException(401, "invalid")
	token = create_token(str(u.id))
	return {"access_token": token, "token_type": "bearer"}
