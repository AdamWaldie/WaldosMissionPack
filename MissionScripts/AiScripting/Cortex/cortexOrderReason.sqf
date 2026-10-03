/*
 * Author: WaldoTheWarfighter
 * Explains why an explicit Cortex order cannot run, before touching the group's current orders.
 * Locality/authority: read-only anywhere; the current owner repeats this check before execution.
 * Repeat/JIP: no handlers, state changes or replay. Empty string means no known blocker.
 * Arguments: 0: group <GROUP>, grpNull; 1: order <STRING>, empty; 2: building <OBJECT>, objNull.
 * Return: STRING describing the blocker, or empty when the order may proceed.
 * Current callers: CortexOrderDialog and AIPassOrderLocal.
 * Example: [_group,"DEFEND"] call Waldo_fnc_CortexOrderReason;
 */
params [["_group",grpNull,[grpNull]],["_order","",[""]],["_building",objNull,[objNull]]];
if (isNull _group) exitWith {"Select a squad first."};
private _alive = units _group select {alive _x};
if (_alive isEqualTo []) exitWith {"The selected squad has no living members."};
if (units _group findIf {isPlayer _x} >= 0) exitWith {"Player squads cannot be given Cortex orders."};
if (_order in ["RELEASE","EXCLUDE","RETURN"]) exitWith {""};
if !(missionNamespace getVariable ["Waldo_AIPass_Enable",false]) exitWith {"Cortex behaviours are disabled. Enable them in Cortex Control > Overview & profiles first."};
if (local _group && {!(missionNamespace getVariable ["Waldo_AIPass_Active",false])}) exitWith {"Cortex is not ready on this squad's owner. Wait for settings to reach that machine and retry."};
if !([_group,true] call Waldo_fnc_CortexIsEligible) exitWith {"This squad is excluded, remote-controlled, outside the configured AI filters, or controlled by another feature. Release that control first."};
if (_order == "AIRBORNE") exitWith {
    private _air = vehicle leader _group;
    if !(_air isKindOf "Air") exitWith {"Select the passenger squad, not the aircraft crew. Its leader must be aboard the aircraft."};
    if (isNull driver _air || {isPlayer driver _air}) exitWith {"The aircraft needs a living AI pilot."};
    if ((getPosATL _air select 2) < (missionNamespace getVariable ["Waldo_AIPass_Airborne_MinAltitude",100]) || {surfaceIsWater getPosATL _air}) exitWith {"The aircraft must be above the configured jump altitude and over land."};
    if (_alive findIf {vehicle _x == _air && {(assignedVehicleRole _x) param [0,""] == "cargo"}} < 0) exitWith {"No passengers in this squad are ready to jump."};
    ""
};
private _foot = _alive select {vehicle _x == _x && {[_x] call Waldo_fnc_CortexCombatEffective}};
if (_foot isEqualTo []) exitWith {"The squad needs capable infantry on foot. Dismount its passengers before issuing this order."};
if (_order == "CLEAR" && {isNull _building || {!(_building isKindOf "House")} || {(_building buildingPos -1) isEqualTo []}}) exitWith {"Place Clear Building on a building with usable interior positions."};
if (_order == "CLEAR" && {count _foot < 2}) exitWith {"Clearing needs at least two capable soldiers on foot: a leader and a clearing soldier."};
""
