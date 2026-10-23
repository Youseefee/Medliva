from pydantic import BaseModel


class DeviceRegisterRequest(BaseModel):
    fcm_token: str
    platform: str = "android"
    app_version: str | None = None
