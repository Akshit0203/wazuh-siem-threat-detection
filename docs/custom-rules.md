# Custom Rules & Correlation

Wazuh ships with thousands of rules, but detection engineering is about tuning and extending
them. This page explains the rule model and walks through the custom rules used in the lab
(full file: [`../config/local_rules.xml`](../config/local_rules.xml)).

## Rule model in brief

- Rules live on the **manager** in `/var/ossec/etc/rules/`. Custom rules go in
  `local_rules.xml` and must use IDs **≥ 100000**.
- Each rule has a **level** (severity): `0` = ignore, `3` = low, `5–7` = notice/warning,
  `10–12` = high, `12+` = critical.
- Rules match on decoded fields, on a prior rule (`if_sid`), or on *patterns over time*
  (`frequency` + `timeframe`) for correlation.
- Rules can carry `<mitre>` technique IDs and compliance groups (`pci_dss_*`, `gdpr_*`, …),
  which drive the ATT&CK and compliance dashboards.

## Anatomy of a rule

```xml
<rule id="100101" level="5">
  <if_sid>100100</if_sid>                 <!-- only consider myapp AUTH events -->
  <field name="status">FAILED</field>      <!-- where the decoded status is FAILED -->
  <description>myapp: authentication failed for user $(user) from $(srcip).</description>
  <group>authentication_failed,</group>
  <mitre><id>T1110</id></mitre>            <!-- Brute Force -->
</rule>
```

`$(user)` and `$(srcip)` interpolate the decoded fields into the alert description, so the
analyst sees *who* and *from where* without opening the raw event.

## Correlation: single failure → brute force

A single failed login is noise. The signal is **many** failures from **one** source in a short
window. That's a correlation rule using `frequency` and `timeframe` with `same_source_ip`:

```xml
<rule id="100102" level="12" frequency="5" timeframe="120">
  <if_matched_sid>100101</if_matched_sid>   <!-- 5 matches of rule 100101 ... -->
  <same_source_ip />                         <!-- ... from the same source IP ... -->
  <description>myapp: possible brute-force attack - 5+ failed logins from $(srcip) in 120s.</description>
  <group>authentication_failures,attack,pci_dss_11.4,</group>
  <mitre><id>T1110</id></mitre>
</rule>
```

Five level-5 events collapse into **one level-12 alert** — far more actionable, and tagged for
both MITRE (T1110) and PCI DSS (11.4).

## Follow-on: compromise after brute force

If a **successful** login arrives from the same IP right after the brute-force pattern, that's a
likely account compromise and deserves its own critical alert:

```xml
<rule id="100103" level="12">
  <if_sid>100100</if_sid>
  <field name="status">SUCCESS</field>
  <if_matched_sid>100102</if_matched_sid>
  <same_source_ip />
  <description>myapp: successful login from $(srcip) after brute-force - possible account compromise.</description>
  <mitre><id>T1078</id></mitre>            <!-- Valid Accounts -->
</rule>
```

This chain — *failed → brute force → success* — is a compact example of multi-stage detection.

## Tuning a built-in rule

You don't always need new decoders. You can build on Wazuh's existing rule IDs. Here we escalate
SSH brute force (built-in rule `5716`, "sshd authentication failed") on the lab hosts:

```xml
<rule id="100110" level="12" frequency="6" timeframe="120">
  <if_matched_sid>5716</if_matched_sid>
  <same_source_ip />
  <description>SSH brute-force: 6+ failed logins from same source in 120s.</description>
  <group>authentication_failures,attack,pci_dss_11.4,</group>
  <mitre><id>T1110</id></mitre>
</rule>
```

This is exactly what the simulated SSH brute force in [threat-simulation.md](threat-simulation.md)
triggers — visible as the authentication-failure spike in
[`10-security-events-bruteforce.png`](../assets/images/10-security-events-bruteforce.png).

## Workflow

1. Edit `local_rules.xml` / `local_decoder.xml`.
2. Validate interactively: `sudo /var/ossec/bin/wazuh-logtest`.
3. Apply: `sudo systemctl restart wazuh-manager`.
4. Generate the matching activity and confirm the alert on the dashboard.

> **Tip:** keep custom rule IDs grouped by purpose (e.g. `1001xx` for app auth, `1002xx` for
> FIM) so the ruleset stays readable as it grows.
