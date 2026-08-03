/*
 * Author: WaldoTheWarfighter
 * Convenience "plant a tracker" helper for players and scripts. Tags a target (defaulting to the
 * object under the player's cursor) so the caller's side can follow it on the map. Wired to the ACE
 * "Plant Signal Tracker" interaction on units and vehicles by Waldo_fnc_JammingInit, and also usable
 * from a trigger or script. Forwards to the server via Waldo_fnc_Tracker.
 *
 * Arguments:
 * 0: Target <OBJECT> - the unit/vehicle to tag (optional, default: cursorTarget)
 * 1: Tracking side <SIDE or STRING> - who sees it (optional, default: the caller's side)
 * 2: Label <STRING> - marker label (optional, default: auto "TRK-<id>")
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [cursorTarget] call Waldo_fnc_TrackerAttach;
 * [enemyTruck, west, "Convoy Lead"] call Waldo_fnc_TrackerAttach;
 */

params [["_target", cursorTarget], ["_side", side player], ["_label", ""]];

if (isNull _target) exitWith {
    if (hasInterface) then { systemChat "No valid target to tag."; };
};

[_target, _side, _label] call Waldo_fnc_Tracker;

if (hasInterface) then {
    systemChat "Signal tracker planted - target now tracked on your map.";
    private _msg = parseText "<t color='#c8102e' size='1.3' align='center'>TRACKER PLANTED</t><br /><t size='0.9' align='center'>Target tracked on your map</t><br />";
    [_msg, 3] spawn Waldo_fnc_TimedHint;
};
