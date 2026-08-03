/*
 * Author: WaldoTheWarfighter
 * Saves the local player's current equipment as the mission respawn inventory. Explicit player
 * actions show themed confirmation; automatic radio/startup callers can suppress presentation so
 * no notification is queued into the mission loading/title sequence.
 *
 * Arguments:
 * 0: show notification <BOOL> (default true)
 *
 * Return Value: BOOL - true after the inventory is saved.
 *
 * Example: [false] call Waldo_fnc_SaveLoadout;
 * Current callers: starter/loadout-save interactions and ACRE2 radio assignment finalisation.
 */
params [["_showNotification", true, [true]]];
private _loadout = [getUnitLoadout player] call Waldo_fnc_ACRE2FilterLoadout;
missionNamespace setVariable ["Waldo_Player_Inventory", _loadout];
if (_showNotification) then {
    [
        "RESPAWN LOADOUT SAVED",
        "Your current equipment will be restored when you respawn.",
        "SUCCESS",
        5,
        "TOP_RIGHT",
        "RESPAWN_LOADOUT",
        "PLAYER LOADOUT",
        "REPLACE"
    ] call Waldo_fnc_ShowUiNotification;
};
true
