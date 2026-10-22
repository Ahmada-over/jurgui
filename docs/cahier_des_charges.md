# CAHIER DES CHARGES FONCTIONNEL ET TECHNIQUE

## Plateforme de gestion d’élevage ovin — Élevage Intelligent – Dakar

**Nom de code du projet :** Jur-gui / Élevage Intelligent – Dakar  
**Version :** 1.0  
**Date :** 22 octobre 2026  
**Type de projet :** Application mobile (Flutter) et API Web (FastAPI + PostgreSQL)  
**Zone d’exploitation initiale :** Dakar, Sénégal  

---

# 1. Présentation générale du projet

## 1.1. Contexte
La gestion d’un élevage ovin nécessite un suivi rigoureux des animaux, de leur alimentation, de leur état sanitaire, de leur reproduction et des stocks disponibles.
Le suivi manuel peut entraîner des oublis de traitements, des erreurs dans les dates de saillie, une mauvaise anticipation des mises bas, des difficultés à suivre les filiations et un manque de visibilité sur les dépenses alimentaires.
Le projet « Élevage Intelligent – Dakar » consiste à développer une application numérique permettant de centraliser ces informations et de faciliter la gestion quotidienne de l’élevage.
L’application sera conçue en priorité pour un élevage de moutons de races Ladoum, Métisse Ladoum et Peulh Peulh, avec une architecture évolutive permettant d’ajouter ultérieurement d’autres races et espèces.

## 1.2. Objectifs généraux
La plateforme devra permettre de :
- Centraliser les informations relatives à chaque animal.
- Organiser le cheptel selon les races, les secteurs et les lots.
- Suivre les accouplements, les gestations, les mises bas et la généalogie.
- Planifier les opérations quotidiennes de nutrition et de soins.
- Gérer les stocks d’aliments, de compléments et de produits sanitaires.
- Programmer des rappels et recevoir des notifications.
- Suivre l’évolution du poids, de l’état corporel et des performances reproductives.
- Enregistrer les dépenses et les coûts liés à l’élevage.
- Produire des rapports permettant de prendre de meilleures décisions.

## 1.3. Périmètre du MVP
La première version comprendra quatre modules fonctionnels principaux :
1. Gestion du cheptel et des secteurs.
2. Reproduction et généalogie.
3. Nutrition et gestion des stocks.
4. Santé animale, hygiène et environnement.

Un tableau de bord général, un système de notifications, une gestion des utilisateurs et un module de suivi financier simplifié compléteront le MVP.

---

# 2. Utilisateurs et droits d’accès

## 2.1. Administrateur ou propriétaire
L’administrateur disposera de tous les droits :
- Consulter et modifier les fiches animales.
- Enregistrer les saillies et les mises bas.
- Organiser les secteurs et les lots.
- Gérer les aliments, les stocks et les dépenses.
- Créer et modifier les rappels.
- Consulter les statistiques et les rapports.
- Gérer les comptes utilisateurs et leurs autorisations.

## 2.2. Employé d’élevage
L’employé pourra, selon les autorisations accordées :
- Consulter les fiches des animaux.
- Enregistrer les distributions alimentaires.
- Déclarer les changements de secteur.
- Signaler un problème sanitaire.
- Enregistrer les observations quotidiennes.
- Consulter et exécuter les tâches planifiées.
- Déclarer les stocks consommés.
L’employé ne pourra pas modifier les données sensibles ou supprimer des historiques sans autorisation.

## 2.3. Accès vétérinaire facultatif
Une évolution pourra permettre à un vétérinaire autorisé de consulter les dossiers sanitaires, d’enregistrer ses observations et de renseigner les traitements prescrits.

---

# 3. Module A — Gestion du cheptel et des secteurs

## 3.1. Fiche individuelle de l’animal
Chaque animal possédera une fiche individuelle avec un identifiant unique.
- **Identification :** Identifiant interne, nom, numéro de boucle/physique, photos (principale et secondaires), race, sexe, date de naissance ou âge estimé, origine (achat, naissance, don), date d'entrée, vendeur/origine, prix d'achat, statut (actif, vendu, décédé, transféré).
- **Physique :** Poids actuel (kg), historique des pesées, état corporel (maigre, normal, gras), observations physiques, morphologie, mensurations.

## 3.2. Gestion des races
Races initiales configurables (extensible sans modif de code) :
- Ladoum
- Métisse Ladoum
- Peulh Peulh

## 3.3. Gestion des secteurs physiques
- Zone Ladoum/Métis
- Zone Peulh Peulh
Chaque secteur : nom, description, capacité estimée, animaux présents, statut, observations/consignes.

## 3.4. Lots et 3.5 Déplacements
- Regroupements par critères (sexe, âge, repro, nutrition, santé).
- Historisation inaltérable des changements de secteur (animal, départ, arrivée, date/heure, auteur, motif).

---

# 4. Module B — Reproduction, gestation et généalogie

## 4.1. Saillies & 4.2 Date prévisionnelle
- Déclaration saillie : femelle, bélier, date/heure, type (naturel/assisté), statut (observé, déclaré, confirmé, à vérifier), observations.
- Durée de référence paramétrable (défaut : 150 jours).
- Estimation théorique calculée : `Date mise bas = Date saillie + 150j`.

## 4.3 - 4.5 Calendrier de suivi de gestation
- J+90 : Transition alimentaire et besoins nutritionnels.
- J+105 : Vérification calendrier sanitaire / vétérinaire.
- J+120 : Évaluation état corporel.
- J+135 : Vérification ration et qualité fin de gestation.
- J+145 : Préparation espace mise bas et renforcement surveillance.
- J+150 : Surveillance mise bas.
- Suivi de confirmation : non vérifié, suspecté, confirmé, non gestant.

## 4.6 - 4.8 Mises bas & Généalogie
- Mises bas : femelle, date/heure, agneaux nés (mâles/femelles, vivants/mort-nés), difficultés, interventions.
- Création automatique fiches agneaux et liens généalogiques (arbre ascendant/descendant, interdiction auto-filiation).

---

# 5. Module C — Nutrition et rationnement

## 5.1 - 5.3 Catalogue aliments & Rations
- Catalogue : Son de blé, tourteau de coton, fanes d'arachide, fanes de niébé, fourrages, concentrés, blocs minéraux, pierres à lécher...
- Profils nutritionnels selon stade (croissance, entretien, engraissement, gestation, lactation, agneaux).
- Fiches de ration par lot ou animal avec fréquence, quantité, statut.

## 5.4 - 5.6 Distributions et Consommation
- Suivi des distributions individuelles et collectives.
- Calculs de consommation et anticipation des besoins d'approvisionnement.

---

# 6. Module D — Gestion des stocks

- Entrées : produit, quantité, unité, PU, montant total, fournisseur, lot, péremption.
- Sorties : distributions, soins, pertes, inventaires.
- Alertes de seuil minimum et péremptions.
- Inventaires physiques avec traçabilité des écarts.

---

# 7. Module E — Santé animale et suivi vétérinaire

- Dossier sanitaire individuel : symptômes, appétit, diagnostic, prescriptions, traitements, posologie.
- Registre de vaccination et calendrier paramétrable.
- Traitements antiparasitaires (ex: lévamisole) avec contrôle strict des dosages.
- Suivi des symptômes, alertes sanitaires et temps d'attente (délais de précaution).

---

# 8. Module F — Hygiène et environnement

- Planification entretien : litière ("ripasse"), abreuvoirs, mangeoires, désinfection.
- Fiches de sécurité pour produits d'entretien.
- Registre d'inspections régulières des enclos.

---

# 9. Module G — Tâches et notifications

- Types : alertes reproduction, rappels santé, nutrition, stocks, hygiène.
- Canaux : In-app notification center, notifications locales mobiles, push FCM.
- Prévention des doublons et reprogrammation dynamique.

---

# 10. Module H & I — Tableau de bord, Statistiques & Finances

- Dashboard centralisé (effectifs, alertes, gestations, tâches du jour, alertes stock).
- Exports PDF et CSV.
- Finances simplifiées : Dépenses (aliments, soins, achats, matériel, main d'œuvre) et Recettes (ventes ovins) en FCFA.

---

# 11. Architecture technique

- **Mobile :** Flutter (Android/iOS, approche Offline-First, SQLite local / drift ou Isar / Hive).
- **Backend :** FastAPI (Python 3.11+), validation Pydantic v2, ORM SQLAlchemy v2.
- **Base de données :** PostgreSQL avec contraintes d'intégrité strictes.
- **Notifications :** Firebase Cloud Messaging (FCM) + In-App Notification Engine.
- **Stockage média :** Object Storage / Stockage de fichiers local ou cloud sécurisé.
