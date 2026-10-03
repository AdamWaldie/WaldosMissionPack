/*
 * Author: WaldoTheWarfighter
 * Machine-local discovery sweep for Cortex, run as a scheduler job every
 * Waldo_AIPass_DiscoveryInterval seconds (default 10) on the server and each headless client.
 *
 * One sweep caches candidates and installs repeat-safe ground-group ownership handlers:
 * - caches player positions for the distance tiers (one allPlayers read per sweep, not per group);
 * - starts a Waldo_fnc_CortexGroupTick job for each newly local, eligible non-aircraft group and records its
 *   peak strength, which is how groups handed over by ACE Headless or WMP Headless are picked up;
 * - re-applies garrison orders on the new owner after a locality change, because disableAI and
 *   event handlers are stored per machine;
 * - optionally applies WMP garrison handling to Dynamic AO garrison groups;
 * - reconciles blanket WMP-mode and finite SPLIT-mode LAMBS movement ownership;
 * - caches locally owned, eligible artillery for fire support and counter-battery;
 * - re-applies defence-line orders after a locality change;
 * - hands landed paratroopers and dismounted crews of a lost transport to the pass
 *   (Waldo_fnc_CortexReleaseFeatureCrew);
 * - installs the missile-warning handler (flares, and the optional break-away jink) on every locally
 *   owned, eligible AI aircraft; no unrelated WMP aircraft-system marker is required.
 * - reserves aircraft crews from the generic group domain, then queues proactive attack-run flare
 *   sampling and the finite adaptive attack controller only for a
 *   currently eligible, crewed AI aircraft;
 *   empty, player, UAV and excluded aircraft are reconsidered on later sweeps without job churn.
 * Locality and authority: discovery is machine-local; orders, restoration checkpoints and LAMBS markers are public.
 *
 * Review contract: Live LAMBS mode changes apply to already managed groups. The restoration marker is public so a new owner can return LAMBS control; aircraft event IDs are tracked for stop cleanup.
 *
 * Repeat/JIP: current feature gates and eligibility are rechecked; owner jobs are retired on migration.
 * Missile-warning bursts carry an owner-local generation token, so handler replacement, locality
 * migration or a stop/restart cannot revive countermeasures queued by an earlier Cortex run.
 * Arguments:
 * 0: job <HASHMAP> - unused
 *
 * Return Value:
 * Number - seconds until the next sweep, or -1 when the pass has stopped
 *
 * Example:
 * [Waldo_fnc_CortexDiscover, createHashMap, 1] call Waldo_fnc_CortexQueueJob;
 * Result: local AI groups are brought under the pass within one sweep.
 *
 * Current caller: Waldo_fnc_CortexInit.
 */

if !(missionNamespace getVariable ["Waldo_AIPass_Active", false]) exitWith {
    missionNamespace setVariable ["Waldo_AIPass_DiscoveryQueued", false];
    -1
};
missionNamespace setVariable ["Waldo_AIPass_PlayerPositions", (allPlayers select {alive _x && {!(_x isKindOf "HeadlessClient_F")}}) apply {getPosATL _x}];

private _lambsWmpMode = (missionNamespace getVariable ["Waldo_AIPass_LambsDangerLoaded", false])
    && {toUpperANSI (missionNamespace getVariable ["Waldo_AIPass_LambsMode", "SPLIT"]) == "WMP"};
private _spotters = [];
private _daoGarrison = missionNamespace getVariable ["Waldo_AIPass_Garrison_DynamicAO", false];
{
    private _group = _x;
    // Aircraft occupants remain eligible for the dedicated air systems below, but the generic
    // infantry/ground-vehicle domain must not install hearing, locality adoption or a group tick.
    // If a previously managed ground group boards an aircraft, release that old owner immediately.
    private _groundEligible = [_group,false,true] call Waldo_fnc_CortexIsEligible;
    if (_groundEligible) then {
        [_group] call Waldo_fnc_CortexHearingLocal;
        if (isNil {_group getVariable "Waldo_AIPass_LocalHandler"}) then {
            _group setVariable ["Waldo_AIPass_LocalHandler", _group addEventHandler ["Local", {
                _this call Waldo_fnc_CortexLocality;
            }]];
        };
        if (local _group && {!(_group getVariable ["Waldo_AIPass_Adopted", false])}) then {
            [_group, true] call Waldo_fnc_CortexLocality;
        };
    } else {
        [_group,true] call Waldo_fnc_CortexHearingLocal;
        if (local _group && {_group getVariable ["Waldo_AIPass_Managed",false]}) then {
            [_group,true,"AIRCRAFT_DEDICATED"] call Waldo_fnc_CortexReleaseGroup;
        };
    };
    // "Applied" flags are machine-local. Clear them while another machine owns the group, so a group
    // that comes back (for example server to headless client and back) has its order re-applied here.
    if (!local _group) then {
        _group setVariable ["Waldo_AIPass_GarrisonApplied", nil];
        _group setVariable ["Waldo_AIPass_DefendApplied", nil];
    };
    if (local _group && {(units _group) findIf {alive _x} >= 0}) then {
        _spotters append ((units _group) select {alive _x && {_x getVariable ["Waldo_AIPass_Spotter", false]}});
        if ((_group getVariable ["Waldo_AIPass_Garrison", []]) isNotEqualTo [] && {!(_group getVariable ["Waldo_AIPass_GarrisonApplied", false])}) then {
            [_group] call Waldo_fnc_CortexGarrisonApplyLocal;
        };
        if ((_group getVariable ["Waldo_AIPass_Defend", []]) isNotEqualTo [] && {!(_group getVariable ["Waldo_AIPass_DefendApplied", false])}) then {
            [_group] call Waldo_fnc_CortexDefendApplyLocal;
        };
        private _clear = _group getVariable ["Waldo_AIPass_ClearOrder", []];
        if (_clear isNotEqualTo [] && {!(_group getVariable ["Waldo_AIPass_ClearApplied", false])}) then {
            [_group, _clear select 0, createHashMapFromArray [["useLambs", false], ["resume", true]]] call Waldo_fnc_CortexClearBuilding;
        };
        // Landed paratroopers and dismounted crews of a lost transport are released by their feature.
        if (_group getVariable ["Waldo_Paradrop_Jumped", false]
            || {!isNil {_group getVariable "Waldo_TransportService_Vehicle"}}) then {
            [_group] call Waldo_fnc_CortexReleaseFeatureCrew;
        };
        // Aircraft occupants have dedicated flight, flare, missile-reaction and airborne controllers.
        // They may remain generally Cortex-eligible for those systems, but must never acquire the
        // generic ground-group loop as a second movement/behaviour owner.
        private _eligible = _groundEligible;
        if ((!_lambsWmpMode || {!_eligible}) && {_group getVariable ["Waldo_AIPass_LambsDisabledByPass", false]}) then {
            _group setVariable ["lambs_danger_disableGroupAI", _group getVariable ["Waldo_AIPass_LambsBaseline", false], true];
            _group setVariable ["Waldo_AIPass_LambsDisabledByPass", nil, true];
            _group setVariable ["Waldo_AIPass_LambsBaseline", nil, true];
        };
        if (_lambsWmpMode && {_eligible} && {!(_group getVariable ["Waldo_AIPass_LambsDisabledByPass", false])}) then {
            private _scopedLease = _group getVariable ["Waldo_Cortex_LambsLease", []];
            private _baseline = if (count _scopedLease == 3) then {_scopedLease select 1} else {
                _group getVariable ["lambs_danger_disableGroupAI", false]
            };
            _group setVariable ["Waldo_AIPass_LambsBaseline", _baseline, true];
            _group setVariable ["lambs_danger_disableGroupAI", true, true];
            _group setVariable ["Waldo_AIPass_LambsDisabledByPass", true, true];
        };
        private _lambsLease = _group getVariable ["Waldo_Cortex_LambsLease", []];
        if (_lambsLease isNotEqualTo []) then {
            if (serverTime >= (_lambsLease select 2)) then {
                [_group,"",false] call Waldo_fnc_CortexLambsLease;
            } else {
                // A live mode change may have just removed the blanket switch. Renewing the same
                // scoped owner reasserts exclusive movement without changing its saved baseline.
                [_group,_lambsLease select 0,true,_lambsLease select 2] call Waldo_fnc_CortexLambsLease;
            };
        };
        if (!(_group getVariable ["Waldo_AIPass_Managed", false]) && {_eligible}) then {
            _group setVariable ["Waldo_AIPass_Managed", true];
            _group setVariable ["Waldo_AIPass_PeakSize", (_group getVariable ["Waldo_AIPass_PeakSize", 0]) max ({alive _x} count units _group)];
            [Waldo_fnc_CortexGroupTick, createHashMapFromArray [["group", _group]], random 2] call Waldo_fnc_CortexQueueJob;
            if (_daoGarrison && {(_group getVariable ["Waldo_DynamicAO_Role", ""]) == "GARRISON"}
                && {(_group getVariable ["Waldo_AIPass_Garrison", []]) isEqualTo []}) then {
                private _building = _group getVariable ["Waldo_DynamicAO_Building", objNull];
                private _centre = if (isNull _building) then {getPosATL leader _group} else {getPosATL _building};
                [_group, _centre, 25, createHashMapFromArray [["inPlace", true], ["useLambs", false]]] call Waldo_fnc_CortexGarrison;
            };

        };
    };
} forEach allGroups;
missionNamespace setVariable ["Waldo_AIPass_LocalSpotters", _spotters];

private _wantArtillery = (missionNamespace getVariable ["Waldo_AIPass_Artillery_Enable", false])
    || {missionNamespace getVariable ["Waldo_AIPass_CounterBattery_Enable", false]};
private _wantFlares = (missionNamespace getVariable ["Waldo_AIPass_AircraftFlares_Enable", false])
    || {missionNamespace getVariable ["Waldo_AIPass_AircraftBreak_Enable", false]};
private _wantAttackFlares=missionNamespace getVariable ["Waldo_Cortex_AttackRunFlares_Enable",true];
private _wantAirAttack=missionNamespace getVariable ["Waldo_Cortex_AirAttack_Enable",true];
if (_wantArtillery || _wantFlares || _wantAttackFlares || _wantAirAttack) then {
    private _artillery = [];
    private _allArtillery = [];
    {
        private _vehicle = _x;
        if (isServer && {alive _vehicle} && {getNumber (configOf _vehicle >> "artilleryScanner") == 1}) then {_allArtillery pushBack _vehicle};
        if (local _vehicle && {alive _vehicle}) then {
            private _pilot = driver _vehicle;
            private _attackFlareEligible = _wantAttackFlares && {_vehicle isKindOf "Air"}
                && {!isNull _pilot} && {alive _pilot} && {!isPlayer _pilot} && {!unitIsUAV _vehicle}
                && {[group _pilot,"Waldo_Cortex_AttackRunFlares_Enable",true] call Waldo_fnc_CortexFeatureEnabled}
                && {[group _pilot] call Waldo_fnc_CortexIsEligible || {[_vehicle] call Waldo_fnc_CortexAircraftEligible}};
            if (_attackFlareEligible && {!(_vehicle getVariable ["Waldo_Cortex_AttackFlareJob",false])}) then {
                _vehicle setVariable ["Waldo_Cortex_AttackFlareJob",true];
                [Waldo_fnc_CortexAttackRunFlares,createHashMapFromArray [["aircraft",_vehicle]],1] call Waldo_fnc_CortexQueueJob;
            };
            private _airAttackEligible=_wantAirAttack && {_vehicle isKindOf "Air"}
                && {!isNull _pilot} && {alive _pilot} && {!isPlayer _pilot} && {!unitIsUAV _vehicle}
                && {!isTouchingGround _vehicle} && {!(_vehicle isKindOf "Plane") || {speed _vehicle >= 40}}
                && {combatMode group _pilot in ["YELLOW","RED"]}
                && {[group _pilot,"Waldo_Cortex_AirAttack_Enable",true] call Waldo_fnc_CortexFeatureEnabled}
                && {[group _pilot] call Waldo_fnc_CortexIsEligible};
            private _hasHostileTarget=false;
            if (_airAttackEligible) then {
                {
                    private _candidate=assignedTarget _x;
                    if (!isNull _candidate && {alive _candidate} && {(side group _pilot) getFriend side _candidate < 0.6}) exitWith {_hasHostileTarget=true};
                } forEach ([effectiveCommander _vehicle,driver _vehicle,gunner _vehicle,commander _vehicle]+crew _vehicle);
            };
            if (_airAttackEligible && {_hasHostileTarget} && {!(_vehicle getVariable ["Waldo_Cortex_AirAttackJob",false])}) then {
                _vehicle setVariable ["Waldo_Cortex_AirAttackJob",true];
                [Waldo_fnc_CortexAirAttack,createHashMapFromArray [["aircraft",_vehicle],["group",group _pilot]],0] call Waldo_fnc_CortexQueueJob;
            };
            if (_wantArtillery && {getNumber (configOf _vehicle >> "artilleryScanner") == 1}) then {
                private _gunner = gunner _vehicle;
                if (alive _gunner && {!isPlayer _gunner} && {[group _gunner] call Waldo_fnc_CortexIsEligible}) then {_artillery pushBack _vehicle};
            };
            if (_wantFlares && {_vehicle isKindOf "Air"} && {!(_vehicle getVariable ["Waldo_AIPass_FlaresInstalled", false])}
                && {[_vehicle] call Waldo_fnc_CortexAircraftEligible}) then {
                _vehicle setVariable ["Waldo_AIPass_FlaresInstalled", true];
                // The value is intentionally owner-local. A newly installed owner handler advances it,
                // permanently invalidating callbacks left by an earlier handler on this machine.
                _vehicle setVariable ["Waldo_Cortex_FlareBurstGeneration",
                    (_vehicle getVariable ["Waldo_Cortex_FlareBurstGeneration",0])+1];
                private _handler = _vehicle addEventHandler ["IncomingMissile", {
                    params ["_vehicle", "", "_shooter"];
                    if !([_vehicle] call Waldo_fnc_CortexAircraftEligible) exitWith {};
                    if (time < (_vehicle getVariable ["Waldo_AIPass_NextFlare", 0])) exitWith {};
                    _vehicle setVariable ["Waldo_AIPass_NextFlare", time + 3];
                    if ([group driver _vehicle,"Waldo_AIPass_AircraftFlares_Enable",false] call Waldo_fnc_CortexFeatureEnabled) then {
                        private _generation=(_vehicle getVariable ["Waldo_Cortex_FlareBurstGeneration",0])+1;
                        _vehicle setVariable ["Waldo_Cortex_FlareBurstGeneration",_generation];
                        for "_burst" from 0 to 2 do {
                            [{
                                params ["_vehicle","_generation"];
                                if ((_vehicle getVariable ["Waldo_Cortex_FlareBurstGeneration",-1]) == _generation
                                    && {[_vehicle] call Waldo_fnc_CortexAircraftEligible}
                                    && {[group driver _vehicle,"Waldo_AIPass_AircraftFlares_Enable",false] call Waldo_fnc_CortexFeatureEnabled}
                                    ) then {
                                    [_vehicle] call Waldo_fnc_CortexFireCountermeasure;
                                };
                            }, [_vehicle,_generation], _burst * 0.4] call CBA_fnc_waitAndExecute;
                        };
                    };
                    // Break-away: one sideways jink away from the shooter, without touching
                    // the aircraft's waypoints or orbit (Waldo_AIPass_AircraftBreak_Enable, off by default).
                    if (([group driver _vehicle,"Waldo_AIPass_AircraftBreak_Enable",false] call Waldo_fnc_CortexFeatureEnabled) && {!isNull _shooter}) then {
                        private _velocity = velocityModelSpace _vehicle;
                        private _side = [18, -18] select ((_vehicle getRelDir _shooter) < 180);
                        private _candidate=[((_velocity select 0)+_side) max -18 min 18,_velocity select 1,(_velocity select 2)-4];
                        // Reject the jink if either the current or projected flight envelope is too low.
                        // World-space clearance also accounts for a banked aircraft and rising terrain.
                        private _safe=true;
                        {
                            private _position=_vehicle modelToWorldWorld (_candidate vectorMultiply _x);
                            if ((_position select 2)-(getTerrainHeightASL _position) < 30) then {_safe=false};
                        } forEach [0,1,2];
                        if (_safe && {abs (_velocity select 0) <= 18}) then {_vehicle setVelocityModelSpace _candidate};
                    };
                }];
                _vehicle setVariable ["Waldo_AIPass_FlaresHandler", _handler];
                private _tracked = missionNamespace getVariable ["Waldo_AIPass_FlareVehicles", []];
                _tracked pushBackUnique _vehicle;
                missionNamespace setVariable ["Waldo_AIPass_FlareVehicles", _tracked];
            };
        };
    } forEach vehicles;
    missionNamespace setVariable ["Waldo_AIPass_LocalArtillery", _artillery];
    if (isServer) then {missionNamespace setVariable ["Waldo_AIPass_AllArtillery", _allArtillery]};
};
missionNamespace getVariable ["Waldo_AIPass_DiscoveryInterval", 10]
