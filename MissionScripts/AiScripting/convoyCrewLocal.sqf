/*
 * Author: WaldoTheWarfighter
 * Keeps operating crew aboard, directs permitted mounted fire and unloads only snapshotted passengers on halt.
 * Locality/authority: each server/HC acts only on its own vehicles and units from the server registry.
 * Repeat/JIP: five-second owner checks replay a durable halt after transfer; current seats are revalidated.
 * Arguments: 0: group <GROUP>; 1: configuration <ARRAY> [revision, speed, gap, push, vehicles, phase, cargo, restore, halt reason, believed threat ATL, expiry].
 * Return Value: Nothing. Unconscious passengers wait until capable; players and remote-controlled units are skipped.
 * Current callers: ConvoyTick on every AI-owning machine.
 * Example: [_group, _configuration] call Waldo_fnc_ConvoyCrewLocal;
 */
params ["_group", "_configuration"];
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {};
_configuration params ["_revision", "", "", "", "_vehicles", "_phase", "_cargo", "_restore", ["_reason", "MANUAL"], ["_threat", []], ["_deadline", 0]];
if (time < (_group getVariable ["Waldo_Convoy_CrewDue", -1])) exitWith {};
_group setVariable ["Waldo_Convoy_CrewDue", time + 5];
if (_group getVariable ["Waldo_AI_ExternalControl",false] || {"ALL" in (_group getVariable ["Waldo_AIPass_DisabledFeatures",[]])} || {[] call Waldo_fnc_AIPassIsPaused} || {[_group] call Waldo_fnc_AIPassZeusHeld}
    || {_vehicles findIf {(crew _x) findIf {isPlayer _x || {!isNull (_x getVariable ["bis_fnc_moduleRemoteControl_owner", objNull])}} >= 0} >= 0}) exitWith {[_group, _configuration, true] call Waldo_fnc_ConvoyDismountLocal};
private _seats = createHashMap;
{
    private _vehicle = _x;
    if (alive _vehicle) then {
        if (local _vehicle) then {
            if (isNil {_vehicle getVariable "Waldo_Convoy_HitEH"}) then {
                _vehicle setVariable ["Waldo_Convoy_HitEH", _vehicle addEventHandler ["Hit", {
                    params ["_vehicle", "_source", "_damage", "_instigator"];
                    if (!local _vehicle || {!(_vehicle getVariable ["Waldo_Convoy_Active", false])} || {_damage <= 0}) exitWith {};
                    if (isNull _instigator) exitWith {};
                    if ((side group driver _vehicle) getFriend (side group _instigator) >= 0.6) exitWith {};
                    if (serverTime - (_vehicle getVariable ["Waldo_Convoy_HitAt", -1e9]) >= 5) then {
                        _vehicle setVariable ["Waldo_Convoy_HitAt", serverTime, true];
                    };
                }]];
            };
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
            private _fireEnabled = [_group,"Waldo_Convoy_MountedFire_Enable",true] call Waldo_fnc_AIPassFeatureEnabled && {[group _unit,"Waldo_Convoy_MountedFire_Enable",true] call Waldo_fnc_AIPassFeatureEnabled};
            if (local _unit && {!isPlayer _unit} && {!_fireEnabled || {!(combatMode group _unit in ["YELLOW", "RED"] && {unitCombatMode _unit in ["YELLOW", "RED"]})}}) then {
                private _previous = _unit getVariable ["Waldo_Convoy_Target", objNull];
                if (!isNull _previous && {assignedTarget _unit == _previous}) then {_unit doTarget objNull};
                _unit setVariable ["Waldo_Convoy_Target", nil, true];
            };
            if (_fireEnabled && {local _unit} && {alive _unit} && {!isPlayer _unit} && {!_personTurret} && {_role in ["gunner", "commander", "turret"]}
                && {!(_unit getVariable ["ACE_isUnconscious", false])} && {lifeState _unit != "INCAPACITATED"}
                && {combatMode group _unit in ["YELLOW", "RED"]} && {unitCombatMode _unit in ["YELLOW", "RED"]}) then {
                private _report = [_unit] call Waldo_fnc_ConvoyThreat;
                if (_report isNotEqualTo []) then {
                    private _enemy = _report select 0;
                    // Target/fire never orders pursuit or changes ROE.
                    if (assignedTarget _unit != _enemy) then {
                        _unit doTarget _enemy;
                        _unit doFire _enemy;
                        _unit setVariable ["Waldo_Convoy_Target", _enemy, true];
                    };
                } else {
                    private _previous = _unit getVariable ["Waldo_Convoy_Target", objNull];
                    if (!isNull _previous && {assignedTarget _unit == _previous}) then {_unit doTarget objNull};
                    _unit setVariable ["Waldo_Convoy_Target", nil, true];
                };
            };
        } forEach fullCrew [_vehicle, "", false];
    };
} forEach _vehicles;
if (_phase != "HALT") exitWith {};
{
    _x params ["_unit", "_vehicle"];
    if (local _unit && {vehicle _unit == _unit} && {(_unit getVariable ["Waldo_Convoy_Unloaded", []]) isNotEqualTo [_group, _revision]}) then {_unit setVariable ["Waldo_Convoy_Unloaded", [_group, _revision], true]};
    if ([_group,"Waldo_Convoy_Unload_Enable",true] call Waldo_fnc_AIPassFeatureEnabled && {[group _unit,"Waldo_Convoy_Unload_Enable",true] call Waldo_fnc_AIPassFeatureEnabled} && {[_unit,_vehicle] call Waldo_fnc_AIPassPassengerReady}
        && {local _unit} && {alive _unit} && {!isPlayer _unit} && {vehicle _unit == _vehicle}
        && {(_unit getVariable ["Waldo_Convoy_Unloaded", []]) isNotEqualTo [_group, _revision]}
        && {abs speed _vehicle < 1} && {!(_unit getVariable ["ACE_isUnconscious", false])} && {lifeState _unit != "INCAPACITATED"}
        && {!isPlayer leader group _unit} && {!([group _unit] call Waldo_fnc_AIPassZeusHeld)} && {isNull (_unit getVariable ["bis_fnc_moduleRemoteControl_owner", objNull])}) then {
        private _seat = _seats getOrDefault [netId _unit, []];
        if (_seat isNotEqualTo [] && {(_seat select 0) == _vehicle} && {(_seat select 1) == "cargo" || {_seat select 2}}) then {
            if ([_group,"Waldo_Convoy_Cover_Enable",true] call Waldo_fnc_AIPassFeatureEnabled && {[group _unit,"Waldo_Convoy_Cover_Enable",true] call Waldo_fnc_AIPassFeatureEnabled} && {_reason == "AMBUSH"} && {serverTime < _deadline} && {isNil {_unit getVariable "Waldo_Convoy_Dismount"}}) then {
                _unit setVariable ["Waldo_Convoy_Dismount", [_group, _revision, _deadline, []], true];
            };
            unassignVehicle _unit;
            doGetOut _unit;
        };
    };
} forEach _cargo;

[_group, _configuration] call Waldo_fnc_ConvoyDismountLocal;
