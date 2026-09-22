/*
 * Author: WaldoTheWarfighter
 * Purpose: Enables only the extra features exercised by this packaged test mission.
 * Locality / Authority: Every machine before the shared WMP config load; server publishes runtime state.
 * Repeat / JIP: Idempotent defaults; the server snapshot remains authoritative for joining clients.
 * Arguments: None. Return Value: Nothing.
 * Current caller: generated init.sqf pre-hook.
 * Example: call compile preprocessFileLineNumbers "serviceLogisticsTestPreInit.sqf";
 */
{
    if (isNil _x) then {missionNamespace setVariable [_x, true]};
} forEach ["Waldo_BaseServices_Enable", "Waldo_SupplyTransfers_Enable",
    "Waldo_PhysicalCargo_Enable", "Waldo_PhysicalCargo_BlockSeats"];
{
    private _name = format ["Waldo_QM_%1_Enable", _x];
    if (isNil _name) then {missionNamespace setVariable [_name, true]};
} forEach
    ["Grenades", "Explosives", "Rearm", "FuelBarrel", "FuelJerrycan"];
