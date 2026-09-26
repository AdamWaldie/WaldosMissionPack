/*
 * Author: WaldoTheWarfighter
 * Returns a unit's group callsign from its leader's Eden role description after `@`. Falls back
 * to the group ID only when that description is empty. A nonempty role must include `@`.
 * Singleplayer returns an empty string.
 * Locality/authority: read-only call on a machine that knows the unit and leader. It does not
 * change the Arma group or broadcast a label.
 * Repeat/JIP: repeat-safe and stateless; joining clients read the current leader when called.
 * Arguments: 0: unit <OBJECT> - member whose group name is wanted (default: local player).
 * Return Value: STRING - uppercase callsign or group ID when the leader role is empty; empty in
 * singleplayer. A nonempty leader role without `@` does not provide a valid callsign part.
 * Current callers: mission-maker scripts and role-aware WMP setup.
 * Example: private _name = [player] call Waldo_fnc_GetPlayerGroup;
 * Result: _name contains the text after `@` in the group's leader role description.
 */
params[["_unit",player]];

private _return = "";

if !(isMultiplayer) exitWith { _return };

private _groupName = roleDescription (leader _unit);

if !(_groupName == "") then {
    _groupName = _groupName splitString "@";
    _groupName = _groupName select 1;
    _groupName = toUpper (_groupName);
    _return = _groupName;
} else {
    private _groupName = groupId (group _unit);
    _return = toUpper(_groupName);
};

_return;
