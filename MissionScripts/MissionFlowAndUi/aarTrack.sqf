/*
 * Author: Waldo
 * Lightweight, event-driven after-action tracking for the ENDEX debrief.
 * Records mission start time and tallies infantry KIA per side (and player
 * losses) using the global EntityKilled mission event handler, which fires on
 * every machine for every entity - so a single server-side registration
 * captures all kills regardless of unit locality. No per-frame loops.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_AARTrack;
 */

if !(isServer) exitWith {};
if (missionNamespace getVariable ["Waldo_AAR_Initialised", false]) exitWith {};
missionNamespace setVariable ["Waldo_AAR_Initialised", true];

// [west, east, independent, civilian] KIA counts, plus player losses.
missionNamespace setVariable ["Waldo_AAR_KIA", [0,0,0,0], true];
missionNamespace setVariable ["Waldo_AAR_PlayerKIA", 0, true];
missionNamespace setVariable ["Waldo_AAR_StartTime", time, true];

addMissionEventHandler ["EntityKilled", {
    params ["_killed"];
    if (isNull _killed) exitWith {};
    if !(_killed isKindOf "CAManBase") exitWith {};

    private _idx = switch (side group _killed) do {
        case west: { 0 };
        case east: { 1 };
        case independent: { 2 };
        case civilian: { 3 };
        default { -1 };
    };
    if (_idx < 0) exitWith {};

    private _kia = +(missionNamespace getVariable ["Waldo_AAR_KIA", [0,0,0,0]]);
    _kia set [_idx, (_kia select _idx) + 1];
    missionNamespace setVariable ["Waldo_AAR_KIA", _kia, true];

    if (isPlayer _killed) then {
        missionNamespace setVariable ["Waldo_AAR_PlayerKIA",
            (missionNamespace getVariable ["Waldo_AAR_PlayerKIA", 0]) + 1, true];
    };
}];
