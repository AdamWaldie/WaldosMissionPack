/*
Author: Waldo
This function fetches your grop callsign using the role description, failing that it attempts to get it from the groupID field of the group itself.

Arguments:
_unit - Player [Object]

Returns:
Group Name [String Type]

Example:
[_unit] call Waldo_fnc_GetPlayerGroup;

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