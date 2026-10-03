/*
 * Author: WaldoTheWarfighter
 * Installs the local player's inventory-open handler for armed corpses.
 * Locality and authority: Interface-client only; it sends a trigger request to the server when
 * the current player opens a corpse marked ARMED.
 * Repeat/JIP: The unit flag prevents duplicate event handlers. CorpseTrapInit calls this on
 * initial join and again for a new player unit after respawn.
 * Arguments:
 * 0: current player unit <OBJECT> (default objNull)
 * Return Value: <BOOL> - true if already installed or now installed; false for another unit.
 * Current caller: Waldo_fnc_CorpseTrapInit and its respawn class event handler.
 * Example: [player] call Waldo_fnc_CorpseTrapInstallInventoryHandler;
 * Result: Opening an armed corpse's inventory requests one authoritative trap trigger.
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
