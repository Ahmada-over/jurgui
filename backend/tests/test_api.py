import pytest
from httpx import AsyncClient, ASGITransport
from datetime import date, datetime, timezone
from app.main import app


@pytest.mark.asyncio
async def test_health_and_auth():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # 1. Health check
        res = await client.get("/health")
        assert res.status_code == 200
        assert res.json()["status"] == "healthy"

        # 2. Login as seeded admin
        login_res = await client.post(
            "/api/v1/auth/login",
            data={"username": "admin@jurgui.sn", "password": "admin1234"}
        )
        assert login_res.status_code == 200
        token_data = login_res.json()
        assert "access_token" in token_data
        assert token_data["user"]["role"] == "admin"
        token = token_data["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # 3. /me endpoint
        me_res = await client.get("/api/v1/auth/me", headers=headers)
        assert me_res.status_code == 200
        assert me_res.json()["email"] == "admin@jurgui.sn"


@pytest.mark.asyncio
async def test_complete_livestock_workflow():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # Auth
        login_res = await client.post(
            "/api/v1/auth/login",
            data={"username": "admin@jurgui.sn", "password": "admin1234"}
        )
        token = login_res.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # 1. Breeds test
        breeds_res = await client.get("/api/v1/breeds", headers=headers)
        assert breeds_res.status_code == 200
        breed_names = [b["name"] for b in breeds_res.json()]
        assert "Ladoum" in breed_names
        assert "Métisse Ladoum" in breed_names
        assert "Peulh Peulh" in breed_names
        ladoum_breed_id = next(b["id"] for b in breeds_res.json() if b["name"] == "Ladoum")

        # 2. Sectors test
        sectors_res = await client.get("/api/v1/sectors", headers=headers)
        assert sectors_res.status_code == 200
        assert len(sectors_res.json()) >= 2
        ladoum_sector_id = sectors_res.json()[0]["id"]
        peulh_sector_id = sectors_res.json()[1]["id"]

        # 3. Create female animal (Ndeye Khady, NK-2026-01)
        female_payload = {
            "id": "NK-2026-01",
            "name": "Ndeye Khady",
            "breed_id": ladoum_breed_id,
            "sex": "female",
            "origin": "purchase",
            "purchase_price_cfa": 1200000.0,
            "current_sector_id": ladoum_sector_id,
            "current_weight_kg": 75.5,
            "body_condition": "normal",
            "notes": "Brebis souche d'exception"
        }
        create_fem_res = await client.post("/api/v1/animals", json=female_payload, headers=headers)
        assert create_fem_res.status_code == 201
        assert create_fem_res.json()["id"] == "NK-2026-01"

        # 4. Create male ram (Gorgui, RAM-2026-01)
        male_payload = {
            "id": "RAM-2026-01",
            "name": "Gorgui",
            "breed_id": ladoum_breed_id,
            "sex": "male",
            "origin": "purchase",
            "purchase_price_cfa": 2500000.0,
            "current_sector_id": ladoum_sector_id,
            "current_weight_kg": 115.0,
            "body_condition": "normal",
            "notes": "Grand bélier reproducteur Ladoum"
        }
        create_male_res = await client.post("/api/v1/animals", json=male_payload, headers=headers)
        assert create_male_res.status_code == 201

        # 5. Move animal sector (NK-2026-01 moved to Peulh zone)
        move_res = await client.post(
            "/api/v1/animals/NK-2026-01/move",
            json={"to_sector_id": peulh_sector_id, "reason": "Mise en lot d'accouplement"},
            headers=headers
        )
        assert move_res.status_code == 200
        assert move_res.json()["to_sector_id"] == peulh_sector_id

        # 6. Record mating event
        mating_payload = {
            "female_id": "NK-2026-01",
            "ram_id": "RAM-2026-01",
            "mating_date": "2026-10-22T08:00:00Z",
            "mating_type": "natural",
            "status": "observed",
            "notes": "Accouplement surveillé réussi"
        }
        mating_res = await client.post("/api/v1/reproduction/matings", json=mating_payload, headers=headers)
        assert mating_res.status_code == 201
        mating_id = mating_res.json()["id"]

        # 7. Create pregnancy and verify 150 days rule & milestones
        preg_payload = {
            "female_id": "NK-2026-01",
            "ram_id": "RAM-2026-01",
            "mating_event_id": mating_id,
            "start_date": "2026-10-22",
            "gestation_duration_days": 150,
            "confirmation_status": "confirmed"
        }
        preg_res = await client.post("/api/v1/reproduction/pregnancies", json=preg_payload, headers=headers)
        assert preg_res.status_code == 201
        preg_data = preg_res.json()
        assert preg_data["expected_birth_date"] == "2027-03-21"  # 150 days after 2026-10-22
        assert len(preg_data["timeline"]) == 6  # J+90, J+105, J+120, J+135, J+145, J+150
        pregnancy_id = preg_data["id"]

        # 8. Record birth with an automatically created lamb
        birth_payload = {
            "pregnancy_id": pregnancy_id,
            "female_id": "NK-2026-01",
            "ram_id": "RAM-2026-01",
            "birth_date": "2027-03-20T04:30:00Z",
            "total_lambs": 1,
            "alive_count": 1,
            "stillborn_count": 0,
            "male_count": 1,
            "female_count": 0,
            "difficulties": "Aucune, mise bas naturelle",
            "new_lambs": [
                {
                    "id": "LAMB-2027-01",
                    "name": "Champion Ladoum Jr",
                    "sex": "male",
                    "weight_kg": 4.8,
                    "physical_tag": "SN-DKR-001"
                }
            ]
        }
        birth_res = await client.post("/api/v1/reproduction/births", json=birth_payload, headers=headers)
        assert birth_res.status_code == 201

        # 9. Verify genealogy of the new lamb
        genealogy_res = await client.get("/api/v1/animals/LAMB-2027-01/genealogy", headers=headers)
        assert genealogy_res.status_code == 200
        gen_data = genealogy_res.json()
        assert gen_data["mother"]["id"] == "NK-2026-01"
        assert gen_data["father"]["id"] == "RAM-2026-01"

        # 10. Nutrition & Stock Movement
        products_res = await client.get("/api/v1/feed/products", headers=headers)
        son_de_ble = next(p for p in products_res.json() if "Son de blé" in p["name"])
        initial_stock = son_de_ble["current_stock"]

        # Register stock exit for feeding
        exit_res = await client.post(
            "/api/v1/feed/movements",
            json={
                "feed_product_id": son_de_ble["id"],
                "movement_type": "out_feeding",
                "quantity": 25.0,
                "reason": "Ration matinale brebis"
            },
            headers=headers
        )
        assert exit_res.status_code == 201

        # Verify updated stock
        updated_prods = await client.get("/api/v1/feed/products", headers=headers)
        updated_son = next(p for p in updated_prods.json() if p["id"] == son_de_ble["id"])
        assert updated_son["current_stock"] == initial_stock - 25.0

        # 11. Health record & treatment with withdrawal period
        health_payload = {
            "animal_id": "NK-2026-01",
            "symptoms": "Baisse d'appétit passagère post mise-bas",
            "severity": "low",
            "treatments": [
                {
                    "product_name": "Lévamisole Ovin",
                    "dosage": "7.5 mg/kg corporel",
                    "withdrawal_period_days": 14,
                    "prescribing_vet": "Dr. Diop"
                }
            ]
        }
        health_res = await client.post("/api/v1/health/observations", json=health_payload, headers=headers)
        assert health_res.status_code == 201
        treatments = health_res.json()["treatments"]
        assert len(treatments) == 1
        assert treatments[0]["withdrawal_period_days"] == 14

        # 12. Finances test (FCFA)
        exp_res = await client.post(
            "/api/v1/finances/expenses",
            json={
                "amount_cfa": 50000.0,
                "category": "feed",
                "label": "Achat 2 sacs de tourteaux"
            },
            headers=headers
        )
        assert exp_res.status_code == 201

        finance_summary = await client.get("/api/v1/finances/summary", headers=headers)
        assert finance_summary.status_code == 200
        assert finance_summary.json()["total_expenses_cfa"] >= 50000.0

        # 13. Dashboard overview
        dash_res = await client.get("/api/v1/dashboard/overview", headers=headers)
        assert dash_res.status_code == 200
        dash_data = dash_res.json()
        assert dash_data["cheptel"]["total_active"] >= 3
        assert "Ladoum" in dash_data["cheptel"]["by_breed"]
