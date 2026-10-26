from datetime import UTC, datetime
from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user
from app.core.errors import AppError
from app.db.session import get_db
from app.models.devices import Device
from app.models.user import User
from app.schemas.devices import DeviceRegisterRequest

router = APIRouter(tags=["devices"])


@router.post("/devices")
async def register_device(
    payload: DeviceRegisterRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> dict[str, str]:
    stmt = select(Device).where(Device.fcm_token == payload.fcm_token)
    res = await db.execute(stmt)
    device = res.scalar_one_or_none()

    now = datetime.now(UTC)
    if device:
        # A token registered to another user must not be silently
        # transferred: that would hijack push notifications for that
        # device. Re-registering your own device is still allowed.
        if device.user_id != current_user.id:
            raise AppError(
                403,
                "DEVICE_BELONGS_TO_ANOTHER_USER",
                "هذا الجهاز مسجل لمستخدم آخر",
            )
        device.platform = payload.platform
        device.app_version = payload.app_version
        device.last_seen = now
    else:
        device = Device(
            user_id=current_user.id,
            fcm_token=payload.fcm_token,
            platform=payload.platform,
            app_version=payload.app_version,
            last_seen=now,
        )
        db.add(device)

    await db.commit()
    return {"status": "success", "message": "تم تسجيل الجهاز بنجاح"}
