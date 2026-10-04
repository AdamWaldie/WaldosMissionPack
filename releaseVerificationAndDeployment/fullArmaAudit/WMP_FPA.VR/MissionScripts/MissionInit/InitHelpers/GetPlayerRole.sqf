/*
 * Author: WaldoTheWarfighter
 * Returns the local player's Eden role description before `@`, falling back to the unit class
 * display name. Singleplayer returns "Infantry".
 * Locality/authority: player interface only; this reads local player state and changes nothing.
 * Repeat/JIP: repeat-safe, with no persistent state or event handler. A joining player reads their
 * own current role when the function runs.
 * Arguments: none. The function always reads local `player`.
 * Return Value: STRING - readable role name.
 * Current callers: mission-maker scripts and role-aware WMP setup.
 * Example: private _role = call Waldo_fnc_GetPlayerRole;
 * Result: _role contains the text before `@` in the local player's role description.
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
