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
    from datetime import date
    from sqlalchemy import or_, func
    from sqlalchemy.orm import selectinload

    async with AsyncSessionLocal() as session:
        query = (
            select(Animal)
            .options(
                selectinload(Animal.breed),
                selectinload(Animal.current_sector),
                selectinload(Animal.weight_records),
                selectinload(Animal.mother).selectinload(Animal.breed),
                selectinload(Animal.mother).selectinload(Animal.father),
                selectinload(Animal.mother).selectinload(Animal.mother),
                selectinload(Animal.father).selectinload(Animal.breed),
                selectinload(Animal.father).selectinload(Animal.father),
                selectinload(Animal.father).selectinload(Animal.mother),
            )
            .where(func.lower(Animal.id) == animal_id.strip().lower())
        )
        res = await session.execute(query)
        animal = res.scalars().first()
        if not animal:
            return HTMLResponse(
                content="""<!DOCTYPE html><html lang="fr"><head><meta charset="UTF-8"/><meta name="viewport" content="width=device-width,initial-scale=1.0"/><title>Fiche introuvable — Jur-gui</title><style>body{font-family:system-ui,sans-serif;background:#071F18;color:#fff;display:flex;align-items:center;justify-content:center;min-height:100vh;margin:0;padding:20px;text-align:center}.box{max-width:420px;background:#0D3B2E;border:1px solid rgba(212,175,55,0.4);border-radius:20px;padding:32px}h1{margin:0 0 8px;color:#F3D36B;font-size:22px}p{color:#CBD5E1;font-size:14px}</style></head><body><div class="box"><h1>Certificat Généalogique Introuvable</h1><p>Aucun sujet ovin enregistré sous cette référence dans le registre Jur-gui Dakar.</p></div></body></html>""",
                status_code=404,
            )

        offspring_res = await session.execute(
            select(Animal)
            .options(selectinload(Animal.breed))
            .where(or_(Animal.mother_id == animal.id, Animal.father_id == animal.id))
            .order_by(Animal.birth_date.desc())
        )
        offspring = offspring_res.scalars().all()

        breed_name = animal.breed.name if animal.breed else "Race Ovine Sélectionnée"
        is_female = animal.sex.lower() == "female"
        sex_label = "Brebis (Femelle)" if is_female else "Bélier Géniteur (Mâle)"
        sex_code = "♀ FEMELLE" if is_female else "♂ MÂLE"
        lineage_label = animal.lineage or "Lignée Pure Sélectionnée — Registre Jur-gui"
        tag_label = animal.physical_tag or "Non bouclé"
        birth_str = animal.birth_date.strftime("%d/%m/%Y") if animal.birth_date else "Non renseignée"

        age_str = "Non précisé"
        if animal.birth_date:
            months = max(0, (date.today() - animal.birth_date).days // 30)
            if months >= 12:
                years = months // 12
                rem_m = months % 12
                age_str = f"{years} an{'s' if years > 1 else ''}" + (f" {rem_m} mois" if rem_m else "")
            else:
                age_str = f"{months} mois"
        elif animal.estimated_age_months:
            age_str = f"{animal.estimated_age_months} mois (est.)"

        origin_map = {
            "birth": "Né à la bergerie (Sélection interne)",
            "purchase": "Acquisition externe sélectionnée",
            "gift": "Don / Échange génétique",
        }
        origin_label = origin_map.get(animal.origin, "Bergerie Jur-gui Dakar")

        cond_map = {
            "normal": ("État Corporel Optimal (BCS 3.5/5)", "#10B981"),
            "fat": ("État Corporel Élevé / Concours (BCS 4/5)", "#D4AF37"),
            "thin": ("En phase de reprise corporelle", "#F59E0B"),
        }
        cond_label, cond_color = cond_map.get(animal.body_condition, ("Optimal", "#10B981"))

        repro_map = {
            "not_pregnant": "Disponible / Actif en reproduction",
            "suspected": "Saillie déclarée (Gestation présumée)",
            "confirmed": "Gestation confirmée (Suivi 150 j)",
            "lactating": "En lactation (Mère allaitante)",
            "resting": "Repos physiologique",
        }
        repro_label = repro_map.get(animal.reproduction_status, "Actif")

        # Weight calculation & history
        weights_sorted = sorted(animal.weight_records, key=lambda w: w.recorded_at)
        current_weight_str = (
            f"{animal.current_weight_kg:.1f} kg" if animal.current_weight_kg else "Non pesé"
        )
        initial_weight_str = (
            f"{weights_sorted[0].weight_kg:.1f} kg" if weights_sorted else current_weight_str
        )
        weight_gain_str = "—"
        if len(weights_sorted) >= 2:
            diff = weights_sorted[-1].weight_kg - weights_sorted[0].weight_kg
            sign = "+" if diff >= 0 else ""
            weight_gain_str = f"{sign}{diff:.1f} kg"

        # Genealogy nodes (3 generations)
        def fmt_node(obj, fallback_id=None, default_txt="Origine externe non répertoriée"):
            if obj:
                b_txt = obj.breed.name if getattr(obj, "breed", None) else breed_name
                l_txt = f" • Lignée {obj.lineage}" if getattr(obj, "lineage", None) else ""
                return (
                    f"<div class='node-name'>{obj.name}</div>"
                    f"<div class='node-meta'>ID : <strong>{obj.id}</strong> • {b_txt}{l_txt}</div>"
                )
            if fallback_id:
                return (
                    f"<div class='node-name'>Réf. {fallback_id}</div>"
                    f"<div class='node-meta'>Ascendant enregistré hors bergerie</div>"
                )
            return f"<div class='node-empty'>{default_txt}</div>"

        sire_html = fmt_node(animal.father, animal.father_id, "Géniteur externe / Non renseigné")
        dam_html = fmt_node(animal.mother, animal.mother_id, "Génitrice externe / Non renseignée")

        paternal_gf = animal.father.father if animal.father else None
        paternal_gf_id = animal.father.father_id if animal.father else None
        paternal_gm = animal.father.mother if animal.father else None
        paternal_gm_id = animal.father.mother_id if animal.father else None

        maternal_gf = animal.mother.father if animal.mother else None
        maternal_gf_id = animal.mother.father_id if animal.mother else None
        maternal_gm = animal.mother.mother if animal.mother else None
        maternal_gm_id = animal.mother.mother_id if animal.mother else None

        pgf_html = fmt_node(paternal_gf, paternal_gf_id, "Grand-père paternel non renseigné")
        pgm_html = fmt_node(paternal_gm, paternal_gm_id, "Grand-mère paternelle non renseignée")
        mgf_html = fmt_node(maternal_gf, maternal_gf_id, "Grand-père maternel non renseigné")
        mgm_html = fmt_node(maternal_gm, maternal_gm_id, "Grand-mère maternelle non renseignée")

        # Photo or Monogram
        if animal.photo_url and animal.photo_url.strip():
            avatar_html = f"<img src='{animal.photo_url}' alt='{animal.name}' class='subject-photo' />"
        else:
            initial = animal.name[0].upper() if animal.name else "O"
            avatar_html = f"<div class='subject-monogram'>{initial}</div>"

        # Offspring table
        if offspring:
            offspring_rows = "".join(
                f"<tr>"
                f"<td><strong>{o.name}</strong></td>"
                f"<td><span class='mono-tag'>{o.id}</span></td>"
                f"<td>{'♀ Brebis' if o.sex == 'female' else '♂ Bélier'}</td>"
                f"<td>{o.breed.name if o.breed else breed_name}</td>"
                f"<td>{o.birth_date.strftime('%d/%m/%Y') if o.birth_date else '—'}</td>"
                f"<td>{f'{o.current_weight_kg:.1f} kg' if o.current_weight_kg else '—'}</td>"
                f"</tr>"
                for o in offspring
            )
            offspring_section = f"""
            <div class="section">
              <div class="section-header">
                <span class="section-num">04</span>
                <div>
                  <h2>Descendance Certifiée ({len(offspring)} sujet{'s' if len(offspring) > 1 else ''})</h2>
                  <p>Produits directs enregistrés dans le livre généalogique de l'exploitation</p>
                </div>
              </div>
              <div class="table-wrap">
                <table class="data-table">
                  <thead>
                    <tr>
                      <th>Nom du sujet</th>
                      <th>N° Registre</th>
                      <th>Sexe</th>
                      <th>Race</th>
                      <th>Naissance</th>
                      <th>Poids</th>
                    </tr>
                  </thead>
                  <tbody>{offspring_rows}</tbody>
                </table>
              </div>
            </div>
            """
        else:
            offspring_section = ""

        # Weight records table
        if weights_sorted:
            w_rows = "".join(
                f"<tr>"
                f"<td>{w.recorded_at.strftime('%d/%m/%Y')}</td>"
                f"<td><strong>{w.weight_kg:.1f} kg</strong></td>"
                f"<td>{w.notes or 'Pesée de contrôle zootechnique'}</td>"
                f"</tr>"
                for w in reversed(weights_sorted[-5:])
            )
            weights_table_html = f"""
            <div class="table-wrap" style="margin-top:14px;">
              <table class="data-table">
                <thead>
                  <tr><th>Date du relevé</th><th>Poids mesuré</th><th>Observation zootechnique</th></tr>
                </thead>
                <tbody>{w_rows}</tbody>
              </table>
            </div>
            """
        else:
            weights_table_html = ""

        issued_date = date.today().strftime("%d/%m/%Y")
        cert_ref = f"JG-DKR-{animal.id.upper()}-{date.today().year}"

        return f"""<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Certificat Officiel de Lignée & Pedigree — {animal.name} ({animal.id}) | Jur-gui Dakar</title>
  <style>
    :root {{
      --forest: #0D3B2E;
      --forest-dark: #071F18;
      --emerald: #10B981;
      --gold: #D4AF37;
      --gold-light: #FBF5E2;
      --gold-dark: #9A7B1C;
      --slate-900: #0F172A;
      --slate-700: #334155;
      --slate-500: #64748B;
      --border: #E2E8F0;
    }}
    * {{ box-sizing: border-box; }}
    body {{
      font-family: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: #071A14;
      color: var(--slate-900);
      margin: 0;
      padding: 28px 16px 48px;
      line-height: 1.5;
    }}
    .toolbar {{
      max-width: 880px;
      margin: 0 auto 16px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      color: #E2E8F0;
      font-size: 13px;
    }}
    .btn-print {{
      background: linear-gradient(135deg, #D4AF37, #AA8215);
      color: #071F18;
      border: none;
      padding: 9px 18px;
      border-radius: 99px;
      font-weight: 800;
      font-size: 13px;
      cursor: pointer;
      box-shadow: 0 4px 14px rgba(212,175,55,0.35);
    }}
    .sheet {{
      max-width: 880px;
      margin: 0 auto;
      background: #FFFFFF;
      border-radius: 24px;
      overflow: hidden;
      box-shadow: 0 28px 70px rgba(0,0,0,0.55);
      border: 2px solid var(--gold);
    }}
    /* Header Banner */
    .cert-header {{
      background: linear-gradient(135deg, #0D3B2E 0%, #062119 100%);
      color: #FFFFFF;
      padding: 32px 36px;
      border-bottom: 3px solid var(--gold);
      position: relative;
    }}
    .cert-topline {{
      display: flex;
      justify-content: space-between;
      align-items: center;
      flex-wrap: wrap;
      gap: 10px;
      margin-bottom: 22px;
      padding-bottom: 16px;
      border-bottom: 1px solid rgba(255,255,255,0.12);
    }}
    .brand {{
      display: flex;
      align-items: center;
      gap: 12px;
    }}
    .brand-seal {{
      width: 42px;
      height: 42px;
      border-radius: 12px;
      background: rgba(212,175,55,0.18);
      border: 1.5px solid var(--gold);
      display: flex;
      align-items: center;
      justify-content: center;
      font-weight: 900;
      color: #F3D36B;
      font-size: 16px;
    }}
    .brand-title {{
      font-size: 15px;
      font-weight: 800;
      letter-spacing: 0.4px;
      text-transform: uppercase;
      color: #FFFFFF;
    }}
    .brand-sub {{
      font-size: 12px;
      color: #A7F3D0;
    }}
    .cert-ref {{
      font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
      font-size: 12px;
      background: rgba(212,175,55,0.16);
      color: #F3D36B;
      border: 1px solid rgba(212,175,55,0.45);
      padding: 6px 14px;
      border-radius: 99px;
      font-weight: 700;
    }}
    .hero-subject {{
      display: flex;
      align-items: center;
      gap: 24px;
      flex-wrap: wrap;
    }}
    .subject-photo {{
      width: 112px;
      height: 112px;
      border-radius: 50%;
      object-fit: cover;
      border: 3px solid var(--gold);
      box-shadow: 0 8px 24px rgba(0,0,0,0.4);
      background: #092920;
    }}
    .subject-monogram {{
      width: 112px;
      height: 112px;
      border-radius: 50%;
      background: radial-gradient(circle at 30% 30%, #1B5E4B, #092920);
      border: 3px solid var(--gold);
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 44px;
      font-weight: 900;
      color: #F3D36B;
      box-shadow: 0 8px 24px rgba(0,0,0,0.4);
    }}
    .subject-info {{
      flex: 1;
      min-width: 240px;
    }}
    .doc-kicker {{
      font-size: 11px;
      text-transform: uppercase;
      letter-spacing: 1.4px;
      color: #F3D36B;
      font-weight: 800;
    }}
    .subject-name {{
      font-size: 34px;
      font-weight: 900;
      margin: 4px 0 8px;
      letter-spacing: -0.6px;
      color: #FFFFFF;
    }}
    .pills {{
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
    }}
    .pill {{
      font-size: 12px;
      font-weight: 800;
      padding: 5px 12px;
      border-radius: 8px;
      background: rgba(255,255,255,0.12);
      color: #FFFFFF;
    }}
    .pill-gold {{
      background: linear-gradient(135deg, #F3D36B, #D4AF37);
      color: #071F18;
    }}
    /* Lineage Highlight Strip */
    .lineage-strip {{
      background: var(--gold-light);
      border-bottom: 1px solid #E5D59B;
      padding: 18px 36px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      flex-wrap: wrap;
      gap: 12px;
    }}
    .lineage-strip-lbl {{
      font-size: 11px;
      font-weight: 800;
      text-transform: uppercase;
      letter-spacing: 1px;
      color: var(--gold-dark);
    }}
    .lineage-strip-val {{
      font-size: 20px;
      font-weight: 900;
      color: var(--forest-dark);
    }}
    /* Body Content */
    .cert-body {{
      padding: 32px 36px;
    }}
    .section {{
      margin-bottom: 32px;
    }}
    .section:last-child {{
      margin-bottom: 0;
    }}
    .section-header {{
      display: flex;
      align-items: flex-start;
      gap: 12px;
      margin-bottom: 16px;
      padding-bottom: 10px;
      border-bottom: 2px solid #F1F5F9;
    }}
    .section-num {{
      background: var(--forest);
      color: #F3D36B;
      font-weight: 900;
      font-size: 12px;
      padding: 4px 9px;
      border-radius: 8px;
      margin-top: 2px;
    }}
    .section-header h2 {{
      margin: 0;
      font-size: 18px;
      font-weight: 800;
      color: var(--forest-dark);
    }}
    .section-header p {{
      margin: 2px 0 0;
      font-size: 12.5px;
      color: var(--slate-500);
    }}
    /* Spec Grid */
    .spec-grid {{
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(185px, 1fr));
      gap: 12px;
    }}
    .spec-card {{
      background: #F8FAFC;
      border: 1px solid var(--border);
      border-radius: 14px;
      padding: 12px 14px;
    }}
    .spec-lbl {{
      font-size: 11px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      color: var(--slate-500);
    }}
    .spec-val {{
      font-size: 15px;
      font-weight: 800;
      color: var(--slate-900);
      margin-top: 4px;
    }}
    /* 3-Generation Pedigree Tree */
    .pedigree-tree {{
      display: grid;
      grid-template-columns: 1fr 1.15fr;
      gap: 16px;
      align-items: stretch;
    }}
    @media (max-width: 680px) {{
      .pedigree-tree {{ grid-template-columns: 1fr; }}
      .cert-header, .cert-body, .lineage-strip {{ padding-left: 20px; padding-right: 20px; }}
    }}
    .gen-col {{
      display: flex;
      flex-direction: column;
      justify-content: space-around;
      gap: 12px;
    }}
    .tree-card {{
      border-radius: 14px;
      padding: 14px 16px;
      border: 1px solid var(--border);
      background: #FFFFFF;
      position: relative;
    }}
    .tree-sire {{
      border-left: 4px solid #1D4ED8;
      background: #F8FAFF;
    }}
    .tree-dam {{
      border-left: 4px solid #BE185D;
      background: #FFF8FB;
    }}
    .tree-gp {{
      padding: 10px 14px;
      background: #F8FAFC;
      border-left: 3px solid #94A3B8;
    }}
    .role-tag {{
      font-size: 10.5px;
      font-weight: 800;
      text-transform: uppercase;
      letter-spacing: 0.6px;
      margin-bottom: 4px;
    }}
    .role-sire {{ color: #1D4ED8; }}
    .role-dam {{ color: #BE185D; }}
    .role-gp {{ color: #475569; }}
    .node-name {{
      font-size: 15px;
      font-weight: 800;
      color: var(--slate-900);
    }}
    .node-meta {{
      font-size: 12px;
      color: var(--slate-700);
      margin-top: 2px;
    }}
    .node-empty {{
      font-size: 13px;
      font-style: italic;
      color: var(--slate-500);
    }}
    /* Tables */
    .table-wrap {{
      overflow-x: auto;
      border: 1px solid var(--border);
      border-radius: 14px;
    }}
    .data-table {{
      width: 100%;
      border-collapse: collapse;
      font-size: 13.5px;
      text-align: left;
    }}
    .data-table th {{
      background: #F1F5F9;
      color: var(--slate-700);
      font-size: 11px;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      padding: 10px 14px;
      border-bottom: 1px solid var(--border);
    }}
    .data-table td {{
      padding: 10px 14px;
      border-bottom: 1px solid #F1F5F9;
      color: var(--slate-900);
    }}
    .data-table tr:last-child td {{ border-bottom: none; }}
    .mono-tag {{
      font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
      font-size: 12px;
      background: #E8F5EE;
      color: var(--forest);
      padding: 3px 8px;
      border-radius: 6px;
      font-weight: 700;
    }}
    /* Footer Certification */
    .cert-footer {{
      background: #F8FAFC;
      border-top: 1px solid var(--border);
      padding: 22px 36px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      flex-wrap: wrap;
      gap: 16px;
      font-size: 12px;
      color: var(--slate-500);
    }}
    .stamp {{
      display: inline-flex;
      align-items: center;
      gap: 8px;
      color: var(--forest);
      font-weight: 800;
      background: #E8F5EE;
      border: 1px solid #A7F3D0;
      padding: 6px 14px;
      border-radius: 99px;
    }}
    @media print {{
      body {{ background: #FFFFFF; padding: 0; }}
      .toolbar {{ display: none; }}
      .sheet {{ box-shadow: none; border: 1px solid #000; }}
    }}
  </style>
</head>
<body>
  <div class="toolbar">
    <span>Registre Numérique d'Élevage Ovin — Jur-gui Dakar</span>
    <button class="btn-print" onclick="window.print()">Imprimer / Enregistrer en PDF</button>
  </div>

  <div class="sheet">
    <!-- EN-TÊTE OFFICIEL -->
    <div class="cert-header">
      <div class="cert-topline">
        <div class="brand">
          <div class="brand-seal">JG</div>
          <div>
            <div class="brand-title">Jur-gui • Livre Généalogique Ovin</div>
            <div class="brand-sub">Élevage de Sélection — Dakar, Sénégal</div>
          </div>
        </div>
        <div class="cert-ref">RÉF. CERTIFICAT : {cert_ref}</div>
      </div>

      <div class="hero-subject">
        {avatar_html}
        <div class="subject-info">
          <div class="doc-kicker">Certificat Officiel d'Origine, de Lignée & de Performances</div>
          <h1 class="subject-name">{animal.name}</h1>
          <div class="pills">
            <span class="pill pill-gold">{breed_name}</span>
            <span class="pill">{sex_code}</span>
            <span class="pill">ID : {animal.id}</span>
            <span class="pill">Boucle : {tag_label}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- BANDEAU LIGNÉE / SANG -->
    <div class="lineage-strip">
      <div>
        <div class="lineage-strip-lbl">Lignée / Famille Génétique Certifiée</div>
        <div class="lineage-strip-val">{lineage_label}</div>
      </div>
      <div style="text-align:right;">
        <div class="lineage-strip-lbl">Statut Reproducteur</div>
        <div style="font-size:14px;font-weight:800;color:{cond_color};">{repro_label}</div>
      </div>
    </div>

    <div class="cert-body">
      <!-- 01. IDENTIFICATION & SIGNALEMENT -->
      <div class="section">
        <div class="section-header">
          <span class="section-num">01</span>
          <div>
            <h2>Identification & Signalement Zootechnique</h2>
            <p>Données officielles d'enregistrement individuel et de traçabilité</p>
          </div>
        </div>
        <div class="spec-grid">
          <div class="spec-card">
            <div class="spec-lbl">Identifiant Registre</div>
            <div class="spec-val">{animal.id}</div>
          </div>
          <div class="spec-card">
            <div class="spec-lbl">Boucle / Bague Officielle</div>
            <div class="spec-val">{tag_label}</div>
          </div>
          <div class="spec-card">
            <div class="spec-lbl">Race & Standard</div>
            <div class="spec-val">{breed_name}</div>
          </div>
          <div class="spec-card">
            <div class="spec-lbl">Sexe</div>
            <div class="spec-val">{sex_label}</div>
          </div>
          <div class="spec-card">
            <div class="spec-lbl">Date de Naissance</div>
            <div class="spec-val">{birth_str} ({age_str})</div>
          </div>
          <div class="spec-card">
            <div class="spec-lbl">Origine</div>
            <div class="spec-val">{origin_label}</div>
          </div>
        </div>
      </div>

      <!-- 02. ARBRE GÉNÉALOGIQUE (ASCENDANCE SUR 2 GÉNÉRATIONS) -->
      <div class="section">
        <div class="section-header">
          <span class="section-num">02</span>
          <div>
            <h2>Arbre Généalogique & Ascendance (Parents & Grands-Parents)</h2>
            <p>Filiation paternelle (Sire) et maternelle (Dam) certifiée</p>
          </div>
        </div>
        <div class="pedigree-tree">
          <!-- Génération I : Parents -->
          <div class="gen-col">
            <div class="tree-card tree-sire">
              <div class="role-tag role-sire">♂ Père (Géniteur / Sire)</div>
              {sire_html}
            </div>
            <div class="tree-card tree-dam">
              <div class="role-tag role-dam">♀ Mère (Génitrice / Dam)</div>
              {dam_html}
            </div>
          </div>
          <!-- Génération II : Grands-Parents -->
          <div class="gen-col">
            <div class="tree-card tree-gp">
              <div class="role-tag role-gp">♂ Grand-Père Paternel</div>
              {pgf_html}
            </div>
            <div class="tree-card tree-gp">
              <div class="role-tag role-gp">♀ Grand-Mère Paternelle</div>
              {pgm_html}
            </div>
            <div class="tree-card tree-gp">
              <div class="role-tag role-gp">♂ Grand-Père Maternel</div>
              {mgf_html}
            </div>
            <div class="tree-card tree-gp">
              <div class="role-tag role-gp">♀ Grand-Mère Maternelle</div>
              {mgm_html}
            </div>
          </div>
        </div>
      </div>

      <!-- 03. PERFORMANCES PONDERALES & MORPHOLOGIE -->
      <div class="section">
        <div class="section-header">
          <span class="section-num">03</span>
          <div>
            <h2>Performances Pondérales & État Corporel</h2>
            <p>Suivi de croissance et conformation morphologique</p>
          </div>
        </div>
        <div class="spec-grid">
          <div class="spec-card">
            <div class="spec-lbl">Poids Actuel Certifié</div>
            <div class="spec-val" style="color:var(--forest);font-size:18px;">{current_weight_str}</div>
          </div>
          <div class="spec-card">
            <div class="spec-lbl">Première Pesée</div>
            <div class="spec-val">{initial_weight_str}</div>
          </div>
          <div class="spec-card">
            <div class="spec-lbl">Évolution Pondérale</div>
            <div class="spec-val">{weight_gain_str}</div>
          </div>
          <div class="spec-card">
            <div class="spec-lbl">Note d'État Corporel</div>
            <div class="spec-val">{cond_label}</div>
          </div>
        </div>
        {weights_table_html}
      </div>

      <!-- 04. DESCENDANCE -->
      {offspring_section}
    </div>

    <!-- PIED DE PAGE CERTIFICATION -->
    <div class="cert-footer">
      <div class="stamp">✓ Fiche Généalogique Vérifiée • Jur-gui Dakar</div>
      <div>Édité le {issued_date} • Réf. {cert_ref}</div>
    </div>
  </div>
</body>
</html>"""

