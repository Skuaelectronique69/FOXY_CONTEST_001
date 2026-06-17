# SKUA — SYSTEM FOUNDATION V1

## Origine

Cette synthèse est issue de l'étude des dossiers Linux, administration système et cybersécurité.

Objectif : constituer une base de connaissances durable pour l'exploitation de SKUA-CORE et de l'ensemble de l'écosystème SKUA.

---

## Leçon n°1 : Un serveur est un système vivant

SKUA-CORE n'est pas une machine.

C'est un ensemble composé de :

- Processus Linux
- Services système
- Conteneurs Docker
- Réseau
- Stockage
- Comptes utilisateurs
- Permissions
- Journaux
- Sauvegardes

Tout incident doit être analysé comme l'interaction de ces composants.

---

## Leçon n°2 : Comprendre les processus est fondamental

Tout service SKUA est un processus Linux :

- FOXY
- GhostDesk
- Telegram Bots
- Monitoring
- Open WebUI
- Docker

Compétences minimales à maîtriser :

- `ps`
- `top`
- `htop`
- `pidof`
- `jobs`
- `kill`
- `pkill`
- `nice`
- `renice`

Objectif : identifier rapidement un processus bloqué, consommant excessivement les ressources ou arrêté.

---

## Leçon n°3 : Mesurer avant de corriger

Aucune décision ne doit être prise sans mesure.

Outils prioritaires :

- `top` / `htop`
- `free`
- `smartctl`
- `iostat`
- `vmstat`
- `sensors`
- `ss`

Objectif : comprendre les causes réelles d'un ralentissement avant toute intervention.

---

## Leçon n°4 : Le stockage est critique

Les données représentent l'actif principal de SKUA.

Surveiller régulièrement :

- Santé SMART des SSD
- Températures
- Entrées/sorties disque
- Occupation des volumes
- Sauvegardes

Un disque remplacé à temps coûte moins qu'une restauration impossible.

---

## Leçon n°5 : Principe du moindre privilège

Chaque agent doit posséder uniquement les droits nécessaires à sa mission.

| Agent        | Périmètre                    |
|--------------|------------------------------|
| FOXY         | Médias et orchestration      |
| Kenny        | SAV                          |
| Rodrigue     | Coordination                 |
| ShadowBroker | OSINT                        |

Aucun agent ne doit disposer d'autorisations globales sans justification documentée.

---

## Leçon n°6 : Séparer Production et Sandbox

**Production**
- Services actifs
- Données réelles
- Infrastructure opérationnelle

**Sandbox**
- Tests
- Développement
- Expérimentations
- Nouveaux agents

Les deux environnements ne doivent jamais être confondus.

---

## Leçon n°7 : Les fuites de données proviennent souvent de négligences

Les causes principales sont :

- Comptes oubliés
- Permissions excessives
- Applications obsolètes
- Absence de surveillance
- Manque de gouvernance

La prévention doit être continue.

---

## Leçon n°8 : L'inventaire est obligatoire

Tout accès doit être documenté :

| Service    | Responsable | Usage | Privilège | MFA | Dernière vérification |
|------------|-------------|-------|-----------|-----|-----------------------|
| GitHub     |             |       |           |     |                       |
| Gmail      |             |       |           |     |                       |
| Notion     |             |       |           |     |                       |
| Telegram   |             |       |           |     |                       |
| Tailscale  |             |       |           |     |                       |
| Discord    |             |       |           |     |                       |
| Canva      |             |       |           |     |                       |
| YouTube    |             |       |           |     |                       |

---

## Leçon n°9 : Observer les signaux faibles

Surveiller :

- Nouveaux périphériques
- Nouveaux accès
- Nouveaux tokens
- Consommations anormales
- Exports de données
- Échecs répétés

Les incidents majeurs commencent souvent par des signaux mineurs.

---

## Conclusion

Cette documentation marque le passage de SKUA d'un projet expérimental vers une infrastructure administrée.

Le rôle du fondateur n'est plus uniquement de construire des outils.

Il est désormais de gouverner un système vivant.

---

_Knowledge Vault SKUA — 17 juin 2026_
