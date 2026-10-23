from fastapi import APIRouter

from app.api.v1.endpoints import (
    adherence,
    ai,
    auth,
    caregiver,
    devices,
    emergency,
    inventory,
    medications,
    reports,
    users,
    vitals,
)

api_v1_router = APIRouter()
api_v1_router.include_router(auth.router)
api_v1_router.include_router(users.router)
api_v1_router.include_router(caregiver.router)
api_v1_router.include_router(medications.router)
api_v1_router.include_router(adherence.router)
api_v1_router.include_router(vitals.router)
api_v1_router.include_router(ai.router)
api_v1_router.include_router(inventory.router)
api_v1_router.include_router(emergency.router)
api_v1_router.include_router(reports.router)
api_v1_router.include_router(devices.router)
