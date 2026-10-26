from typing import AsyncGenerator
import ssl
from urllib.parse import urlparse, parse_qs, urlencode, urlunparse

from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.orm import declarative_base
from app.core.config import settings


def _prepare_postgres_url_and_ssl(raw_url: str, default_ssl: bool) -> tuple[str, dict]:
    """
    Normalise l'URL PostgreSQL (notamment Neon) pour le driver asyncpg :
    - Convertit postgres:// ou postgresql:// en postgresql+asyncpg://
    - Extrait sslmode / channel_binding (non supportés en query string par asyncpg)
    - Configure le contexte SSL si requis (Neon, DATABASE_SSL=True, ou sslmode=require)
    """
    url = raw_url.strip()
    if url.startswith("postgres://"):
        url = url.replace("postgres://", "postgresql+asyncpg://", 1)
    elif url.startswith("postgresql://"):
        url = url.replace("postgresql://", "postgresql+asyncpg://", 1)

    parsed = urlparse(url)
    query_params = parse_qs(parsed.query, keep_blank_values=True)

    sslmode_vals = query_params.pop("sslmode", [])
    query_params.pop("channel_binding", None)

    ssl_needed = (
        default_ssl
        or ("neon.tech" in (parsed.hostname or ""))
        or any(m in ("require", "verify-ca", "verify-full") for m in sslmode_vals)
    )
    if any(m == "disable" for m in sslmode_vals):
        ssl_needed = False
    if parsed.hostname in ("localhost", "127.0.0.1", "db") and not sslmode_vals:
        ssl_needed = False

    clean_query = urlencode(query_params, doseq=True)
    clean_url = urlunparse(parsed._replace(query=clean_query))

    connect_args: dict = {}
    if ssl_needed:
        ssl_ctx = ssl.create_default_context()
        ssl_ctx.check_hostname = False
        ssl_ctx.verify_mode = ssl.CERT_NONE
        connect_args["ssl"] = ssl_ctx

    return clean_url, connect_args


_db_url, connect_args = _prepare_postgres_url_and_ssl(
    settings.DATABASE_URL, settings.DATABASE_SSL
)

# Neon serverless: keep pool small, recycle before idle-timeout (5 min)
engine_kwargs: dict = {
    "echo": False,
    "connect_args": connect_args,
    "future": True,
    "pool_size": settings.DB_POOL_SIZE,
    "max_overflow": settings.DB_MAX_OVERFLOW,
    "pool_recycle": settings.DB_POOL_RECYCLE,
    "pool_pre_ping": True,  # detect stale connections after Neon scale-to-zero
}

engine = create_async_engine(_db_url, **engine_kwargs)

AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)

Base = declarative_base()


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()
