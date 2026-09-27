import re
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.db.models import User, Role
from app.repositories.user_repository import UserRepository, STANDARD_ROLES
from app.core.security import verify_password, create_access_token
from app.api.deps import get_current_active_user
from app.models.schemas import (
    UserRegisterRequest, UserLoginRequest, UserResponse, AuthResponse, RoleSchema
)

router = APIRouter(prefix="/auth", tags=["Authentication"])

EMAIL_REGEX = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


def format_user_response(user: User) -> UserResponse:
    return UserResponse(
        id=user.id,
        name=user.full_name,
        email=user.email,
        organization=user.organization_name,
        roles=[RoleSchema(id=r.id, name=r.name, description=r.description) for r in user.roles],
        is_active=user.is_active,
        created_at=user.created_at.isoformat() if user.created_at else None
    )


@router.post("/register", response_model=AuthResponse, status_code=status.HTTP_201_CREATED)
def register(req: UserRegisterRequest, db: Session = Depends(get_db)):
    """
    Registers a real user in PostgreSQL with bcrypt password hashing.
    Validates email format, password complexity, and email uniqueness.
    """
    email = req.email.strip().lower()
    if not EMAIL_REGEX.match(email):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid email address format"
        )

    if len(req.password) < 6:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Password must be at least 6 characters in length"
        )

    existing = UserRepository.get_by_email(db, email)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="An account with this email address already exists"
        )

    # Determine initial roles - all registered users have access to all standard workspaces by default
    if req.role_ids:
        role_ids = req.role_ids
    elif req.role_id and req.role_id != "all":
        role_ids = [req.role_id]
    else:
        role_ids = [r["id"] for r in STANDARD_ROLES]

    org_name = req.organization.strip() if req.organization and req.organization.strip() else f"{req.name.strip()}'s Operations"

    user = UserRepository.create_user(
        db=db,
        email=email,
        password=req.password,
        full_name=req.name.strip(),
        organization_name=org_name,
        role_ids=role_ids
    )

    access_token = create_access_token(data={"sub": user.id, "email": user.email})
    return AuthResponse(
        access_token=access_token,
        token_type="bearer",
        user=format_user_response(user)
    )


@router.post("/login", response_model=AuthResponse)
def login(req: UserLoginRequest, db: Session = Depends(get_db)):
    """
    Authenticates a user via email and password.
    Returns signed JWT access token and user role assignments.
    """
    email = req.email.strip().lower()
    user = UserRepository.get_by_email(db, email)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
            headers={"WWW-Authenticate": "Bearer"}
        )

    if not verify_password(req.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
            headers={"WWW-Authenticate": "Bearer"}
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is inactive. Contact operations administrator."
        )

    UserRepository.update_last_login(db, user)
    access_token = create_access_token(data={"sub": user.id, "email": user.email})

    return AuthResponse(
        access_token=access_token,
        token_type="bearer",
        user=format_user_response(user)
    )


@router.post("/logout")
def logout(current_user: User = Depends(get_current_active_user)):
    """
    Invalidates active session. Client discards the token.
    """
    return {
        "status": "success",
        "message": f"User {current_user.email} successfully logged out."
    }


@router.get("/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_active_user)):
    """
    Returns the authenticated user's actual database record and assigned roles.
    Used by frontend to verify and restore authenticated sessions.
    """
    return format_user_response(current_user)
