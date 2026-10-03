/*
 * Author: WaldoTheWarfighter
 * Keeps travelling occupants assigned to their actual seats, directs mounted fire and unloads only snapshotted passengers on halt.
 * Locality/authority: each server/HC acts only on its own vehicles and units from the server registry.
 * Hostile Hit events count as contact even when armour absorbs the damage.
 * Repeat/JIP: five-second owner checks repair occupied seat assignments and replay a durable halt
 * after transfer. Boarding orders are cancelled before unloading; driver and operating turret roles are excluded.
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
if (_group getVariable ["Waldo_AI_ExternalControl",false] || {"ALL" in (_group getVariable ["Waldo_AIPass_DisabledFeatures",[]])} || {[] call Waldo_fnc_CortexIsPaused} || {[_group] call Waldo_fnc_CortexZeusHeld}
    || {_vehicles findIf {(crew _x) findIf {isPlayer _x || {!isNull (_x getVariable ["bis_fnc_moduleRemoteControl_owner", objNull])}} >= 0} >= 0}) exitWith {[_group, _configuration, true] call Waldo_fnc_ConvoyDismountLocal};
private _seats = createHashMap;
{
    private _vehicle = _x;
    if (alive _vehicle) then {
        if (local _vehicle) then {
            if (isNil {_vehicle getVariable "Waldo_Convoy_HitEH"}) then {
                _vehicle setVariable ["Waldo_Convoy_HitEH", _vehicle addEventHandler ["Hit", {
                    params ["_vehicle", "_source", "_damage", "_instigator"];
                    if (!local _vehicle || {!(_vehicle getVariable ["Waldo_Convoy_Active", false])}) exitWith {};
                    if (isNull _instigator) exitWith {};
                    if ((side group driver _vehicle) getFriend (side group _instigator) >= 0.6) exitWith {};
                    if (serverTime - (_vehicle getVariable ["Waldo_Convoy_HitAt", -1e9]) >= 5) then {
                        _vehicle setVariable ["Waldo_Convoy_HitAt", serverTime, true];
                    };
                }]];
            };
            // Explicit cargo orders decide unloading; operating turrets never receive a dismount order.
            if (getUnloadInCombat _vehicle isNotEqualTo [false, false]) then {_vehicle setUnloadInCombat [false, false]};

        };
        {
            _x params ["_unit", "_role", "_cargoIndex", "_turretPath", "_personTurret"];
            _seats set [netId _unit, [_vehicle, _role, _personTurret]];
            // Physical occupancy and the engine boarding assignment are separate.
            // Repair the actual seat for crew as well as passengers on that unit's owner.
            // Only occupants already aboard are adopted; dismounted troops are not forced back in.
            private _passenger = _role == "cargo" || {_role == "turret" && {_personTurret}};
            private _assignedOccupant = _x param [5,objNull];
            if ((_phase == "TRAVEL" || {!_passenger}) && {canMove _vehicle} && {local _unit} && {alive _unit} && {!isPlayer _unit}
                && {vehicle _unit == _vehicle}
                && {!isPlayer leader group _unit} && {!([group _unit] call Waldo_fnc_CortexZeusHeld)}
                && {!((group _unit) getVariable ["Waldo_AI_ExternalControl",false])}
                && {!("ALL" in ((group _unit) getVariable ["Waldo_AIPass_DisabledFeatures",[]]))}
                && {isNull (_unit getVariable ["bis_fnc_moduleRemoteControl_owner",objNull])}
                && {[_unit] call Waldo_fnc_CortexCombatEffective}) then {
                private _repairSeat=assignedVehicle _unit != _vehicle || {_assignedOccupant != _unit};
                private _previousAssignment=_unit getVariable ["Waldo_Convoy_PassengerRevision",[]];
                private _newAssignment=_previousAssignment isNotEqualTo [_group,_revision,clientOwner];
                private _newController=(_previousAssignment param [0,grpNull]) != _group || {(_previousAssignment param [2,-1]) != clientOwner};
                if (_repairSeat) then {
                    switch (_role) do {
                        case "driver": {_unit assignAsDriver _vehicle};
                        case "commander": {_unit assignAsCommander _vehicle};
                        case "gunner": {_unit assignAsGunner _vehicle};
                        case "cargo": {_unit assignAsCargoIndex [_vehicle,_cargoIndex]};
                        default {_unit assignAsTurret [_vehicle,_turretPath]};
                    };
                };
                // Already-mounted occupants need no repeated boarding command. Reissuing it
                // can compete with the driver's path/halt order even when the seat is unchanged.
                if (_repairSeat || {_newController && {_phase == "TRAVEL"}}) then {[_unit] orderGetIn true};
                if (_newAssignment) then {
                    _unit setVariable ["Waldo_Convoy_PassengerRevision",[_group,_revision,clientOwner],true];
                };
            };
            private _fireEnabled = [_group,"Waldo_Convoy_MountedFire_Enable",true] call Waldo_fnc_CortexFeatureEnabled && {[group _unit,"Waldo_Convoy_MountedFire_Enable",true] call Waldo_fnc_CortexFeatureEnabled};
            if (local _unit && {!isPlayer _unit} && {!_fireEnabled || {!(combatMode group _unit in ["YELLOW", "RED"] && {unitCombatMode _unit in ["YELLOW", "RED"]})}}) then {
                private _previous = _unit getVariable ["Waldo_Convoy_Target", objNull];
                if (!isNull _previous && {assignedTarget _unit == _previous}) then {_unit doTarget objNull};
                if (!isNil {_unit getVariable "Waldo_Convoy_Target"}) then {_unit setVariable ["Waldo_Convoy_Target", nil, true]};
            };
            if (_fireEnabled && {local _unit} && {alive _unit} && {!isPlayer _unit} && {!_passenger} && {_role in ["gunner", "commander", "turret"]}
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
                    if (!isNil {_unit getVariable "Waldo_Convoy_Target"}) then {_unit setVariable ["Waldo_Convoy_Target", nil, true]};
                };
            };
        } forEach fullCrew [_vehicle, "", false];
        // Stop after any necessary boarding repair so the last driver command remains HALT.
        if (_phase == "HALT" && {local _vehicle}) then {
            // Some tracked steering controllers retain the last drive path despite driver STOP.
            // Retire that movement source explicitly before applying the stationary command.
            if (isAISteeringComponentEnabled _vehicle) then {
                _vehicle setDriveOnPath [];
                // A driver can already report STOP while executing a scripted path.
                // Replace that path with a current-position move once per halt/owner,
                // then stop it. This uses navigation, never position or velocity changes.
                private _haltOwner=[_group,_revision,clientOwner];
                if ((_vehicle getVariable ["Waldo_Convoy_HaltOwner",[]]) isNotEqualTo _haltOwner) then {
                    _vehicle move getPosATL _vehicle;
                    _vehicle setVariable ["Waldo_Convoy_HaltOwner",_haltOwner];
                };
            };
            _vehicle forceSpeed 0;
            if (local driver _vehicle && {!isNull driver _vehicle}) then {doStop driver _vehicle};
        };
    };
} forEach _vehicles;
if (_phase != "HALT") exitWith {};
{
    _x params ["_unit", "_vehicle"];
    if (local _unit && {vehicle _unit == _unit} && {(_unit getVariable ["Waldo_Convoy_Unloaded", []]) isNotEqualTo [_group, _revision]}) then {_unit setVariable ["Waldo_Convoy_Unloaded", [_group, _revision], true]};
    if ([_group,"Waldo_Convoy_Unload_Enable",true] call Waldo_fnc_CortexFeatureEnabled && {[group _unit,"Waldo_Convoy_Unload_Enable",true] call Waldo_fnc_CortexFeatureEnabled} && {[_unit,_vehicle] call Waldo_fnc_CortexPassengerReady}
        && {local _unit} && {alive _unit} && {!isPlayer _unit} && {vehicle _unit == _vehicle}
        && {(_unit getVariable ["Waldo_Convoy_Unloaded", []]) isNotEqualTo [_group, _revision]}
        && {abs speed _vehicle < 1} && {!(_unit getVariable ["ACE_isUnconscious", false])} && {lifeState _unit != "INCAPACITATED"}
        && {!isPlayer leader group _unit} && {!([group _unit] call Waldo_fnc_CortexZeusHeld)} && {isNull (_unit getVariable ["bis_fnc_moduleRemoteControl_owner", objNull])}) then {
        private _seat = _seats getOrDefault [netId _unit, []];
        if (_seat isNotEqualTo [] && {(_seat select 0) == _vehicle} && {(_seat select 1) == "cargo" || {(_seat select 1) == "turret" && {_seat select 2}}}) then {
            if ([_group,"Waldo_Convoy_Cover_Enable",true] call Waldo_fnc_CortexFeatureEnabled && {[group _unit,"Waldo_Convoy_Cover_Enable",true] call Waldo_fnc_CortexFeatureEnabled} && {serverTime < _deadline} && {isNil {_unit getVariable "Waldo_Convoy_Dismount"}}) then {
                _unit setVariable ["Waldo_Convoy_Dismount", [_group, _revision, _deadline, []], true];
            };
            [_unit] orderGetIn false;
            unassignVehicle _unit;
            doGetOut _unit;
        };
    };
} forEach _cargo;

[_group, _configuration] call Waldo_fnc_ConvoyDismountLocal;
