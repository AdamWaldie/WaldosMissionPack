# Full Arma audit: PR #21 through PR #32

This reusable disposable mission audits the runtime feature range from PR #21
through PR #32. It records machine-readable `WMP FULL AUDIT` lines in Arma's
RPT and converts them into JSON and Markdown evidence under `.qa`.

The canonical release gate stages the real mission under `MPMissions`, starts
the dedicated server and connects isolated clients through the normal mission
lifecycle. The helper always disables BattlEye:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\releaseVerificationAndDeployment\launch_full_arma_dedicated_audit.ps1 -Suite core -ModProfile core -Clients 1
```

Available suites are `core`, `economy`, `ew`, `party`, `interactions`, and
`all`. Mod profiles are `none`, `core` (CBA/ACE/ZEN/ACRE2), `acre`, and
`tfar`. The disposable server explicitly permits file patching; never reuse its
generated server configuration for a public or production server.
Client windows remain visible because hidden Arma clients do not reliably
complete the interface-bearing mission lifecycle. Use `-LeaveClientsOpen` for
a manual inspection session after the structured cases finish.
Bulk screenshots and RPT files are local evidence and are not release assets.
See [PROCESS.md](PROCESS.md) for the full release workflow, evidence rules,
defect/retest policy and sign-off requirements. The scripted
`launch_full_arma_audit.ps1` mode is only a fast audit-kernel self-test.
