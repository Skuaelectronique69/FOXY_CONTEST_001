# FOXY WEEKLY REPORT

**FOXY — Directeur de Programme SKUA**
Version : V1

---

## Objectif

Produire chaque semaine un rapport d'état automatique de l'écosystème SKUA :
infrastructure, conteneurs Docker, versionning Git, puis l'archiver et notifier via Telegram.

---

## Structure

```
FOXY_CONTEST_001/
├── scripts/
│   └── foxy_weekly_report.py   # Script principal
├── reports/
│   └── weekly/                 # Rapports générés (FOXY_WEEKLY_REPORT_YYYY-MM-DD.md)
├── .env.example                # Modèle de configuration
└── README_FOXY_WEEKLY_REPORT.md
```

---

## Installation

```bash
# 1. Cloner ou se placer dans le dépôt
cd FOXY_CONTEST_001

# 2. Copier et renseigner les variables d'environnement
cp .env.example .env
# Editer .env avec les valeurs réelles (Telegram, Notion)

# 3. Aucune dépendance externe requise — stdlib Python 3.10+ uniquement
python3 --version
```

---

## Utilisation

### Lancement manuel

```bash
# Sans variables d'environnement (rapport local uniquement)
python3 scripts/foxy_weekly_report.py

# Avec Telegram
TELEGRAM_BOT_TOKEN=xxx TELEGRAM_CHAT_ID=yyy python3 scripts/foxy_weekly_report.py

# Avec .env (via python-dotenv ou export manuel)
export $(cat .env | xargs) && python3 scripts/foxy_weekly_report.py
```

### Automatisation hebdomadaire (cron)

```bash
# Tous les vendredis à 18h00
crontab -e
# Ajouter :
0 18 * * 5 cd /path/to/FOXY_CONTEST_001 && export $(cat .env | xargs) && python3 scripts/foxy_weekly_report.py >> /var/log/foxy_weekly.log 2>&1
```

---

## Ce que collecte V1

| Collecteur     | Données                                      |
|----------------|----------------------------------------------|
| Date           | Horodatage de génération                     |
| Hostname       | Nom du serveur                               |
| Uptime         | Temps de disponibilité système               |
| Disque         | Espace total / utilisé / libre (avec alerte) |
| Docker         | Liste des conteneurs actifs (`docker ps`)    |
| Git            | Branche, statut, 5 derniers commits          |

Alerte disque : `WARN` si utilisation > 80 %.

---

## Sortie

### Fichier Markdown archivé

```
reports/weekly/FOXY_WEEKLY_REPORT_2026-06-20.md
```

### Résumé Telegram (si configuré)

```
📋 FOXY WEEKLY REPORT
🖥 Hôte : skua-core
🕐 Date : 2026-06-20 18:00:01
⏱ Uptime : up 3 days, 4 hours

📊 Statuts
Disque  : ✅ PASS
Docker  : ✅ PASS

📁 Rapport : FOXY_WEEKLY_REPORT_2026-06-20.md

— FOXY, Directeur de Programme SKUA
```

---

## Variables d'environnement

| Variable             | Obligatoire | Description                         |
|----------------------|-------------|-------------------------------------|
| `TELEGRAM_BOT_TOKEN` | Non         | Token du bot Telegram FOXY          |
| `TELEGRAM_CHAT_ID`   | Non         | ID du canal / chat de destination   |
| `NOTION_API_KEY`     | Non         | Clé API Notion (V2)                 |
| `NOTION_DATABASE_ID` | Non         | ID de la base Notion cible (V2)     |

Si les variables Telegram sont absentes, l'envoi est ignoré sans erreur.
Si les variables Notion sont absentes, le hook est ignoré sans erreur.

---

## Roadmap

| Version | Contenu                                               |
|---------|-------------------------------------------------------|
| **V1**  | Collecte locale + Markdown + Telegram + hook Notion   |
| V2      | Intégration Notion complète + sections décisions      |
| V3      | Collecte multi-serveurs + alertes automatiques        |
| V4      | FOXY PMO — pilotage projets complet                   |

---

_FOXY — Directeur de Programme SKUA_
