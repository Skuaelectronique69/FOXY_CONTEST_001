# AUDIT SKUA-CORE
> FOXY — Directeur de Programme SKUA

| Champ     | Valeur |
|-----------|--------|
| Date      | 2026-06-17 13:37:56 |
| Script    | audit-skua-core.sh |

---

## 1. Identité système

| Champ    | Valeur |
|----------|--------|
| Hostname | vm |
| Uptime   | up 2 minutes |
| Kernel   | 6.18.5 |
| OS       | Ubuntu 24.04.4 LTS |

---

## 2. CPU / RAM

### Uptime / charge

```
 13:37:56 up 2 min,  0 user,  load average: 0.23, 0.15, 0.06
```

### Mémoire

```
               total        used        free      shared  buff/cache   available
Mem:            15Gi       536Mi        15Gi       4.2Mi       362Mi        15Gi
Swap:             0B          0B          0B
```

### Top (instantané)

```
top - 13:37:57 up 2 min,  0 user,  load average: 0.23, 0.15, 0.06
Tasks:  84 total,   1 running,  83 sleeping,   0 stopped,   0 zombie
%Cpu(s):  2.2 us,  4.3 sy,  0.0 ni, 93.5 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st 
MiB Mem :  16075.4 total,  15431.2 free,    536.3 used,    363.1 buff/cache     
MiB Swap:      0.0 total,      0.0 free,      0.0 used.  15539.1 avail Mem 

  PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
  535 root      20   0 1949276  58340  43216 S   9.1   0.4   0:01.07 environme+
    1 root      20   0   17648   5372   2640 S   0.0   0.0   0:00.80 process_a+
    2 root      20   0       0      0      0 S   0.0   0.0   0:00.00 kthreadd
    3 root      20   0       0      0      0 S   0.0   0.0   0:00.00 pool_work+
    4 root       0 -20       0      0      0 I   0.0   0.0   0:00.00 kworker/R+
    5 root       0 -20       0      0      0 I   0.0   0.0   0:00.00 kworker/R+
    6 root       0 -20       0      0      0 I   0.0   0.0   0:00.00 kworker/R+
    7 root       0 -20       0      0      0 I   0.0   0.0   0:00.00 kworker/R+
    8 root       0 -20       0      0      0 I   0.0   0.0   0:00.00 kworker/R+
    9 root      20   0       0      0      0 I   0.0   0.0   0:00.00 kworker/0+
   10 root       0 -20       0      0      0 I   0.0   0.0   0:00.00 kworker/0+
   11 root      20   0       0      0      0 I   0.0   0.0   0:00.02 kworker/0+
   12 root      20   0       0      0      0 I   0.0   0.0   0:10.14 kworker/u+
```

---

## 3. Stockage

### Volumes (df -h)

```
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           7.9G     0  7.9G   0% /dev/shm
tmpfs           7.9G     0  7.9G   0% /sys/fs/cgroup
/dev/vda        252G  7.1G   31G  20% /
```

### Partitions (lsblk)

```
NAME MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
vda  254:0    0  256G  0 disk /
vdb  254:16   0 62.9M  1 disk /opt/claude-code
vdc  254:32   0 19.1M  1 disk /opt/env-runner
vdd  254:48   0  660K  1 disk /mnt/skills/public
vde  254:64   0  5.3M  1 disk /mnt/skills/examples
```

### Santé SMART

_smartctl non installé — `sudo apt install smartmontools`_

---

## 4. Docker

### Conteneurs actifs (0)

```
Accès Docker refusé
```

### Stats ressources (instantané)

```
Aucun conteneur actif ou accès refusé
```

---

## 5. Réseau

### Interfaces (ip addr)

```
ip addr indisponible
```

### Ports en écoute (ss -tulpn)

```
ss indisponible
```

### Tailscale

_Tailscale non installé sur ce système._

---

## 6. Services

### Services en échec (systemctl --failed)

```
systemctl indisponible
```

### Services critiques SKUA

| Service    | Processus recherché   | Statut |
|------------|-----------------------|--------|
| Docker daemon | `dockerd` | ⚠️ Non détecté |
| FOXY | `foxy_weekly_report` | ⚠️ Non détecté |
| GhostDesk | `ghostdesk` | ⚠️ Non détecté |
| Open WebUI | `open.webui\|openwebui\|open-webui` | ⚠️ Non détecté |
| Telegram Bot | `telegram.*bot\|bot.*telegram\|python.*bot` | ⚠️ Non détecté |

---

## 7. Sécurité

### Utilisateurs locaux (UID ≥ 1000)

```
ubuntu (UID:1000, shell:/bin/bash)
```

### Clés SSH autorisées

| Fichier | Nb clés |
|---------|---------|
| _Aucun fichier authorized_keys trouvé_ | — |

### Pare-feu UFW

_UFW non installé — `sudo apt install ufw`_

---

## 8. Sauvegardes

| Dossier potentiel | Présent | Dernier fichier |
|-------------------|---------|-----------------|
| `/backup` | ❌ Absent | — |
| `/mnt/backup` | ❌ Absent | — |
| `/root/backup` | ❌ Absent | — |
| `/root/Backup` | ❌ Absent | — |
| `/var/backup` | ❌ Absent | — |
| `/media/backup` | ❌ Absent | — |

---

## 9. Inventaire SKUA

| Composant    | Méthode de détection         | Statut |
|--------------|------------------------------|--------|
| GhostDesk | process / container | ⚠️ Non détecté |
| FOXY | script présent dans repo | ✅ Détecté |
| Monitoring | process / container | ⚠️ Non détecté |
| Telegram Bots | process / container | ⚠️ Non détecté |
| Open WebUI | process / port 3000-8080 | ⚠️ Non détecté |

---

## 10. Verdict

### Statut global : 🔴 CRITICAL

> 1 point(s) critique(s) à traiter immédiatement.

### Détail

| Statut | Point de contrôle |
|--------|-------------------|
| ✅ PASS     | RAM : 3% utilisé |
| ⚠️  WARN     | smartctl absent — santé SMART non vérifiée |
| ⚠️  WARN     | Docker actif mais aucun conteneur en cours |
| ⚠️  WARN     | Tailscale absent |
| ✅ PASS     | Aucun service en échec |
| ⚠️  WARN     | Service Docker daemon non détecté |
| ⚠️  WARN     | Service FOXY non détecté |
| ⚠️  WARN     | Service GhostDesk non détecté |
| ⚠️  WARN     | Service Open WebUI non détecté |
| ⚠️  WARN     | Service Telegram Bot non détecté |
| ✅ PASS     | 1 utilisateur(s) local(aux) |
| ⚠️  WARN     | Aucune clé SSH autorisée — vérifier l'accès root |
| ⚠️  WARN     | UFW absent — pare-feu non vérifié |
| 🔴 CRITICAL | Aucun dossier de sauvegarde détecté |

---

_Généré par FOXY — Directeur de Programme SKUA — 
