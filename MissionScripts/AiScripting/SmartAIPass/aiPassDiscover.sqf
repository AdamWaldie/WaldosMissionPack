/*
 * Author: WaldoTheWarfighter
 * Machine-local discovery sweep for the Smart AI Pass, run as a scheduler job every
 * Waldo_AIPass_DiscoveryInterval seconds (default 10) on the server and each headless client.
 *
 * One sweep replaces the per-unit init and locality handlers the audited mods relied on:
 * - caches player positions for the distance tiers (one allPlayers read per sweep, not per group);
 * - starts a Waldo_fnc_AIPassGroupTick job for each newly local, eligible group and records its
 *   peak strength, which is how groups handed over by ACE Headless or WMP Headless are picked up;
 * - re-applies garrison orders on the new owner after a locality change, because disableAI and
 *   event handlers are stored per machine;
 * - optionally applies WMP garrison handling to Dynamic AO garrison groups;
 * - in LAMBS "WMP" mode, turns LAMBS group AI off for managed groups (restored on release);
 * - caches locally owned, eligible artillery for fire support and counter-battery;
 * - re-applies defence-line orders after a locality change;
 * - installs the missile-warning handler (flares, and the optional break-away jink) on locally owned
 *   WMP gunships and Dynamic AA fighters.
 * Locality and authority: machine-local; nothing is broadcast except the documented LAMBS and
 * garrison group variables.
 *
 * Arguments:
 * 0: job <HASHMAP> - unused
 *
 * Return Value:
 * Number - seconds until the next sweep, or -1 when the pass has stopped
 *
 * Example:
 * [Waldo_fnc_AIPassDiscover, createHashMap, 1] call Waldo_fnc_AIPassQueueJob;
 * Result: local AI groups are brought under the pass within one sweep.
 *
 * Current caller: Waldo_fnc_AIPassInit.
 */

if !(missionNamespace getVariable ["Waldo_AIPass_Active", false]) exitWith {
    missionNamespace setVariable ["Waldo_AIPass_DiscoveryQueued", false];
    -1
};
missionNamespace setVariable ["Waldo_AIPass_PlayerPositions", (allPlayers select {alive _x && {!(_x isKindOf "HeadlessClient_F")}}) apply {getPosATL _x}];

private _lambsWmpMode = (missionNamespace getVariable ["Waldo_AIPass_LambsDangerLoaded", false])
    && {toUpperANSI (missionNamespace getVariable ["Waldo_AIPass_LambsMode", "SPLIT"]) == "WMP"};
private _daoGarrison = missionNamespace getVariable ["Waldo_AIPass_Garrison_DynamicAO", false];
{
    private _group = _x;
    if (local _group && {(units _group) findIf {alive _x} >= 0}) then {
        if ((_group getVariable ["Waldo_AIPass_Garrison", []]) isNotEqualTo [] && {!(_group getVariable ["Waldo_AIPass_GarrisonApplied", false])}) then {
            [_group] call Waldo_fnc_AIPassGarrisonApplyLocal;
        };
        if ((_group getVariable ["Waldo_AIPass_Defend", []]) isNotEqualTo [] && {!(_group getVariable ["Waldo_AIPass_DefendApplied", false])}) then {
            [_group] call Waldo_fnc_AIPassDefendApplyLocal;
        };
        if (!(_group getVariable ["Waldo_AIPass_Managed", false]) && {[_group] call Waldo_fnc_AIPassIsEligible}) then {
            _group setVariable ["Waldo_AIPass_Managed", true];
            _group setVariable ["Waldo_AIPass_PeakSize", (_group getVariable ["Waldo_AIPass_PeakSize", 0]) max ({alive _x} count units _group)];
            [Waldo_fnc_AIPassGroupTick, createHashMapFromArray [["group", _group]], random 2] call Waldo_fnc_AIPassQueueJob;
            if (_daoGarrison && {(_group getVariable ["Waldo_DynamicAO_Role", ""]) == "GARRISON"}
                && {(_group getVariable ["Waldo_AIPass_Garrison", []]) isEqualTo []}) then {
                private _building = _group getVariable ["Waldo_DynamicAO_Building", objNull];
                private _centre = if (isNull _building) then {getPosATL leader _group} else {getPosATL _building};
                [_group, _centre, 25, createHashMapFromArray [["inPlace", true], ["useLambs", false]]] call Waldo_fnc_AIPassGarrison;
            };
            if (_lambsWmpMode && {!(_group getVariable ["lambs_danger_disableGroupAI", false])}) then {
                _group setVariable ["lambs_danger_disableGroupAI", true, true];
                _group setVariable ["Waldo_AIPass_LambsDisabledByPass", true];
            };
        };
    };
} forEach allGroups;

private _wantArtillery = (missionNamespace getVariable ["Waldo_AIPass_Artillery_Enable", false])
    || {missionNamespace getVariable ["Waldo_AIPass_CounterBattery_Enable", false]};
private _wantFlares = (missionNamespace getVariable ["Waldo_AIPass_AircraftFlares_Enable", false])
    || {missionNamespace getVariable ["Waldo_AIPass_AircraftBreak_Enable", false]};
if (_wantArtillery || _wantFlares) then {
    private _artillery = [];
    {
        private _vehicle = _x;
        if (local _vehicle && {alive _vehicle}) then {
            if (_wantArtillery && {getNumber (configOf _vehicle >> "artilleryScanner") == 1}) then {
                private _gunner = gunner _vehicle;
                if (alive _gunner && {!isPlayer _gunner} && {[group _gunner] call Waldo_fnc_AIPassIsEligible}) then {_artillery pushBack _vehicle};
            };
            if (_wantFlares && {_vehicle isKindOf "Air"} && {!(_vehicle getVariable ["Waldo_AIPass_FlaresInstalled", false])}
                && {!isNil {_vehicle getVariable "Waldo_Gunship_Id"} || {!isNil {_vehicle getVariable "Waldo_DynamicAA_SystemId"}}}) then {
                _vehicle setVariable ["Waldo_AIPass_FlaresInstalled", true];
                _vehicle addEventHandler ["IncomingMissile", {
                    params ["_vehicle", "", "_shooter"];
                    if (!local _vehicle || {isPlayer driver _vehicle} || {!(missionNamespace getVariable ["Waldo_AIPass_Active", false])}) exitWith {};
                    if (time < (_vehicle getVariable ["Waldo_AIPass_NextFlare", 0])) exitWith {};
                    _vehicle setVariable ["Waldo_AIPass_NextFlare", time + 3];
                    if (missionNamespace getVariable ["Waldo_AIPass_AircraftFlares_Enable", false]) then {
                        for "_burst" from 0 to 2 do {
                            [{[_this] call Waldo_fnc_AIPassFireCountermeasure}, _vehicle, _burst * 0.4] call CBA_fnc_waitAndExecute;
                        };
                    };
                    // Smart Aircraft's break: one sideways jink away from the shooter, without touching
                    // the aircraft's waypoints or orbit (Waldo_AIPass_AircraftBreak_Enable, off by default).
                    if ((missionNamespace getVariable ["Waldo_AIPass_AircraftBreak_Enable", false]) && {!isNull _shooter}) then {
                        private _velocity = velocityModelSpace _vehicle;
                        private _side = [18, -18] select ((_vehicle getRelDir _shooter) < 180);
                        _vehicle setVelocityModelSpace [(_velocity select 0) + _side, _velocity select 1, (_velocity select 2) - 4];
                    };
                }];
            };
        };
    } forEach vehicles;
    missionNamespace setVariable ["Waldo_AIPass_LocalArtillery", _artillery];
};
missionNamespace getVariable ["Waldo_AIPass_DiscoveryInterval", 10]
