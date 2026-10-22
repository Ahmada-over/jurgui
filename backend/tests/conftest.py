import pytest_asyncio
from backend.app.main import app, lifespan


@pytest_asyncio.fixture(scope="session", autouse=True)
async def initialize_app_lifespan():
    async with lifespan(app):
        yield
