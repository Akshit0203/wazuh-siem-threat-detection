# Log Collection, Normalization & Decoders

Wazuh's value starts with **collecting** logs from everywhere and **normalizing** them into a
common, searchable structure. This page covers the sources ingested in the lab and how
decoders turn raw log lines into fields that rules can match.

## Log sources collected

| Source | Where | Configured via |
|---|---|---|
| SSH / sudo / PAM | `/var/log/auth.log` (Ubuntu), `/var/log/secure` (CentOS) | `localfile` (syslog) |
| System messages | `/var/log/syslog`, `/var/log/messages` | `localfile` (syslog) |
| Linux audit | audit socket / `auditd` | `auditd` integration |
| Windows Security / System / Application | Event channels | `localfile` (eventchannel) |
| Sysmon (if present) | `Microsoft-Windows-Sysmon/Operational` | `localfile` (eventchannel) |
| PowerShell | `Microsoft-Windows-PowerShell/Operational` | `localfile` (eventchannel) |
| Custom app | `/var/log/myapp/app.log` | `localfile` + custom decoder |

Collection is declared in each agent's `ossec.conf` with `<localfile>` blocks — see
[`../config/ossec.conf.linux.xml`](../config/ossec.conf.linux.xml) and
[`../config/ossec.conf.windows.xml`](../config/ossec.conf.windows.xml).

## How decoding works

For every event the manager runs a two-stage pipeline:

```
raw log line ──▶ PRE-DECODER ──▶ DECODER ──▶ RULE MATCHING ──▶ alert
                (time, host,     (extract      (match fields,
                 program)         fields)        assign level)
```

- **Pre-decoding** pulls the generic envelope (timestamp, hostname, program name) from standard
  syslog-style lines automatically.
- **Decoding** extracts the *meaningful* fields — username, source IP, action, status — using a
  decoder. Wazuh ships thousands of decoders; you add your own only for non-standard logs.

## Writing a custom decoder

The lab includes a custom application log that Wazuh doesn't understand out of the box:

```
2025-11-15 10:42:07 myapp AUTH user=jdoe action=login result=FAILED srcip=203.0.113.44
```

A parent decoder anchors on the program name, and a child decoder extracts the fields
(full file: [`../config/local_decoder.xml`](../config/local_decoder.xml)):

```xml
<decoder name="myapp">
  <program_name>^myapp</program_name>
</decoder>

<decoder name="myapp-auth">
  <parent>myapp</parent>
  <prematch>AUTH </prematch>
  <regex offset="after_prematch">user=(\S+) action=(\S+) result=(\S+) srcip=(\d+.\d+.\d+.\d+)</regex>
  <order>user, action, status, srcip</order>
</decoder>
```

The `<order>` maps each captured group to a named field (`user`, `action`, `status`, `srcip`)
that rules can then reference with `<field name="...">`.

## Testing with `wazuh-logtest`

Always validate decoders and rules before relying on them. `wazuh-logtest` lets you paste a raw
line and see exactly how it is pre-decoded, decoded, and which rule fires:

```bash
sudo /var/ossec/bin/wazuh-logtest
# then paste:
2025-11-15 10:42:07 myapp AUTH user=jdoe action=login result=FAILED srcip=203.0.113.44
```

The output shows the extracted fields (`user: jdoe`, `status: FAILED`, `srcip: 203.0.113.44`)
and the matched rule ID — confirming the decoder and the custom rules in
[custom-rules.md](custom-rules.md) work together.

## From fields to detection

Once fields are extracted, rules do the detection. The custom `myapp` rules escalate a single
failed login (level 5) into a **brute-force** correlation alert (level 12) when five failures
come from the same source IP inside 120 seconds — see [custom-rules.md](custom-rules.md).
