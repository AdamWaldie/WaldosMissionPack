/*
 * Author: WaldoTheWarfighter
 * Saves the local player's current equipment and supported ACRE radio state as one logical respawn
 * snapshot. Transient ACRE unique IDs are filtered from the inventory while channel/frequency, ear,
 * volume, supported audio source and selected-radio state are stored separately by base class plus
 * same-type occurrence. Explicit player actions show themed confirmation; automatic radio/startup
 * callers can suppress presentation so no notification enters the mission loading/title sequence.
 * Locality and authority: call only on the player's interface client. The snapshot is player-local;
 * optional persistence capture sends its separately filtered state through the server lifecycle.
 *
 * Arguments:
 * 0: show notification <BOOL> (default true)
 *
 * Return Value: BOOL - true after the inventory and available radio state are saved.
 *
 * Example: [false] call Waldo_fnc_SaveLoadout;
 * Result: inventory and supported radio settings are saved without displaying a notification.
 * Current callers: starter/loadout-save interactions and ACRE2 radio assignment finalisation.
 */
params [["_showNotification", true, [true]]];
private _loadout = [getUnitLoadout player] call Waldo_fnc_ACRE2FilterLoadout;
missionNamespace setVariable ["Waldo_Player_Inventory", _loadout];
private _radioState = [];
if (
    isClass (configFile >> "CfgPatches" >> "acre_main")
    && {!isNil "acre_api_fnc_isInitialized"}
    && {[] call acre_api_fnc_isInitialized}
) then {
    _radioState = [] call Waldo_fnc_ACRE2CaptureRadioState;
};
missionNamespace setVariable ["Waldo_Player_RadioState", _radioState];
if (_showNotification) then {
    [
        "RESPAWN LOADOUT SAVED",
        "Your current equipment and supported radio settings will be restored when you respawn.",
        "SUCCESS",
        5,
        "TOP_RIGHT",
        "RESPAWN_LOADOUT",
        "PLAYER LOADOUT",
        "REPLACE"
    ] call Waldo_fnc_ShowUiNotification;
};
true
