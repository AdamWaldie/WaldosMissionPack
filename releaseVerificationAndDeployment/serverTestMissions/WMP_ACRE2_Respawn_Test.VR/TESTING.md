# WMP ACRE2 respawn server test

Upload the complete `WMP_ACRE2_Respawn_Test.VR` folder to the server's `MPMissions` directory, or
upload the supplied ZIP/PBO through the server's normal mission deployment process.

Required mods: CBA_A3, ACE3 and ACRE2. The mission contains the current WMP source directly.

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

Babel is deliberately disabled, but the mission config contains a documented `VARIABLENAME`
override for `acre_bravo_1` so that selector can be enabled for a separate Babel test.

# CEOI and optional Babel

When the root ACRE setup has `enabled=true`, the loadout-save crate exposes blue actions that
rebuild the CEOI and report the applied radio and Babel state. A successful enabled run must create
`Map > Briefing > ACRE2 > CEOI`. These controls and the expected-settings diary remain absent when
the WMP ACRE setup is disabled. Babel controls and the Babel diary entry require both the WMP ACRE
setup and `babel.enabled=true` in `MissionConfig\acreConfig.sqf`; the shipped mission deliberately
leaves Babel disabled.

When testing Babel, change only `babel.enabled` to `true`, restart the mission, and use **Reapply
Enabled ACRE2 Babel** if a manual retry is required. The Babel action and Babel diary entry must not
exist while Babel is disabled. If the root WMP ACRE setting is disabled, neither the CEOI controls
nor the ACRE expected-settings diary should exist.
