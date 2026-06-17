#!/usr/bin/env python3
"""
FOXY WEEKLY REPORT - Directeur de Programme SKUA
V1 : collecte locale + Markdown + Telegram (optionnel) + hook Notion (non-bloquant)
"""

import os
import sys
import subprocess
import socket
import shutil
import datetime
import logging
from pathlib import Path

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

ROOT_DIR = Path(__file__).resolve().parent.parent
REPORTS_DIR = ROOT_DIR / "reports" / "weekly"

TELEGRAM_BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN", "")
TELEGRAM_CHAT_ID   = os.getenv("TELEGRAM_CHAT_ID", "")
NOTION_API_KEY     = os.getenv("NOTION_API_KEY", "")
NOTION_DATABASE_ID = os.getenv("NOTION_DATABASE_ID", "")

logging.basicConfig(
    level=logging.INFO,
    format="[FOXY] %(asctime)s %(levelname)s — %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
log = logging.getLogger("foxy")

# ---------------------------------------------------------------------------
# Collectors
# ---------------------------------------------------------------------------

def _run(cmd: list[str], default: str = "N/A") -> str:
    try:
        result = subprocess.run(
            cmd, capture_output=True, text=True, timeout=10
        )
        return result.stdout.strip() if result.returncode == 0 else default
    except Exception:
        return default


def collect_date() -> str:
    return datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")


def collect_hostname() -> str:
    return socket.gethostname()


def collect_uptime() -> str:
    return _run(["uptime", "-p"], default="uptime indisponible")


def collect_disk() -> str:
    usage = shutil.disk_usage("/")
    total_gb  = usage.total  / (1024 ** 3)
    used_gb   = usage.used   / (1024 ** 3)
    free_gb   = usage.free   / (1024 ** 3)
    pct       = used_gb / total_gb * 100
    status    = "WARN" if pct > 80 else "PASS"
    return (
        f"Total : {total_gb:.1f} Go | "
        f"Utilisé : {used_gb:.1f} Go ({pct:.0f}%) | "
        f"Libre : {free_gb:.1f} Go | "
        f"Statut : {status}"
    )


def collect_docker() -> str:
    raw = _run(["docker", "ps", "--format", "table {{.Names}}\t{{.Status}}\t{{.Image}}"])
    if raw == "N/A":
        return "Docker indisponible ou aucun conteneur actif."
    lines = raw.splitlines()
    if len(lines) <= 1:
        return "Aucun conteneur en cours d'exécution."
    return "\n".join(f"  {line}" for line in lines)


def collect_git() -> str:
    git_dir = ROOT_DIR / ".git"
    if not git_dir.exists():
        return "Dépôt Git non détecté."
    branch  = _run(["git", "-C", str(ROOT_DIR), "rev-parse", "--abbrev-ref", "HEAD"])
    commits = _run(["git", "-C", str(ROOT_DIR), "log", "--oneline", "-5"])
    status  = _run(["git", "-C", str(ROOT_DIR), "status", "--short"])
    status_str = status if status else "Répertoire de travail propre."
    return (
        f"Branche   : {branch}\n"
        f"Statut    : {status_str}\n"
        f"Derniers commits :\n"
        + "\n".join(f"  {line}" for line in commits.splitlines())
    )


def collect_all() -> dict:
    log.info("Collecte des données système...")
    data = {
        "date":     collect_date(),
        "hostname": collect_hostname(),
        "uptime":   collect_uptime(),
        "disk":     collect_disk(),
        "docker":   collect_docker(),
        "git":      collect_git(),
    }
    log.info("Collecte terminée.")
    return data

# ---------------------------------------------------------------------------
# Report generator
# ---------------------------------------------------------------------------

def build_markdown(data: dict) -> str:
    disk_status  = "WARN" if "WARN" in data["disk"] else "PASS"
    disk_icon    = "⚠️" if disk_status == "WARN" else "✅"
    docker_warn  = "WARN" if "indisponible" in data["docker"].lower() else "PASS"
    docker_icon  = "⚠️" if docker_warn == "WARN" else "✅"

    report = f"""# FOXY WEEKLY REPORT
> Directeur de Programme SKUA

---

## Métadonnées

| Champ     | Valeur |
|-----------|--------|
| Date      | {data["date"]} |
| Hôte      | {data["hostname"]} |
| Uptime    | {data["uptime"]} |

---

## Infrastructure

### Disque {disk_icon}

```
{data["disk"]}
```

### Conteneurs Docker {docker_icon}

```
{data["docker"]}
```

---

## Versionning Git

```
{data["git"]}
```

---

## Décisions ouvertes

> _À renseigner manuellement ou via intégration Notion (V2)_

- [ ] —
- [ ] —

---

## Risques identifiés

> _À renseigner manuellement ou via intégration Notion (V2)_

- [ ] —
- [ ] —

---

## Prochaines actions

> _À renseigner manuellement ou via intégration Notion (V2)_

- [ ] —
- [ ] —

---

_Généré automatiquement par FOXY — Directeur de Programme SKUA_
"""
    return report


def save_report(content: str, date_str: str) -> Path:
    REPORTS_DIR.mkdir(parents=True, exist_ok=True)
    filename = REPORTS_DIR / f"FOXY_WEEKLY_REPORT_{date_str}.md"
    filename.write_text(content, encoding="utf-8")
    log.info(f"Rapport sauvegardé : {filename}")
    return filename

# ---------------------------------------------------------------------------
# Telegram dispatcher
# ---------------------------------------------------------------------------

def build_telegram_summary(data: dict, report_path: Path) -> str:
    disk_status = "⚠️ WARN" if "WARN" in data["disk"] else "✅ PASS"
    docker_warn = "⚠️ WARN" if "indisponible" in data["docker"].lower() else "✅ PASS"
    return (
        f"📋 *FOXY WEEKLY REPORT*\n"
        f"🖥 Hôte : `{data['hostname']}`\n"
        f"🕐 Date : `{data['date']}`\n"
        f"⏱ Uptime : `{data['uptime']}`\n"
        f"\n"
        f"📊 *Statuts*\n"
        f"Disque  : {disk_status}\n"
        f"Docker  : {docker_warn}\n"
        f"\n"
        f"📁 Rapport : `{report_path.name}`\n"
        f"\n"
        f"_— FOXY, Directeur de Programme SKUA_"
    )


def send_telegram(message: str) -> bool:
    if not TELEGRAM_BOT_TOKEN or not TELEGRAM_CHAT_ID:
        log.info("Telegram non configuré (TELEGRAM_BOT_TOKEN / TELEGRAM_CHAT_ID absents) — envoi ignoré.")
        return False
    try:
        import urllib.request
        import urllib.parse
        import json

        url = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendMessage"
        payload = json.dumps({
            "chat_id":    TELEGRAM_CHAT_ID,
            "text":       message,
            "parse_mode": "Markdown",
        }).encode("utf-8")
        req = urllib.request.Request(
            url,
            data=payload,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        with urllib.request.urlopen(req, timeout=15) as resp:
            result = json.loads(resp.read())
            if result.get("ok"):
                log.info("Message Telegram envoyé avec succès.")
                return True
            else:
                log.warning(f"Telegram API erreur : {result}")
                return False
    except Exception as e:
        log.warning(f"Échec envoi Telegram : {e}")
        return False

# ---------------------------------------------------------------------------
# Notion hook (non-bloquant, V2)
# ---------------------------------------------------------------------------

def push_notion(data: dict, report_path: Path) -> bool:
    """
    Hook Notion préparé pour V2.
    Activé uniquement si NOTION_API_KEY et NOTION_DATABASE_ID sont définis.
    Échec silencieux — ne bloque jamais le rapport.
    """
    if not NOTION_API_KEY or not NOTION_DATABASE_ID:
        log.info("Notion non configuré — hook ignoré (V2).")
        return False
    try:
        import urllib.request
        import json

        url = "https://api.notion.com/v1/pages"
        payload = json.dumps({
            "parent": {"database_id": NOTION_DATABASE_ID},
            "properties": {
                "Name": {
                    "title": [{"text": {"content": f"FOXY WEEKLY REPORT {data['date'][:10]}"}}]
                },
                "Date": {
                    "date": {"start": data["date"][:10]}
                },
                "Hôte": {
                    "rich_text": [{"text": {"content": data["hostname"]}}]
                },
                "Statut Disque": {
                    "rich_text": [{"text": {"content": "WARN" if "WARN" in data["disk"] else "PASS"}}]
                },
            },
        }).encode("utf-8")
        req = urllib.request.Request(
            url,
            data=payload,
            headers={
                "Authorization":  f"Bearer {NOTION_API_KEY}",
                "Content-Type":   "application/json",
                "Notion-Version": "2022-06-28",
            },
            method="POST",
        )
        with urllib.request.urlopen(req, timeout=15) as resp:
            result = json.loads(resp.read())
            if result.get("id"):
                log.info(f"Notion : page créée ({result['id']}).")
                return True
            else:
                log.warning(f"Notion API réponse inattendue : {result}")
                return False
    except Exception as e:
        log.warning(f"Échec push Notion (non-bloquant) : {e}")
        return False

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> int:
    log.info("=== FOXY WEEKLY REPORT — démarrage ===")

    data        = collect_all()
    date_str    = datetime.datetime.now().strftime("%Y-%m-%d")
    content     = build_markdown(data)
    report_path = save_report(content, date_str)

    # Telegram
    summary = build_telegram_summary(data, report_path)
    send_telegram(summary)

    # Notion (non-bloquant)
    push_notion(data, report_path)

    log.info(f"=== FOXY WEEKLY REPORT — terminé : {report_path.name} ===")
    return 0


if __name__ == "__main__":
    sys.exit(main())
