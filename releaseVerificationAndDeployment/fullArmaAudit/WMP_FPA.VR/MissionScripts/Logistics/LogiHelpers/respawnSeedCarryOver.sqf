/*
 * Author: WaldoTheWarfighter
 * Seeds a respawn snapshot for a live-side-switched player by carrying over their current gear and
 * radios exactly as-is, tagged BRIDGED. This is a deliberate live bridge back to the player's old
 * side's kit and radio presets - ACRE2 never re-syncs a switched player's preset on its own (verified
 * against ACRE2's own upstream source: presets are baked into a radio item at creation time via a
 * client-local, non-networked table, and are never re-applied on a live side change), so carrying the
 * existing radios over as-is is what actually keeps the player able to hear/speak with whoever they
 * could before the switch - deliberately not "corrected" onto the new side's own preset.
 *
 * Arguments: None (operates on the local player).
 * Return Value: Boolean - true after one snapshot is saved (see Waldo_fnc_SaveLoadout's own return).
 *
 * Example: [] call Waldo_fnc_RespawnSeedCarryOver;
 * Current callers: Waldo_fnc_RespawnSeedSideSwitch (CARRY_OVER mode, and as SIDE_BASE_LOADOUT's
 * automatic fallback when the target side has no usable mission.sqm pool).
 */
missionNamespace setVariable ["Waldo_Player_NextRespawnSnapshotTag", "BRIDGED"];
[false] call Waldo_fnc_SaveLoadout;
