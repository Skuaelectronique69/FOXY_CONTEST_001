#!/usr/bin/env bash
# FOXY AUDIT — SKUA-CORE
# Produit : reports/audit/AUDIT_SKUA_CORE_YYYY-MM-DD.md
# Usage   : bash scripts/audit-skua-core.sh

# ── Init ────────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPORTS_DIR="$ROOT_DIR/reports/audit"
DATE_STR="$(date +%Y-%m-%d)"
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"
OUT="$REPORTS_DIR/AUDIT_SKUA_CORE_${DATE_STR}.md"

WARN_COUNT=0
CRITICAL_COUNT=0
VERDICT_LINES=()

mkdir -p "$REPORTS_DIR"
> "$OUT"  # reset file

log()  { printf '[FOXY-AUDIT] %s INFO  — %s\n' "$(date '+%H:%M:%S')" "$*"; }
lwarn(){ printf '[FOXY-AUDIT] %s WARN  — %s\n' "$(date '+%H:%M:%S')" "$*"; }

# Exécute une commande ; retourne le fallback si elle échoue
rr() { local fb="$1"; shift; "$@" 2>/dev/null || printf '%s' "$fb"; }

# Vérifie la présence d'un binaire
has() { command -v "$1" &>/dev/null; }

# Compteurs verdict
add_pass()     { VERDICT_LINES+=("✅ PASS     | $1"); }
add_warn()     { WARN_COUNT=$((WARN_COUNT + 1));     VERDICT_LINES+=("⚠️  WARN     | $1"); lwarn "$1"; }
add_critical() { CRITICAL_COUNT=$((CRITICAL_COUNT + 1)); VERDICT_LINES+=("🔴 CRITICAL | $1"); lwarn "CRITICAL — $1"; }

# Écriture dans le rapport
W()  { printf '%s\n'   "$*" >> "$OUT"; }
WN() { printf '\n'     >> "$OUT"; }
WH() { printf '```\n%s\n```\n' "$*" >> "$OUT"; }

# ── Header ──────────────────────────────────────────────────────────────────

log "=== FOXY AUDIT SKUA-CORE — démarrage ==="

W "# AUDIT SKUA-CORE"
W "> FOXY — Directeur de Programme SKUA"
WN
W "| Champ     | Valeur |"
W "|-----------|--------|"
W "| Date      | $TIMESTAMP |"
W "| Script    | audit-skua-core.sh |"
WN
W "---"
WN

# ── Section 1 : Identité système ────────────────────────────────────────────

log "Section 1 — Identité système"
W "## 1. Identité système"
WN

HOSTNAME_VAL="$(hostname 2>/dev/null || echo 'N/A')"
UPTIME_VAL="$(uptime -p 2>/dev/null || uptime 2>/dev/null || echo 'N/A')"
KERNEL_VAL="$(uname -r 2>/dev/null || echo 'N/A')"
OS_VAL="$(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d= -f2 | tr -d '"' || echo 'N/A')"

W "| Champ    | Valeur |"
W "|----------|--------|"
W "| Hostname | $HOSTNAME_VAL |"
W "| Uptime   | $UPTIME_VAL |"
W "| Kernel   | $KERNEL_VAL |"
W "| OS       | $OS_VAL |"
WN
W "---"
WN

# ── Section 2 : CPU / RAM ───────────────────────────────────────────────────

log "Section 2 — CPU / RAM"
W "## 2. CPU / RAM"
WN

W "### Uptime / charge"
WN
WH "$(uptime 2>/dev/null || echo 'N/A')"
WN

W "### Mémoire"
WN
RAM_RAW="$(free -h 2>/dev/null || echo 'Commande free indisponible')"
WH "$RAM_RAW"
WN

# Alerte RAM si disponible
RAM_USED_PCT=$(free 2>/dev/null | awk '/^Mem:/ { printf "%.0f", $3/$2*100 }' || echo 0)
if [ "$RAM_USED_PCT" -ge 90 ] 2>/dev/null; then
    add_critical "RAM utilisée à ${RAM_USED_PCT}%"
elif [ "$RAM_USED_PCT" -ge 75 ] 2>/dev/null; then
    add_warn "RAM utilisée à ${RAM_USED_PCT}%"
else
    add_pass "RAM : ${RAM_USED_PCT}% utilisé"
fi

W "### Top (instantané)"
WN
TOP_OUT="$(top -b -n1 2>/dev/null | head -20 || echo 'top indisponible')"
WH "$TOP_OUT"
WN
W "---"
WN

# ── Section 3 : Stockage ────────────────────────────────────────────────────

log "Section 3 — Stockage"
W "## 3. Stockage"
WN

W "### Volumes (df -h)"
WN
WH "$(df -h 2>/dev/null || echo 'df indisponible')"
WN

# Alerte si un volume > 80%
while IFS= read -r line; do
    PCT=$(echo "$line" | awk '{print $5}' | tr -d '%')
    MNT=$(echo "$line" | awk '{print $6}')
    if [[ "$PCT" =~ ^[0-9]+$ ]]; then
        if [ "$PCT" -ge 90 ]; then
            add_critical "Disque $MNT à ${PCT}%"
        elif [ "$PCT" -ge 80 ]; then
            add_warn "Disque $MNT à ${PCT}%"
        fi
    fi
done < <(df 2>/dev/null | tail -n +2 || true)

W "### Partitions (lsblk)"
WN
WH "$(lsblk 2>/dev/null || echo 'lsblk indisponible')"
WN

W "### Santé SMART"
WN
if has smartctl; then
    DEVICES=$(lsblk -dno NAME,TYPE 2>/dev/null | awk '$2=="disk"{print "/dev/"$1}' || echo "")
    if [ -z "$DEVICES" ]; then
        W "_Aucun disque détecté pour SMART._"
        add_warn "Aucun disque détecté pour SMART"
    else
        for DEV in $DEVICES; do
            W "#### $DEV"
            WN
            SMART_OUT="$(smartctl -H "$DEV" 2>/dev/null || echo "smartctl : accès refusé ou non supporté pour $DEV")"
            WH "$SMART_OUT"
            WN
            if echo "$SMART_OUT" | grep -qi "FAILED"; then
                add_critical "SMART FAILED sur $DEV"
            elif echo "$SMART_OUT" | grep -qi "PASSED"; then
                add_pass "SMART PASSED sur $DEV"
            else
                add_warn "SMART : résultat indéterminé pour $DEV"
            fi
        done
    fi
else
    W "_smartctl non installé — \`sudo apt install smartmontools\`_"
    add_warn "smartctl absent — santé SMART non vérifiée"
fi
WN
W "---"
WN

# ── Section 4 : Docker ──────────────────────────────────────────────────────

log "Section 4 — Docker"
W "## 4. Docker"
WN

if has docker; then
    DOCKER_PS="$(docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}\t{{.Ports}}' 2>/dev/null || echo 'Accès Docker refusé')"
    CONTAINER_COUNT=$(docker ps -q 2>/dev/null | wc -l || echo 0)

    W "### Conteneurs actifs ($CONTAINER_COUNT)"
    WN
    WH "$DOCKER_PS"
    WN

    W "### Stats ressources (instantané)"
    WN
    DOCKER_STATS="$(docker stats --no-stream --format 'table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}' 2>/dev/null || echo 'Aucun conteneur actif ou accès refusé')"
    WH "$DOCKER_STATS"
    WN

    if [ "$CONTAINER_COUNT" -eq 0 ]; then
        add_warn "Docker actif mais aucun conteneur en cours"
    else
        add_pass "Docker : $CONTAINER_COUNT conteneur(s) actif(s)"
    fi
else
    W "_Docker non détecté sur ce système._"
    add_warn "Docker absent ou non accessible"
fi
W "---"
WN

# ── Section 5 : Réseau ──────────────────────────────────────────────────────

log "Section 5 — Réseau"
W "## 5. Réseau"
WN

W "### Interfaces (ip addr)"
WN
WH "$(ip addr 2>/dev/null || ifconfig 2>/dev/null || echo 'ip addr indisponible')"
WN

W "### Ports en écoute (ss -tulpn)"
WN
WH "$(ss -tulpn 2>/dev/null || netstat -tulpn 2>/dev/null || echo 'ss indisponible')"
WN

W "### Tailscale"
WN
if has tailscale; then
    TS_OUT="$(tailscale status 2>/dev/null || echo 'Tailscale : statut indisponible')"
    WH "$TS_OUT"
    if echo "$TS_OUT" | grep -qi "stopped\|not running\|indisponible"; then
        add_warn "Tailscale arrêté ou inaccessible"
    else
        add_pass "Tailscale actif"
    fi
else
    W "_Tailscale non installé sur ce système._"
    add_warn "Tailscale absent"
fi
WN
W "---"
WN

# ── Section 6 : Services ────────────────────────────────────────────────────

log "Section 6 — Services"
W "## 6. Services"
WN

W "### Services en échec (systemctl --failed)"
WN
if has systemctl; then
    FAILED="$(systemctl --failed 2>/dev/null || echo 'systemctl indisponible')"
    WH "$FAILED"
    FAILED_COUNT=$(systemctl --failed 2>/dev/null | grep -c '●' || echo 0)
    if [ "$FAILED_COUNT" -gt 0 ] 2>/dev/null; then
        add_critical "$FAILED_COUNT service(s) en échec (systemctl)"
    else
        add_pass "Aucun service en échec"
    fi
else
    W "_systemctl indisponible (environnement non-systemd ?)_"
    add_warn "systemctl absent — services non vérifiés"
fi
WN

W "### Services critiques SKUA"
WN
W "| Service    | Processus recherché   | Statut |"
W "|------------|-----------------------|--------|"

check_service() {
    local name="$1"
    local pattern="$2"
    local found
    found=$(pgrep -f "$pattern" 2>/dev/null | head -1 || true)
    if [ -n "$found" ]; then
        W "| $name | \`$pattern\` | ✅ Actif (PID $found) |"
        add_pass "Service $name actif"
    else
        W "| $name | \`$pattern\` | ⚠️ Non détecté |"
        add_warn "Service $name non détecté"
    fi
}

check_service "Docker daemon"  "dockerd"
check_service "FOXY"           "foxy_weekly_report"
check_service "GhostDesk"      "ghostdesk"
check_service "Open WebUI"     "open.webui\|openwebui\|open-webui"
check_service "Telegram Bot"   "telegram.*bot\|bot.*telegram\|python.*bot"

WN
W "---"
WN

# ── Section 7 : Sécurité ────────────────────────────────────────────────────

log "Section 7 — Sécurité"
W "## 7. Sécurité"
WN

W "### Utilisateurs locaux (UID ≥ 1000)"
WN
USERS="$(awk -F: '$3 >= 1000 && $3 < 65534 {print $1, "(UID:"$3", shell:"$7")"}' /etc/passwd 2>/dev/null || echo 'N/A')"
WH "$USERS"
USER_COUNT=$(awk -F: '$3 >= 1000 && $3 < 65534' /etc/passwd 2>/dev/null | wc -l || echo 0)
if [ "$USER_COUNT" -gt 3 ] 2>/dev/null; then
    add_warn "$USER_COUNT utilisateurs locaux — vérifier les comptes inactifs"
else
    add_pass "$USER_COUNT utilisateur(s) local(aux)"
fi
WN

W "### Clés SSH autorisées"
WN
W "| Fichier | Nb clés |"
W "|---------|---------|"
KEY_TOTAL=0
while IFS= read -r -d '' auth_file; do
    COUNT=$(grep -c '^ssh-\|^ecdsa-\|^sk-' "$auth_file" 2>/dev/null || echo 0)
    KEY_TOTAL=$((KEY_TOTAL + COUNT))
    W "| \`$auth_file\` | $COUNT |"
done < <(find /root /home -name "authorized_keys" -print0 2>/dev/null || true)
if [ "$KEY_TOTAL" -eq 0 ]; then
    W "| _Aucun fichier authorized_keys trouvé_ | — |"
    add_warn "Aucune clé SSH autorisée — vérifier l'accès root"
else
    add_pass "$KEY_TOTAL clé(s) SSH autorisée(s) détectée(s)"
fi
WN

W "### Pare-feu UFW"
WN
if has ufw; then
    UFW_OUT="$(ufw status verbose 2>/dev/null || echo 'UFW : statut indisponible')"
    WH "$UFW_OUT"
    if echo "$UFW_OUT" | grep -qi "Status: active"; then
        add_pass "UFW actif"
    else
        add_warn "UFW inactif ou statut indéterminé"
    fi
else
    W "_UFW non installé — \`sudo apt install ufw\`_"
    add_warn "UFW absent — pare-feu non vérifié"
fi
WN
W "---"
WN

# ── Section 8 : Sauvegardes ─────────────────────────────────────────────────

log "Section 8 — Sauvegardes"
W "## 8. Sauvegardes"
WN

W "| Dossier potentiel | Présent | Dernier fichier |"
W "|-------------------|---------|-----------------|"

BACKUP_FOUND=0
for DIR in /backup /mnt/backup "$HOME/backup" "$HOME/Backup" /var/backup /media/backup; do
    if [ -d "$DIR" ]; then
        BACKUP_FOUND=$((BACKUP_FOUND + 1))
        LAST=$(find "$DIR" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | awk '{print $2}')
        LAST_DATE=$(stat -c '%y' "$LAST" 2>/dev/null | cut -d. -f1 || echo 'N/A')
        W "| \`$DIR\` | ✅ Oui | $LAST_DATE |"
        add_pass "Dossier sauvegarde trouvé : $DIR"
    else
        W "| \`$DIR\` | ❌ Absent | — |"
    fi
done

if [ "$BACKUP_FOUND" -eq 0 ]; then
    add_critical "Aucun dossier de sauvegarde détecté"
fi

WN
W "---"
WN

# ── Section 9 : Inventaire SKUA ─────────────────────────────────────────────

log "Section 9 — Inventaire SKUA"
W "## 9. Inventaire SKUA"
WN
W "| Composant    | Méthode de détection         | Statut |"
W "|--------------|------------------------------|--------|"

check_inventory() {
    local name="$1"
    local method="$2"
    local result="$3"
    if [ -n "$result" ]; then
        W "| $name | $method | ✅ Détecté |"
    else
        W "| $name | $method | ⚠️ Non détecté |"
    fi
}

# GhostDesk
GD=$(pgrep -f "ghostdesk" 2>/dev/null | head -1 || docker ps --filter name=ghostdesk -q 2>/dev/null | head -1 || true)
check_inventory "GhostDesk" "process / container" "$GD"

# FOXY
FX=$(find "$ROOT_DIR" -name "foxy_weekly_report.py" 2>/dev/null | head -1 || true)
check_inventory "FOXY" "script présent dans repo" "$FX"

# Monitoring (Grafana, Prometheus, Netdata…)
MON=$(docker ps 2>/dev/null | grep -iE "grafana|prometheus|netdata|uptime" | head -1 || \
      pgrep -f "grafana\|prometheus\|netdata" 2>/dev/null | head -1 || true)
check_inventory "Monitoring" "process / container" "$MON"

# Telegram Bots
BOT=$(docker ps 2>/dev/null | grep -iE "bot|telegram" | head -1 || \
      pgrep -f "python.*bot\|bot.*python\|telegram" 2>/dev/null | head -1 || true)
check_inventory "Telegram Bots" "process / container" "$BOT"

# Open WebUI
OWU=$(docker ps 2>/dev/null | grep -iE "open.webui\|openwebui\|ollama" | head -1 || \
      pgrep -f "open.webui\|openwebui" 2>/dev/null | head -1 || \
      ss -tlpn 2>/dev/null | grep -E ":3000|:8080" | head -1 || true)
check_inventory "Open WebUI" "process / port 3000-8080" "$OWU"

WN
W "---"
WN

# ── Section 10 : Verdict ────────────────────────────────────────────────────

log "Section 10 — Verdict"
W "## 10. Verdict"
WN

if [ "$CRITICAL_COUNT" -gt 0 ]; then
    GLOBAL_STATUS="🔴 CRITICAL"
    GLOBAL_MSG="$CRITICAL_COUNT point(s) critique(s) à traiter immédiatement."
elif [ "$WARN_COUNT" -gt 0 ]; then
    GLOBAL_STATUS="⚠️  WARN"
    GLOBAL_MSG="$WARN_COUNT avertissement(s) — aucun blocage immédiat mais attention requise."
else
    GLOBAL_STATUS="✅ PASS"
    GLOBAL_MSG="Aucun problème détecté. Système stable."
fi

W "### Statut global : $GLOBAL_STATUS"
WN
W "> $GLOBAL_MSG"
WN
W "### Détail"
WN
W "| Statut | Point de contrôle |"
W "|--------|-------------------|"
for LINE in "${VERDICT_LINES[@]}"; do
    W "| $LINE |"
done
WN
W "---"
WN
W "_Généré par FOXY — Directeur de Programme SKUA — $TIMESTAMP_"

# ── Fin ─────────────────────────────────────────────────────────────────────

log "Rapport généré : $OUT"
log "Résumé : $GLOBAL_STATUS — CRITICAL=$CRITICAL_COUNT WARN=$WARN_COUNT"
log "=== FOXY AUDIT SKUA-CORE — terminé ==="
