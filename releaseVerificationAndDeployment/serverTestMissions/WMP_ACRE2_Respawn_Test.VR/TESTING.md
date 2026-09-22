# WMP ACRE2 respawn server test

Build the supplied ZIP from the current pack source before uploading it. The template folder holds
the scenario and test hooks; the builder adds the current release scripts and configuration.

```powershell
python .\releaseVerificationAndDeployment\build_service_logistics_test_mission.py --destination .qa\WMP_ACRE2_Respawn_Test.VR --zip releaseVerificationAndDeployment\serverTestMissions\WMP_ACRE2_Respawn_Test.VR.zip
```

Upload the ZIP or extract its `WMP_ACRE2_Respawn_Test.VR` folder into the server's `MPMissions`.

Required mods: CBA_A3, ACE3, ZEN and ACRE2. The built package contains the current WMP source.

For a local dedicated/client test, close Arma and run:

```powershell
.\releaseVerificationAndDeployment\launch_acre2_respawn_test.ps1
```

The launcher stages a fresh build, uses 3840×2160 and `-noBattlEye`, does not open Eden, and refuses to launch if the
test-specific `ALPHA_NET`/`BRAVO_NET` configuration has been replaced by the generic pack example.
The server creates one full-addons curator and assigns it to the first connected tester, then
reassigns it after player-object replacement so Zeus remains available after respawn.

## Slots and expected initial state

| Slot/group | PRC-343 | PRC-152 | PRC-77 | Ear setup |
|---|---|---|---|---|
| ALPHA 1 and 2 (`acre_alpha_1`, `acre_alpha_2`) | Block 5, channel 3 | Channel 4 (`ALPHA TEST`) | 45.500 MHz | 343 left, 152 right, 77 both |
| BRAVO 1 and 2 (`acre_bravo_1`, `acre_bravo_2`) | Block 6, channel 7 | Channel 8 (`BRAVO TEST`) | 51.000 MHz | 343 right, 152 left, 77 both |

The PRC-77 is frequency-controlled rather than channel-numbered. None of the configured values are
the radio's default channel/frequency.

## Test procedure

1. Fill all four slots and allow ACRE to finish replacing base radios with unique radios.
2. Confirm every player has exactly one PRC-343, one PRC-152 and one PRC-77.
3. Confirm the initial settings in the table above. Verify each two-player pair can communicate on
   both its shared PRC-152 channel and shared PRC-77 frequency.
4. Change at least one channel and one listening ear on each player.
5. Use `Save Respawn Loadout` on the equipment crate between the two start positions.
6. Respawn through the `WMP ACRE2 TEST RANGE` respawn position.
7. Confirm the player's manually changed and saved radio settings return, rather than the authored
   initial settings being forced again.
8. Reconnect/JIP and confirm the authored baseline is applied to a player with no local saved
   respawn snapshot.

## Service and logistics area

Walk east from the player start. The strip has two named base-service stands, a quartermaster,
two transfer crates, and a NATO Prowler/DAGOR with a small physical-cargo crate.

1. Open both base-service stands. Check the labels, save, heal and spectator actions, then travel in both directions.
2. Issue a crate at the quartermaster. Check its displayed name, issue progress and ACE handling.
3. At the stocked transfer crate, select it as source. On the empty crate, merge the whole source
   through ACE, then repeat after restocking with several selected item rows in the transfer window.
4. Select the stocked crate as source and transfer into the Prowler. Then select the Prowler as source
   and transfer back into a crate. Check both inventories after each operation.
5. Carry the small crate to the Prowler, click to mount it on one passenger seat, and try that seat
   and a visibly clear seat. Only the covered seat should be unavailable. Unmount through ACE carry
   and verify the original seat becomes available again.

The Prowler uses class `B_LSV_01_unarmed_F`. It remains simulated, collidable and drivable. Static
weapons are intentionally absent because working-weapon mounting was removed from this feature.
The builder adds an authored WEST inventory record for WMP's mission-derived supply scanner; the
four legacy ACRE slots remain the only playable people. The record covers their shared NATO rifle,
sidearm and radio kit, plus grenade, explosive and medical issue examples. Check the server RPT for
`PLAYABLE-SLOTS state=READY` before testing quartermaster issues.
The server measures the Prowler's empty seats with a temporary hidden occupant at startup. Check
`[WMP TEST SEATS]` in the server RPT for the number of verified seats before testing locks.

Babel is enabled for this ACRE test. WEST defaults understand Common and English and initially
speak English. `acre_bravo_1` uses the documented `VARIABLENAME` override, additionally understands
Russian and initially speaks Russian. Confirm both the Babel diary record and speaking-language
selection exist immediately after joining, then remain singular after respawn.

# CEOI and optional Babel

When the root ACRE setup has `enabled=true`, the loadout-save crate exposes blue actions that
rebuild the CEOI and report the applied radio and Babel state. A successful enabled run must create
`Map > Briefing > ACRE2 > CEOI`. These controls and the expected-settings diary remain absent when
the WMP ACRE setup is disabled. Babel controls and the Babel diary entry require both the WMP ACRE
setup and `babel.enabled=true` in `MissionConfig\acreConfig.sqf`; the shipped mission deliberately
leaves Babel disabled.

Use **Reapply Enabled ACRE2 Babel** only as a manual diagnostic; normal initial setup must not depend
on it. If the root WMP ACRE setting is disabled, neither CEOI nor Babel controls/records should exist.
