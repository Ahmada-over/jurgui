from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse
from sqlalchemy import select, text

from app.core.config import settings
from app.core.database import engine, Base, AsyncSessionLocal
from app.core.security import get_password_hash
import app.models  # Ensures all 24 models are registered on Base.metadata
from app.models.user import User, UserRole
from app.models.breed import Breed
from app.models.sector import Sector
from app.models.feed import FeedProduct
from app.models.animal import Animal

from app.api.v1.auth import router as auth_router
from app.api.v1.breeds import router as breeds_router
from app.api.v1.sectors import router as sectors_router
from app.api.v1.animals import router as animals_router
from app.api.v1.reproduction import router as reproduction_router
from app.api.v1.feed import router as feed_router
from app.api.v1.health import router as health_router
from app.api.v1.tasks import router as tasks_router
from app.api.v1.finances import router as finances_router
from app.api.v1.dashboard import router as dashboard_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: Create tables if not existing
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
        try:
            await conn.execute(text("ALTER TABLE animals ALTER COLUMN photo_url TYPE TEXT"))
        except Exception:
            pass
        try:
            await conn.execute(text("ALTER TABLE animals ADD COLUMN IF NOT EXISTS lineage VARCHAR(120)"))
        except Exception:
            pass

    # Seed initial data (Admin user, Breeds, Sectors, Feed catalog)
    async with AsyncSessionLocal() as session:
        # 1. Admin user
        admin_check = await session.execute(select(User).where(User.email == "admin@jurgui.sn"))
        if not admin_check.scalars().first():
            default_admin = User(
                email="admin@jurgui.sn",
                full_name="Administrateur Jur-gui",
                hashed_password=get_password_hash("admin1234"),
                role=UserRole.ADMIN.value,
                phone="+221770000000",
                is_active=True
            )
            session.add(default_admin)

        # 2. Breeds
        for breed_name in settings.INITIAL_BREEDS:
            breed_check = await session.execute(select(Breed).where(Breed.name == breed_name))
            if not breed_check.scalars().first():
                session.add(Breed(name=breed_name, is_active=True))

        # 3. Sectors
        for sec_data in settings.INITIAL_SECTORS:
            sec_check = await session.execute(select(Sector).where(Sector.name == sec_data["name"]))
            if not sec_check.scalars().first():
                session.add(Sector(
                    name=sec_data["name"],
                    description=sec_data["description"],
                    estimated_capacity=sec_data["estimated_capacity"],
                    status="active"
                ))

        # 4. Standard Feed Catalog
        initial_feeds = [
            {"name": "Son de blé", "category": "concentrate", "unit": "kg", "unit_price_cfa": 250.0, "current_stock": 500.0, "min_stock_threshold": 50.0},
            {"name": "Tourteau de coton", "category": "concentrate", "unit": "kg", "unit_price_cfa": 350.0, "current_stock": 300.0, "min_stock_threshold": 40.0},
            {"name": "Fanes d'arachide", "category": "forage", "unit": "botte", "unit_price_cfa": 1500.0, "current_stock": 100.0, "min_stock_threshold": 15.0},
            {"name": "Fanes de niébé", "category": "forage", "unit": "botte", "unit_price_cfa": 1800.0, "current_stock": 80.0, "min_stock_threshold": 10.0},
            {"name": "Bloc minéral / Pierre à lécher", "category": "mineral", "unit": "piece", "unit_price_cfa": 4000.0, "current_stock": 20.0, "min_stock_threshold": 5.0},
            {"name": "Ripasse (Litière copeaux)", "category": "supplement", "unit": "sac", "unit_price_cfa": 1000.0, "current_stock": 50.0, "min_stock_threshold": 10.0},
        ]
        for feed in initial_feeds:
            feed_check = await session.execute(select(FeedProduct).where(FeedProduct.name == feed["name"]))
            if not feed_check.scalars().first():
                session.add(FeedProduct(**feed))

        await session.commit()

    yield


app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="API de gestion de cheptel ovin pour l'Élevage Intelligent – Dakar (Jur-gui)",
    lifespan=lifespan,
)

# CORS configuration for Flutter Mobile & Web clients
_origins = [o.strip() for o in settings.ALLOWED_ORIGINS.split(",") if o.strip()]
app.add_middleware(
    CORSMiddleware,
    allow_origins=_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount API Routers
app.include_router(auth_router, prefix=settings.API_V1_STR)
app.include_router(breeds_router, prefix=settings.API_V1_STR)
app.include_router(sectors_router, prefix=settings.API_V1_STR)
app.include_router(animals_router, prefix=settings.API_V1_STR)
app.include_router(reproduction_router, prefix=settings.API_V1_STR)
app.include_router(feed_router, prefix=settings.API_V1_STR)
app.include_router(health_router, prefix=settings.API_V1_STR)
app.include_router(tasks_router, prefix=settings.API_V1_STR)
app.include_router(finances_router, prefix=settings.API_V1_STR)
app.include_router(dashboard_router, prefix=settings.API_V1_STR)


@app.get("/health", tags=["Health"])
async def health_check():
    return {
        "status": "healthy",
        "app": settings.PROJECT_NAME,
        "version": settings.VERSION,
        "environment": settings.ENVIRONMENT,
    }


@app.get("/terms", response_class=HTMLResponse, tags=["Legal"])
async def terms_of_use():
    return """<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Conditions Générales d'Utilisation — Jur-gui</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #F6F8F6; color: #0F172A; margin: 0; padding: 32px 16px; line-height: 1.6; }
    .card { max-width: 760px; margin: 0 auto; background: #FFFFFF; border-radius: 20px; padding: 32px; border: 1px solid #E2E8F0; }
    h1 { color: #0D3B2E; margin-top: 0; }
    h2 { color: #0D3B2E; font-size: 1.15rem; margin-top: 24px; }
    .subtitle { color: #475569; font-size: 0.95rem; margin-bottom: 24px; }
  </style>
</head>
<body>
  <div class="card">
    <h1>Conditions Générales d'Utilisation (CGU)</h1>
    <p class="subtitle">Plateforme Jur-gui — Gestion de Cheptel Ovin (Dakar, Sénégal)</p>
    <h2>1. Objet de l'application Jur-gui</h2>
    <p>Jur-gui est une application professionnelle de gestion de cheptel ovin (races Ladoum, Métis Ladoum, Peulh Peulh et autres races ovines) destinée aux éleveurs, bergers et vétérinaires. Elle permet le suivi individuel des animaux, de la généalogie, des pesées, des enclos, des saillies, des gestations et des mises bas.</p>
    <h2>2. Accès et création de compte</h2>
    <p>L'accès à l'application nécessite la création d'un compte utilisateur (Propriétaire/Administrateur, Vétérinaire ou Employé d'élevage). L'utilisateur s'engage à fournir des informations exactes et à conserver la confidentialité de ses identifiants de connexion.</p>
    <h2>3. Utilisation et responsabilité métier</h2>
    <p>Les indicateurs, comptes à rebours de gestation (cycle indicatif de 150 jours) et alertes affichés dans Jur-gui constituent des outils d'aide au suivi d'exploitation. Ils ne remplacent en aucun cas le diagnostic, la prescription ou l'intervention d'un docteur vétérinaire agréé.</p>
    <h2>4. Propriété des données de l'élevage</h2>
    <p>L'éleveur conserve l'entière propriété des données saisies concernant son cheptel (fiches animales, photographies, généalogie, historique de reproduction et de croissance).</p>
    <h2>5. Disponibilité et sécurité</h2>
    <p>Nous mettons en œuvre les meilleures pratiques techniques pour assurer la disponibilité continue du service et la sauvegarde sécurisée des données de la bergerie.</p>
    <h2>6. Droit applicable et contact</h2>
    <p>Les présentes Conditions Générales d'Utilisation sont régies par le droit sénégalais. Contact : support@jurgui.sn.</p>
  </div>
</body>
</html>"""


@app.get("/privacy", response_class=HTMLResponse, tags=["Legal"])
async def privacy_policy():
    return """<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Politique de Confidentialité — Jur-gui</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #F6F8F6; color: #0F172A; margin: 0; padding: 32px 16px; line-height: 1.6; }
    .card { max-width: 760px; margin: 0 auto; background: #FFFFFF; border-radius: 20px; padding: 32px; border: 1px solid #E2E8F0; }
    h1 { color: #0D3B2E; margin-top: 0; }
    h2 { color: #0D3B2E; font-size: 1.15rem; margin-top: 24px; }
    .subtitle { color: #475569; font-size: 0.95rem; margin-bottom: 24px; }
  </style>
</head>
<body>
  <div class="card">
    <h1>Politique de Confidentialité</h1>
    <p class="subtitle">Plateforme Jur-gui — Protection des données personnelles et d'exploitation</p>
    <h2>1. Données collectées</h2>
    <p>Dans le cadre du fonctionnement de Jur-gui, seules les données strictement nécessaires à la gestion de votre élevage sont collectées : nom complet, adresse email, numéro de téléphone professionnel, rôle dans l'élevage, ainsi que les fiches d'identification des ovins, photographies des animaux, pesées, généalogie et événements de reproduction.</p>
    <h2>2. Utilisation de l'appareil photo et de la galerie</h2>
    <p>L'accès à l'appareil photo ou à la photothèque du téléphone est utilisé exclusivement lorsque vous choisissez d'associer une photo d'identification à la fiche d'un ovin. Aucune photo n'est collectée en arrière-plan.</p>
    <h2>3. Hébergement et sécurité des données</h2>
    <p>Les mots de passe sont hachés de manière irréversible (bcrypt). Les échanges entre l'application mobile et le serveur sont chiffrés via HTTPS/TLS, et la base de données PostgreSQL est protégée par authentification et chiffrement SSL.</p>
    <h2>4. Absence de partage ou de revente</h2>
    <p>Vos données personnelles ainsi que les données généalogiques et zootechniques de votre bergerie sont strictement confidentielles. Elles ne sont ni vendues, ni louées, ni cédées à des tiers publicitaires.</p>
    <h2>5. Vos droits (Accès, Modification, Suppression)</h2>
    <p>Conformément à la réglementation sur la protection des données personnelles (Loi n° 2008-12 au Sénégal / principes RGPD), vous pouvez à tout moment modifier vos informations depuis l'onglet « Profil » de l'application ou demander la suppression complète de votre compte et de vos données à l'adresse : support@jurgui.sn.</p>
  </div>
</body>
</html>"""


@app.get("/pedigree/{animal_id}", response_class=HTMLResponse, tags=["Pedigree Public"])
async def public_pedigree_page(animal_id: str):
    from sqlalchemy.orm import selectinload

    async with AsyncSessionLocal() as session:
        query = (
            select(Animal)
            .options(
                selectinload(Animal.breed),
                selectinload(Animal.mother),
                selectinload(Animal.father),
            )
            .where(Animal.id == animal_id)
        )
        res = await session.execute(query)
        animal = res.scalars().first()
        if not animal:
            return HTMLResponse(
                content="<h1>Ovin introuvable</h1>",
                status_code=404,
            )

        breed_name = animal.breed.name if animal.breed else "Race Ovine"
        sex_label = "Brebis (Femelle)" if animal.sex == "female" else "Bélier (Mâle)"
        lineage_label = animal.lineage or "Lignée certifiée Jur-gui"
        father_label = (
            f"{animal.father.name} ({animal.father.id})"
            if animal.father
            else (animal.father_id or "Non répertorié")
        )
        mother_label = (
            f"{animal.mother.name} ({animal.mother.id})"
            if animal.mother
            else (animal.mother_id or "Non répertoriée")
        )
        weight_label = f"{animal.current_weight_kg:.1f} kg" if animal.current_weight_kg else "Non communiqué"
        tag_label = animal.physical_tag or animal.id

        return f"""<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Certificat de Lignée — {animal.name} ({animal.id}) | Jur-gui</title>
  <style>
    body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #09221A; color: #FFFFFF; margin: 0; padding: 24px 16px; }}
    .cert {{ max-width: 540px; margin: 0 auto; background: linear-gradient(145deg, #0D3B2E, #071F18); border: 2px solid #D4AF37; border-radius: 28px; padding: 28px; box-shadow: 0 20px 50px rgba(0,0,0,0.45); }}
    .badge {{ display: inline-block; background: rgba(212,175,55,0.18); color: #F3D36B; border: 1px solid #D4AF37; padding: 5px 14px; border-radius: 99px; font-size: 12px; font-weight: 800; letter-spacing: 0.8px; text-transform: uppercase; }}
    h1 {{ font-size: 28px; margin: 14px 0 4px; color: #FFFFFF; }}
    .sub {{ color: #A7F3D0; font-weight: 600; font-size: 14px; margin-bottom: 18px; }}
    .lineage-box {{ background: rgba(212,175,55,0.12); border-left: 4px solid #D4AF37; padding: 14px 16px; border-radius: 12px; margin-bottom: 20px; }}
    .lineage-title {{ font-size: 11px; text-transform: uppercase; letter-spacing: 1px; color: #F3D36B; font-weight: 700; }}
    .lineage-val {{ font-size: 18px; font-weight: 800; color: #FFFFFF; margin-top: 2px; }}
    .grid {{ display: grid; grid-template-columns: 1fr 1fr; gap: 12px; margin-bottom: 20px; }}
    .box {{ background: rgba(255,255,255,0.06); border: 1px solid rgba(255,255,255,0.12); border-radius: 16px; padding: 12px 14px; }}
    .lbl {{ font-size: 11px; color: #94A3B8; text-transform: uppercase; font-weight: 700; }}
    .val {{ font-size: 15px; font-weight: 800; color: #FFFFFF; margin-top: 4px; }}
    .parents {{ display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }}
    .parent-sire {{ background: rgba(59,130,246,0.12); border: 1px solid rgba(96,165,250,0.35); border-radius: 16px; padding: 14px; }}
    .parent-dam {{ background: rgba(236,72,153,0.12); border: 1px solid rgba(244,114,182,0.35); border-radius: 16px; padding: 14px; }}
    .footer {{ text-align: center; margin-top: 24px; padding-top: 16px; border-top: 1px solid rgba(255,255,255,0.12); font-size: 12px; color: #94A3B8; }}
  </style>
</head>
<body>
  <div class="cert">
    <span class="badge">Certificat Généalogique • Jur-gui Dakar</span>
    <h1>{animal.name}</h1>
    <div class="sub">{breed_name} • {sex_label}</div>
    <div class="lineage-box">
      <div class="lineage-title">Lignée / Sang</div>
      <div class="lineage-val">{lineage_label}</div>
    </div>
    <div class="grid">
      <div class="box"><div class="lbl">Identifiant / Boucle</div><div class="val">{tag_label}</div></div>
      <div class="box"><div class="lbl">Poids enregistré</div><div class="val">{weight_label}</div></div>
    </div>
    <div class="parents">
      <div class="parent-sire">
        <div class="lbl" style="color:#93C5FD;">Père (Géniteur)</div>
        <div class="val">{father_label}</div>
      </div>
      <div class="parent-dam">
        <div class="lbl" style="color:#F9A8D4;">Mère (Génitrice)</div>
        <div class="val">{mother_label}</div>
      </div>
    </div>
    <div class="footer">Certifié via la plateforme Jur-gui — Élevage Intelligent Dakar</div>
  </div>
</body>
</html>"""

