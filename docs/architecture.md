# Architecture & Lab Topology

## Components

Wazuh is built from four components. In this lab the three central components run on a single
Linux VM (all-in-one), and agents run on the monitored endpoints.

<p align="center">
  <img src="../assets/images/02-architecture-components.png" alt="Wazuh architecture diagram" width="860">
</p>

| Component | Role in this lab |
|---|---|
| **Wazuh Agent** | Installed on each endpoint (Windows + Linux). Collects logs, FIM events, inventory, and runs SCA policy checks, forwarding everything to the manager over an encrypted channel. |
| **Wazuh Manager** | The analysis engine. Pre-decodes and decodes each event, matches it against the ruleset, raises alerts, enriches them with MITRE ATT&CK and compliance tags, and manages agent registration. Alerts are shipped to the indexer by **Filebeat**. |
| **Wazuh Indexer** | OpenSearch-based store that indexes alerts/events for fast search and aggregation. Backs every dashboard visualization. |
| **Wazuh Dashboard** | Web UI (OpenSearch Dashboards) for investigation, visualization, rule management, compliance views, and PDF report generation. |

## Data flow

```
                 (1) collect                 (2) decode + rule match             (3) index
  Endpoint  ─────────────────────▶  Wazuh Manager  ──────────────────▶  Wazuh Indexer
 (Wazuh agent: logs, FIM,         (analysis engine:               (OpenSearch: alerts,
  inventory, SCA)                  decoders + ruleset,             events, searchable)
        ▲                          MITRE/PCI enrichment)                    │
        │                                  │  Filebeat                      │ (4) query
        │  enrollment (1515) /             ▼                                ▼
        └────── agent channel (1514) ──────┘                        Wazuh Dashboard  ◀── Analyst
```

1. **Collect** — agents tail logs, watch files (`syscheck`), read the audit socket, and gather
   inventory, then forward events to the manager.
2. **Decode & match** — the manager's analysis engine normalizes each event with **decoders**,
   then evaluates it against **rules**. Matches become alerts with a severity *level* and, where
   applicable, MITRE and compliance tags.
3. **Index** — Filebeat ships alerts to the indexer, which stores and indexes them.
4. **Investigate** — the analyst queries, pivots, and reports from the dashboard.

## Ports

| Port | Proto | Between | Purpose |
|---|---|---|---|
| 1514 | TCP/UDP | agent → manager | Encrypted event channel |
| 1515 | TCP | agent → manager | Agent enrollment (`authd`) |
| 1516 | TCP | cluster | Manager cluster comms (multi-node) |
| 55000 | TCP | client → manager | Wazuh REST API |
| 9200 | TCP | dashboard → indexer | Indexer REST (OpenSearch) |
| 443 | TCP | analyst → dashboard | HTTPS web UI |

## Lab topology

| Role | Hostname | OS | Notes |
|---|---|---|---|
| Server | `wazuh-server` | Linux | Manager + Indexer + Dashboard (all-in-one) |
| Agent | `ubuntuvm` | Ubuntu 22.04 | syslog, auditd, FIM, inventory (1,619 pkgs / 307 procs) |
| Agent | `centosvm` | CentOS | FIM (`/data`), MITRE/PCI test workloads |
| Agent | *(windows)* | Windows | Windows Event Log, FIM, registry autoruns |

All hosts sit on an isolated host-only/internal network with no inbound exposure to the
internet. The fleet health counters on the dashboard (total / active / disconnected / pending /
never-connected) reflect this small lab — see
[`03-modules-overview.png`](../assets/images/03-modules-overview.png).

## Why all-in-one for a lab

A single-node install keeps resource use low and setup fast, which is ideal for learning and
for reproducing detections. The same configuration, rules, and decoders apply unchanged to a
distributed, multi-node production cluster — only the deployment topology differs.
