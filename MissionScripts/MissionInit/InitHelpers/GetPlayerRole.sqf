/*
Author: Waldo
This function fetches your player role using the role description, failing that it retrieves a generic role from the config.

Arguments:
N/A

Returns:
Role Name [String Type]

Example:
call Waldo_fnc_SetTeamColour;

*/
private _return = "Infantry";

if !(isMultiplayer) exitWith { _return };

private _playerRole = roleDescription player;

if !(_playerRole == "") then {
    _playerRole = _playerRole splitString "@";
    _playerRole = _playerRole select 0;
    _return = _playerRole;
} else {
    _playerRole = getText (configFile >> "CfgVehicles" >> typeOf player >> "displayName");
    _playerRole = _playerRole splitString " ";
    if (_playerRole select 0 in ["Platoon", "Squad"]) then {
            _return = [_playerRole select 0, _playerRole select 1] joinString " ";
    } else {
        _return = _playerRole joinString " ";
    };
};

_return;