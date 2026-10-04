/*
 * Author: WaldoTheWarfighter
 * Vehicle drills for a squad in contact: dismount infantry under fire, and pull a
 * damaged vehicle back behind smoke.
 *
 * Dismount records ownership before issuing exit commands, then cancels outstanding boarding orders.
 * Exit handlers can therefore identify the initiating controller without racing bookkeeping.
 * Crew owners publish a bounded, expiring approximate contact report for separate onboard groups.
 * A validated passenger-owner request temporarily forces the vehicle to zero speed, preserving and
 * restoring any earlier forced-speed value once that passenger squad is out or the request expires.
 * Separate passenger groups handle only their own local cargo. Only the operating
 * crew group may order vehicle withdrawal or gunnery; convoy ownership remains excluded.
 * Dismount: infantry riding as cargo in a ground vehicle get out once an enemy is
 * believed within 400 m, instead of dying inside a truck. They are recorded and ordered back in when
 * the squad returns to CALM (Waldo_fnc_CortexRestoreCalm).
 * Withdraw: a vehicle that can still move but is at 50% damage or (if it carries a real weapon, not
 * just a horn or countermeasure launcher) has lost its weapons, with an enemy
 * within 800 m, fires its smoke launcher (Waldo_fnc_CortexFireCountermeasure). If the whole squad is
 * mounted, it withdraws towards one of five terrain-checked points roughly 300 m away from the enemy
 * (RETREAT phase, through an inserted waypoint). Each vehicle withdraws once per engagement.
 * Gunnery (Waldo_AIPass_VehicleGunnery_Enable): the AI gunner is pointed at the most dangerous
 * enemy seen in the last 15 s within 600 m: anti-tank infantry first, then armour, then anything
 * else, nearest first, held for 8 s. A fully mounted tank or APC that knows of an anti-tank soldier
 * within 60% of Waldo_AIPass_Vehicles_StandoffDistance backs off to that distance, at most once a
 * minute, through an inserted waypoint.
 * A withdrawal or standoff owns group movement until its tagged waypoint completes or its bounded
 * lease expires. Other Cortex manoeuvres may continue their combat layers but cannot replace that
 * movement. Conversely, this layer preserves and yields to every active non-vehicle movement lease
 * while continuing composable gunnery, reporting and passenger handling. A withdrawal outranks
 * standoff inside the same evaluation.
 * Vehicles owned by other WMP features never reach this function (Waldo_fnc_CortexIsEligible).
 * Locality and authority: call where the group is local.
 *
 * Repeat/JIP: current feature gates and eligibility are rechecked. A vehicle withdrawal publishes
 * its origin, target, deadline and progress so the new group owner resumes it after migration;
 * countermeasures are not fired again. Standoff is finite and may be reassessed after adoption.
 * Arguments:
 * 0: group <GROUP>
 * 1: state <HASHMAP>
 * 2: enemies <ARRAY> - from Waldo_fnc_CortexKnowledge
 *
 * Return Value:
 * Boolean - true while vehicle withdrawal or standoff owns group movement
 *
 * Example:
 * [_group, _state, _enemies] call Waldo_fnc_CortexVehicles;
 * Result: a squad caught in its truck bails out and fights on foot.
 *
 * Current caller: Waldo_fnc_CortexGroupTick.
 */

params [["_group", grpNull, [grpNull]], ["_state", createHashMap, [createHashMap]], ["_enemies", [], [[]]]];
private _vehicleMove = _state getOrDefault ["movementLease",[]];
private _activeVehicleMove = false;
if (_vehicleMove isNotEqualTo []) then {
    private _vehicleOwnsLease = (_vehicleMove param [0,""]) in ["VEHICLE_WITHDRAW","VEHICLE_STANDOFF"];
    if (_vehicleOwnsLease) then {
        _activeVehicleMove = ((waypoints _group) findIf {
            (_x select 1) >= currentWaypoint _group && {waypointDescription _x == "WMP AI PASS"}
        } >= 0) && {time < (_vehicleMove select 1)};
        if (!_activeVehicleMove) then {
            [_group,_vehicleMove param [0,""],false] call Waldo_fnc_CortexLambsLease;
            _state deleteAt "movementLease";
        };
    } else {
        // The group tick has already validated direct tactical/support owners.
        // Yield to them without requiring a waypoint or deleting their lease.
        _activeVehicleMove = count _vehicleMove == 2 && {time < (_vehicleMove select 1)};
    };
};
// Movement ownership blocks only another destination. Reporting, dismount handling and
// gunnery remain composable for the duration of the physical move.
private _movementOwned = _activeVehicleMove;
private _vehicles = [];
{
    private _vehicle = vehicle _x;
    if (_vehicle != _x && {alive _x} && {!(_vehicle in _vehicles)} ) then {_vehicles pushBack _vehicle};
} forEach units _group;
if (_vehicles isEqualTo []) exitWith {_movementOwned};
// Cross-group safe-stop handshake. The passenger owner publishes only an expiring identity request;
// the vehicle authority validates current occupants and changes speed locally. This avoids remote
// driver commands, unsafe moving exits and permanent stops after an interrupted/expired handover.
{
    private _vehicle=_x;
    private _request=_vehicle getVariable ["Waldo_Cortex_DismountStopRequest",[]];
    private _saved=_vehicle getVariable ["Waldo_Cortex_DismountForcedSpeed",[]];
    private _valid=false;
    if (count _request == 3 && {local _vehicle} && {effectiveCommander _vehicle in units _group}) then {
        _request params ["_passengerGroup","_passengerOwner","_requestExpiry"];
        _valid=_passengerGroup isEqualType grpNull && {!isNull _passengerGroup}
            && {_passengerOwner isEqualType 0} && {_requestExpiry isEqualType 0}
            && {groupOwner _passengerGroup == _passengerOwner}
            && {side _passengerGroup == side _group}
            && {serverTime < _requestExpiry} && {_requestExpiry <= serverTime+30}
            && {(fullCrew [_vehicle,"",false]) findIf {
                private _unit=_x select 0;
                private _role=_x select 1;
                alive _unit && {group _unit == _passengerGroup}
                    && {_role == "cargo" || {_role == "turret" && {_x select 4}}}
            } >= 0};
    };
    if (_valid) then {
        if (_saved isEqualTo []) then {
            _saved=[getForcedSpeed _vehicle];
            _vehicle setVariable ["Waldo_Cortex_DismountForcedSpeed",_saved];
        };
        _vehicle forceSpeed 0;
    } else {
        if (_saved isNotEqualTo [] && {local _vehicle}) then {_vehicle forceSpeed (_saved param [0,-1])};
        _vehicle setVariable ["Waldo_Cortex_DismountForcedSpeed",nil];
        if (_request isNotEqualTo []) then {_vehicle setVariable ["Waldo_Cortex_DismountStopRequest",nil,true]};
    };
} forEach _vehicles;
if (_enemies isEqualTo []) exitWith {_movementOwned};
private _enemyPos = (_enemies select 0) select 1;
private _selectVehicleEscape = {
    params ["_vehicle","_threatPosition","_threatObject","_distance"];
    private _origin=getPosATL _vehicle;
    private _awayBearing=_threatPosition getDir _origin;
    private _candidates=[];
    {
        _candidates pushBack [_origin getPos [_distance,_awayBearing+_x]];
    } forEach [0,-25,25,-45,45];
    private _selected=[_origin,_candidates,_threatPosition,[],_threatObject,"VEHICLE"]
        call Waldo_fnc_CortexSelectAvenue;
    if (_selected isEqualTo []) then {[]} else {_selected select ((count _selected)-1)}
};
private _withdrawn = _state getOrDefault ["withdrawn", []];
{
    private _vehicle = _x;
    private _distance = _vehicle distance2D _enemyPos;
    private _commandsVehicle = effectiveCommander _vehicle in units _group;
    // Onboard reports carry no target object or reveal. Only the actual vehicle authority
    // publishes, at most once per five seconds and only when another squad is aboard.
    if (_commandsVehicle && {local _vehicle} && {_vehicle isKindOf "LandVehicle"}
        && {(_enemies select 0) select 2 <= 10}
        && {serverTime >= (_vehicle getVariable ["Waldo_Cortex_OnboardReportDue",-1])}
        && {(crew _vehicle) findIf {alive _x && {group _x != _group} && {side group _x == side _group}} >= 0}) then {
        private _reportedPosition=[25*round ((_enemyPos select 0)/25),25*round ((_enemyPos select 1)/25),0];
        // The far scheduler tier is 20 seconds. A shorter report could expire between the
        // independently scheduled crew and passenger jobs and make a valid handover impossible.
        _vehicle setVariable ["Waldo_Cortex_OnboardReport",[_group,groupOwner _group,_reportedPosition,serverTime+35],true];
        _vehicle setVariable ["Waldo_Cortex_OnboardReportDue",serverTime+5];
    };
    if (_vehicle isKindOf "LandVehicle" && {!(_vehicle isKindOf "StaticWeapon")} && {_distance < 400} && {[_group, "Waldo_AIPass_VehicleDismount_Enable", true] call Waldo_fnc_CortexFeatureEnabled}) then {
        // A combined crew/passenger group has no cross-group report consumer. Use the same
        // bounded handshake locally so moving cargo is brought to a safe stop before PassengerReady
        // can admit an exit. The next owner tick restores speed after the last cargo seat clears.
        private _onboardCargo=(fullCrew [_vehicle,"",false]) select {
            private _unit=_x select 0;
            private _role=_x select 1;
            alive _unit && {group _unit == _group}
                && {_role == "cargo" || {_role == "turret" && {_x select 4}}}
        };
        if (_commandsVehicle && {local _vehicle} && {_onboardCargo isNotEqualTo []}) then {
            _vehicle setVariable ["Waldo_Cortex_DismountStopRequest",[_group,groupOwner _group,serverTime+30],true];
            if ((_vehicle getVariable ["Waldo_Cortex_DismountForcedSpeed",[]]) isEqualTo []) then {
                _vehicle setVariable ["Waldo_Cortex_DismountForcedSpeed",[getForcedSpeed _vehicle]];
            };
            _vehicle forceSpeed 0;
        };
        private _cargo = (crew _vehicle) select {
            group _x == _group && {[_x, _vehicle] call Waldo_fnc_CortexPassengerReady}
        };
        if (_cargo isNotEqualTo []) then {
            private _dismounted = _state getOrDefault ["dismounted", []];
            {
                private _unit = _x;
                // Publish local ownership before commands can trigger GetOut handlers.
                // Still aboard on a later tick: reissue the order but record only once.
                if (_dismounted findIf {(_x select 0) == _unit} < 0) then {_dismounted pushBack [_unit, _vehicle]};
                _state set ["dismounted", _dismounted];
                [_unit] orderGetIn false;
                unassignVehicle _unit;
                doGetOut _unit;
            } forEach _cargo;
            _state set ["dismounted", _dismounted];
        };
    };
    // Horns and countermeasure launchers are CfgWeapons entries too; only a real weapon makes a
    // vehicle "armed", so an unarmed truck is never treated as having lost its guns. Read live (and
    // only once canFire already says no), because Vehicle Weapon Loadout can change a vehicle's guns.
    private _hasRealWeapon = {
        ([[-1]] + allTurrets [_vehicle, true]) findIf {
            (_vehicle weaponsTurret _x) findIf {
                private _weaponConfig = configFile >> "CfgWeapons" >> _x;
                toLowerANSI (getText (_weaponConfig >> "displayName")) != "horn"
                && {getText (_weaponConfig >> "simulation") != "cmlauncher"}
            } >= 0
        } >= 0
    };
    if (_commandsVehicle && {_vehicle isKindOf "LandVehicle"} && {[_group, "Waldo_AIPass_VehicleWithdraw_Enable", true] call Waldo_fnc_CortexFeatureEnabled} && {local _vehicle} && {alive _vehicle} && {canMove _vehicle} && {!(_vehicle in _withdrawn)} && {_distance < 800}
        && {damage _vehicle >= 0.5 || {!canFire _vehicle && {call _hasRealWeapon}}}) then {
        _withdrawn pushBack _vehicle;
        _state set ["withdrawn", _withdrawn];
        [_vehicle] call Waldo_fnc_CortexFireCountermeasure;
        if ((units _group) findIf {alive _x && {vehicle _x == _x}} < 0) then {
            private _threat=(_enemies select 0) select 0;
            private _away=[_vehicle,_enemyPos,_threat,300] call _selectVehicleEscape;
            if (_away isNotEqualTo [] && {[_group,"VEHICLE_WITHDRAW",true,serverTime+120] call Waldo_fnc_CortexLambsLease}) then {
                [_group, _away, 40] call Waldo_fnc_CortexGroupMove;
                _state set ["movementLease",["VEHICLE_WITHDRAW",time+120]];
                private _origin = getPosATL _vehicle;
                _state set ["retreatStart",_origin];
                _state set ["retreatTarget",_away];
                _state set ["retreatProgress",[time,0,0]];
                _group setVariable ["Waldo_Cortex_Withdrawal",["MOVING",0,0],true];
                _group setVariable ["Waldo_Cortex_WithdrawalIntent",["VEHICLE",_origin,_away,_enemyPos,serverTime,0,0],true];
                _movementOwned = true;
                [_group,_state,"RETREAT","VEHICLE_DISABLED",time] call Waldo_fnc_CortexSetPhase;
            };
        };
    };
    // Gunner priorities and standoff (Waldo_AIPass_VehicleGunnery_Enable): anti-tank infantry
    // first, then armour, then everything else; armour keeps its distance from known AT teams.
    if (_commandsVehicle && {alive _vehicle} && {[_group, "Waldo_AIPass_VehicleGunnery_Enable", true] call Waldo_fnc_CortexFeatureEnabled}) then {
        private _gunner = gunner _vehicle;
        private _ranked = [];
        {
            _x params ["_enemy", "_position", "_age"];
            private _distance = _vehicle distance2D _position;
            if (_age <= 15 && {_distance <= 600} && {alive _enemy}) then {
                private _priority = switch (true) do {
                    case (_enemy isKindOf "CAManBase" && {"AT" in ([_enemy] call Waldo_fnc_CortexCapabilities)}): {0};
                    case (_enemy isKindOf "Tank" || {_enemy isKindOf "Wheeled_APC_F"}): {1};
                    default {2};
                };
                _ranked pushBack [_priority, _distance, _forEachIndex];
            };
        } forEach _enemies;
        _ranked sort true;
        if (_ranked isNotEqualTo [] && {alive _gunner} && {local _gunner} && {!isPlayer _gunner}
            && {combatMode _group in ["YELLOW", "RED"]} && {unitCombatMode _gunner in ["YELLOW", "RED"]}
            && {(_gunner getVariable ["Waldo_AIPass_TargetHold", -1]) < time}) then {
            private _target = (_enemies select ((_ranked select 0) select 2)) select 0;
            if (assignedTarget _gunner != _target) then {
                _gunner doTarget _target;
            };
            // Target sharing may have assigned this contact before the vehicle layer runs. Fire refresh
            // therefore follows its own bounded hold instead of depending on a target identity change.
            _gunner doFire _target;
            _gunner setVariable ["Waldo_AIPass_TargetHold", time + 8];
            _gunner setVariable ["Waldo_AIPass_VehicleTarget", _target, true];
        };
        private _standoff = missionNamespace getVariable ["Waldo_AIPass_Vehicles_StandoffDistance", 250];
        private _atIndex = _enemies findIf {
            (_x select 0) isKindOf "CAManBase" && {(_x select 2) <= 30} && {(_vehicle distance2D (_x select 1)) < _standoff * 0.6}
            && {"AT" in ([_x select 0] call Waldo_fnc_CortexCapabilities)}
        };
        if (!_movementOwned && {_state getOrDefault ["phase",""] == "CONTACT"} && {_atIndex >= 0}
            && {_vehicle isKindOf "Tank" || {_vehicle isKindOf "Wheeled_APC_F"}} && {canMove _vehicle}
            && {(units _group) findIf {alive _x && {vehicle _x == _x}} < 0} && {!([_state, "standoff"] call Waldo_fnc_CortexCooldown)}) then {
            private _atPos = (_enemies select _atIndex) select 1;
            private _atThreat=(_enemies select _atIndex) select 0;
            private _away=[_vehicle,_atPos,_atThreat,(_standoff - (_vehicle distance2D _atPos)) max 60]
                call _selectVehicleEscape;
            if (_away isNotEqualTo [] && {[_group,"VEHICLE_STANDOFF",true,serverTime+60] call Waldo_fnc_CortexLambsLease}) then {
                [_group, _away, 30] call Waldo_fnc_CortexGroupMove;
                _state set ["movementLease",["VEHICLE_STANDOFF",time+60]];
                _movementOwned = true;
                [_state, "standoff", 60] call Waldo_fnc_CortexCooldown;
            };
        };
    };
} forEach _vehicles;
_movementOwned
