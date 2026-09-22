/*
 * Author: WaldoTheWarfighter
 * Purpose: Lists eligible nearby boxes and cargo-capable vehicles for a selected source.
 * Locality / Authority: Read-only interface helper; server independently validates the choice.
 * Repeat / JIP: Stateless. A newly registered crate or vehicle appears on the next panel open.
 * Arguments: source <OBJECT>. Return Value: destination objects <ARRAY>.
 * Current callers: transfer and merge destination choosers.
 * Example: private _targets = [myCrate] call Waldo_fnc_SupplyTransfersDestinationsLocal;
 */
params [["_source", objNull, [objNull]]];
if (!hasInterface || {isNull _source}) exitWith {[]};
private _range = (missionNamespace getVariable ["Waldo_SupplyTransfers_Range", 20]) max 2 min 50;
private _destinations = [];
{
    if (!isNull _x && {_x isNotEqualTo _source} && {_x distance _source <= _range}
        && {maxLoad _x > 0}) then {_destinations pushBackUnique _x};
} forEach (missionNamespace getVariable ["Waldo_SupplyTransfers_Registry", []]);
{
    if (_x isNotEqualTo _source && {alive _x} && {maxLoad _x > 0}) then {
        _destinations pushBackUnique _x;
    };
} forEach (nearestObjects [_source, ["LandVehicle", "Air", "Ship"], _range]);
_destinations
