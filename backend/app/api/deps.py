from typing import Optional, List, Callable
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.db.models import User
from app.core.security import decode_access_token
from app.repositories.user_repository import UserRepository

# HTTPBearer extracts "Bearer <token>" from Authorization header
security_scheme = HTTPBearer(auto_error=False)


def get_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security_scheme),
    db: Session = Depends(get_db)
) -> User:
    if not credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required. Please provide a valid Bearer token.",
            headers={"WWW-Authenticate": "Bearer"}
        )

    token = credentials.credentials
    payload = decode_access_token(token)
    if not payload or "sub" not in payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired authentication token",
            headers={"WWW-Authenticate": "Bearer"}
        )

    user_id = payload["sub"]
    user = UserRepository.get_by_id(db, user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authenticated user no longer exists",
            headers={"WWW-Authenticate": "Bearer"}
        )

    return user


def get_current_user_optional(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security_scheme),
    db: Session = Depends(get_db)
) -> Optional[User]:
    if not credentials:
        return None
    try:
        token = credentials.credentials
        payload = decode_access_token(token)
        if not payload or "sub" not in payload:
            return None
        user_id = payload["sub"]
        return UserRepository.get_by_id(db, user_id)
    except Exception:
        return None


def get_current_active_user(current_user: User = Depends(get_current_user)) -> User:
    if not current_user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User account is deactivated"
        )
    return current_user


def require_role(required_role_id: str) -> Callable[[User], User]:
    """
    Role-Based Access Control (RBAC) Dependency.
    Ensures the authenticated user possesses the specific role permission.
    For RMC operations, matches 'rmc' or 'rmc_logistics_manager'.
    """
    def role_checker(user: User = Depends(get_current_active_user)) -> User:
        user_role_ids = {r.id.lower() for r in user.roles}
        
        # Allow aliasing between "rmc" and "rmc_logistics_manager"
        match_targets = {required_role_id.lower()}
        if required_role_id.lower() in ("rmc", "rmc_logistics_manager"):
            match_targets.update({"rmc", "rmc_logistics_manager"})

        if not any(target in user_role_ids for target in match_targets):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Access denied: This operation requires the '{required_role_id}' role permission."
            )
        return user

    return role_checker
