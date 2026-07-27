/*
 * Installs the player-local InventoryOpened handler on a newly joined or
 * respawned player object.
 */
params [
    ["_unit", objNull, [objNull]]
];

if (!hasInterface || {isNull _unit} || {_unit != player}) exitWith {false};
if (_unit getVariable ["Waldo_CorpseTrap_InventoryHandler", false]) exitWith {true};

_unit setVariable ["Waldo_CorpseTrap_InventoryHandler", true];
_unit addEventHandler ["InventoryOpened", {
    params ["_unit", "_primaryContainer", "_secondaryContainer"];

    private _corpse = objNull;
    {
        if (
            !isNull _x
            && {_x isKindOf "CAManBase"}
            && {!alive _x}
            && {_x getVariable ["Waldo_CorpseTrap_State", ""] == "ARMED"}
        ) exitWith {
            _corpse = _x;
        };
    } forEach [_primaryContainer, _secondaryContainer];

    if (!isNull _corpse) then {
        [_corpse, _unit] remoteExecCall ["Waldo_fnc_CorpseTrapTriggerServer", 2];
    };

    false
}];

true
