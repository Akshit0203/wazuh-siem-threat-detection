# Threat Detection & MITRE ATT&CK Mapping

Wazuh rules are enriched with **MITRE ATT&CK®** technique IDs, so every qualifying alert is
automatically mapped to the adversary tactic and technique it represents. This turns a stream of
individual alerts into a structured, behaviour-based picture of what an attacker is trying to do.

<p align="center">
  <img src="../assets/images/07-mitre-attack.png" alt="MITRE ATT&CK dashboard: alerts over time, top tactics, rule level by attack and by tactic" width="880">
</p>

## Why ATT&CK mapping matters

- **Shared language** — "T1110 Brute Force" or "T1078 Valid Accounts" is unambiguous across
  tools and teams.
- **Behaviour over signatures** — you reason about *tactics* (the attacker's goal) rather than
  isolated log lines.
- **Coverage gaps** — the tactic/technique breakdown shows where you have detections and where
  you don't.

## How Wazuh maps alerts

Rules carry a `<mitre>` block. Wazuh's built-in ruleset already tags thousands of rules, and the
custom rules in this lab do the same:

```xml
<rule id="100102" level="12" frequency="5" timeframe="120">
  ...
  <mitre>
    <id>T1110</id>   <!-- Brute Force -->
  </mitre>
</rule>
```

The dashboard aggregates these IDs into tactics and techniques.

## What the dashboard shows

From the lab (agent `centosvm`, last 3 hours):

- **Alerts evolution over time** — technique volume over time (a sharp climb in *Stored Data
  Manipulation* is clearly visible).
- **Top tactics** — Impact, Defense Evasion, Initial Access, Persistence, Privilege Escalation,
  Lateral Movement, Credential Access.
- **Top techniques** — Valid Accounts, Password Guessing, Remote Services, Stored Data
  Manipulation, Data Destruction, File Deletion, SSH, Disable or Modify Tools.
- **Rule level by attack / by tactic** — ties alert *severity* to the technique and tactic, so
  you can prioritize high-severity techniques.

The **Framework** and **Intelligence** tabs let you browse the full ATT&CK matrix and drill from
a technique straight into the alerts that matched it.

## Techniques exercised in this lab

| Technique | ID | How it was generated |
|---|---|---|
| Brute Force | T1110 | Simulated SSH / app login failures |
| Valid Accounts | T1078 | Successful auth following failures |
| Stored Data Manipulation | T1565.001 | File add/modify in monitored dirs |
| Data Destruction / File Deletion | T1485 / T1070.004 | File deletion in monitored dirs |
| Account Manipulation | T1098 | `useradd` / `userdel` activity |

See [threat-simulation.md](threat-simulation.md) for the exact commands, and
[custom-rules.md](custom-rules.md) for the rules that tag these techniques.

## From detection to response

Mapping is the input to triage: an analyst reads the tactic to understand intent, checks the
rule level for urgency, pivots to the source agent and raw events, and — for a confirmed
brute-force-into-success chain (T1110 → T1078) — escalates to incident response. Wazuh can also
run **active responses** (e.g. firewall-drop a source IP) when a high-severity rule fires.
