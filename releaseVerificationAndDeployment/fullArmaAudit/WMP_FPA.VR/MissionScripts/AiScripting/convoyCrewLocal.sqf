/*
 * Author: WaldoTheWarfighter
 * Keeps operating crew aboard, directs permitted mounted fire and unloads only snapshotted passengers on halt.
 * Locality/authority: each server/HC acts only on its own vehicles and units from the server registry.
 * Repeat/JIP: five-second owner checks replay a durable halt after transfer; current seats are revalidated.
 * Arguments: 0: group <GROUP>; 1: configuration <ARRAY> [revision, speed, gap, push, vehicles, phase, cargo, restore].
 * Return Value: Nothing. Unconscious passengers wait until capable; players and remote-controlled units are skipped.
 * Current callers: ConvoyTick on every AI-owning machine.
 * Example: [_group, _configuration] call Waldo_fnc_ConvoyCrewLocal;
 */
params ["_group", "_configuration"];
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {};
_configuration params ["_revision", "", "", "", "_vehicles", "_phase", "_cargo", "_restore"];
if (time < (_group getVariable ["Waldo_Convoy_CrewDue", -1])) exitWith {};
_group setVariable ["Waldo_Convoy_CrewDue", time + 5];
if ([] call Waldo_fnc_AIPassIsPaused || {[_group] call Waldo_fnc_AIPassZeusHeld}
    || {_vehicles findIf {(crew _x) findIf {isPlayer _x || {!isNull (_x getVariable ["bis_fnc_moduleRemoteControl_owner", objNull])}} >= 0} >= 0}) exitWith {};
private _seats = createHashMap;
{
    private _vehicle = _x;
    if (alive _vehicle) then {
        if (local _vehicle) then {
            // Explicit cargo orders decide unloading; operating turrets never receive a dismount order.
            if (getUnloadInCombat _vehicle isNotEqualTo [false, false]) then {_vehicle setUnloadInCombat [false, false]};
            if (_phase == "HALT") then {
                _vehicle forceSpeed 0;
                if (local driver _vehicle && {!isNull driver _vehicle}) then {doStop driver _vehicle};
            };
        };
        {
            _x params ["_unit", "_role", "", "", "_personTurret"];
            _seats set [netId _unit, [_vehicle, _role, _personTurret]];
            if (local _unit && {alive _unit} && {!isPlayer _unit} && {!_personTurret} && {_role in ["gunner", "commander", "turret"]}
                && {!(_unit getVariable ["ACE_isUnconscious", false])} && {lifeState _unit != "INCAPACITATED"}
                && {combatMode group _unit in ["YELLOW", "RED"]} && {unitCombatMode _unit in ["YELLOW", "RED"]}) then {
                private _enemy = _unit findNearestEnemy _unit;
                private _knowledge = _unit targetKnowledge _enemy;
                if (!isNull _enemy && {alive _enemy} && {_unit knowsAbout _enemy >= 1.5}
                    && {side group _unit getFriend side _enemy < 0.6}
                    && {_unit distance2D (_unit getHideFrom _enemy) <= 800}
                    && {time - ((_knowledge select 2) max (_knowledge select 3)) <= 30}) then {
                    // Keep vehicle movement with the convoy. Target/fire never orders pursuit or changes ROE.
                    if (assignedTarget _unit != _enemy) then {
                        _unit doTarget _enemy;
                        _unit doFire _enemy;
                        _unit setVariable ["Waldo_Convoy_Target", _enemy];
                    };
                };
            };
        } forEach fullCrew [_vehicle, "", false];
    };
} forEach _vehicles;
if (_phase != "HALT") exitWith {};
{
    _x params ["_unit", "_vehicle"];
    if (local _unit && {alive _unit} && {!isPlayer _unit} && {vehicle _unit == _vehicle}
        && {abs speed _vehicle < 1} && {!(_unit getVariable ["ACE_isUnconscious", false])} && {lifeState _unit != "INCAPACITATED"}
        && {!isPlayer leader group _unit} && {!([group _unit] call Waldo_fnc_AIPassZeusHeld)} && {isNull (_unit getVariable ["bis_fnc_moduleRemoteControl_owner", objNull])}) then {
        private _seat = _seats getOrDefault [netId _unit, []];
        if (_seat isNotEqualTo [] && {(_seat select 0) == _vehicle} && {(_seat select 1) == "cargo" || {_seat select 2}}) then {
            unassignVehicle _unit;
            doGetOut _unit;
        };
    };
} forEach _cargo;
