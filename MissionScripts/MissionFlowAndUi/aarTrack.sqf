/*
 * Author: WaldoTheWarfighter
 * Lightweight, event-driven after-action tracking for the ENDEX debrief.
 * Records mission start time and tallies, via the global EntityKilled mission event
 * handler (fires on every machine for every entity, so a single server-side
 * registration captures all kills regardless of unit locality): infantry KIA per side,
 * player losses, vehicles destroyed per side, friendly-fire kills, and a per-player
 * kill leaderboard. A vehicle's operational side is cached while it is alive, so ACE temporarily
 * changing an unconscious crew member to Civilian cannot misattribute the later vehicle loss.
 * Temporary unconscious/WIA events are deliberately not tracked because they
 * are not mission outcomes and duplicate the more useful KIA record. No per-frame loops.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_AARTrack;
 */

if !(isServer) exitWith {};
if (missionNamespace getVariable ["Waldo_AAR_Initialised", false]) exitWith {};
missionNamespace setVariable ["Waldo_AAR_Initialised", true];

// [west, east, independent, civilian] tallies, plus scalar/leaderboard extras.
missionNamespace setVariable ["Waldo_AAR_KIA", [0,0,0,0], true];      // infantry KIA per side
missionNamespace setVariable ["Waldo_AAR_VehKIA", [0,0,0,0], true];   // vehicles destroyed per side
missionNamespace setVariable ["Waldo_AAR_PlayerKIA", 0, true];        // human player deaths
missionNamespace setVariable ["Waldo_AAR_FF", 0, true];              // friendly-fire kills
missionNamespace setVariable ["Waldo_AAR_Frags", [], true];          // [[name, kills], ...] enemy kills by players
missionNamespace setVariable ["Waldo_AAR_StartTime", time, true];
diag_log format ["[WMP AAR] tracking initialized at missionTime=%1 serverTime=%2", time, serverTime];

private _cacheVehicleSide = {
    params ["_vehicle"];
    if (isNull _vehicle || {!(_vehicle isKindOf "AllVehicles")} || {_vehicle isKindOf "CAManBase"}) exitWith {};
    private _stableSide = _vehicle getVariable ["Waldo_AAR_OperationalSide", sideUnknown];
    private _crewSide = sideUnknown;
    private _crew = crew _vehicle select {alive _x};
    if !(_crew isEqualTo []) then {_crewSide = side group (_crew select 0)};
    if (_crewSide in [west, east, independent]) then {_stableSide = _crewSide};
    if !(_stableSide in [west, east, independent]) then {
        _stableSide = [east, west, independent, civilian] param [getNumber (configOf _vehicle >> "side"), sideUnknown];
    };
    if (_stableSide != sideUnknown) then {_vehicle setVariable ["Waldo_AAR_OperationalSide", _stableSide, true]};
};
missionNamespace setVariable ["Waldo_AAR_CacheVehicleSide", _cacheVehicleSide];
{
    [_x] call _cacheVehicleSide;
} forEach vehicles;
if !(isNil "CBA_fnc_addClassEventHandler") then {
    ["AllVehicles", "init", {
        params ["_vehicle"];
        if (_vehicle isKindOf "CAManBase") exitWith {};
        private _classSide = [east, west, independent, civilian] param [getNumber (configOf _vehicle >> "side"), sideUnknown];
        if (_classSide != sideUnknown) then {_vehicle setVariable ["Waldo_AAR_OperationalSide", _classSide, true]};
        _vehicle addEventHandler ["GetIn", {
            params ["_vehicle", "", "_unit"];
            private _operationalSide = side group _unit;
            if (_operationalSide in [west, east, independent]) then {
                _vehicle setVariable ["Waldo_AAR_OperationalSide", _operationalSide, true];
            };
        }];
    }, true, [], true] call CBA_fnc_addClassEventHandler;
};

addMissionEventHandler ["EntityKilled", {
    params ["_killed", "_killer", "_instigator"];
    if (isNull _killed) exitWith {};

    // The instigator is the actual shooter; fall back to the killer object when absent.
    if (isNull _instigator) then { _instigator = _killer };

    private _sides = [west, east, independent, civilian];

    if (_killed isKindOf "CAManBase") then {
        // Infantry KIA by the dead unit's side.
        private _idx = _sides find (side group _killed);
        if (_idx >= 0) then {
            private _kia = +(missionNamespace getVariable ["Waldo_AAR_KIA", [0,0,0,0]]);
            _kia set [_idx, (_kia select _idx) + 1];
            missionNamespace setVariable ["Waldo_AAR_KIA", _kia, true];
            diag_log format ["[WMP AAR] infantry KIA unit=%1 sideIndex=%2 instigator=%3 totals=%4", typeOf _killed, _idx, if (isNull _instigator) then {"NONE"} else {name _instigator}, _kia];
        };

        if (isPlayer _killed) then {
            missionNamespace setVariable ["Waldo_AAR_PlayerKIA",
                (missionNamespace getVariable ["Waldo_AAR_PlayerKIA", 0]) + 1, true];
        };

        // Killer attribution (needs a valid instigator that is not the victim itself).
        if (!isNull _instigator && {_instigator != _killed} && {_idx >= 0}) then {
            private _killerIdx = _sides find (side group _instigator);
            if (_killerIdx >= 0) then {
                if (_killerIdx == _idx) then {
                    // Same side -> friendly fire.
                    missionNamespace setVariable ["Waldo_AAR_FF",
                        (missionNamespace getVariable ["Waldo_AAR_FF", 0]) + 1, true];
                } else {
                    // Enemy kill by a human player -> leaderboard.
                    if (isPlayer _instigator) then {
                        private _name = name _instigator;
                        private _frags = +(missionNamespace getVariable ["Waldo_AAR_Frags", []]);
                        private _at = _frags findIf {(_x select 0) isEqualTo _name};
                        if (_at < 0) then {
                            _frags pushBack [_name, 1];
                        } else {
                            (_frags select _at) set [1, ((_frags select _at) select 1) + 1];
                        };
                        missionNamespace setVariable ["Waldo_AAR_Frags", _frags, true];
                    };
                };
            };
        };
    } else {
        if (_killed isKindOf "AllVehicles") then {
            // Use the last stable operational side; side _killed can become CIV when ACE makes the
            // dying crew unconscious before this event is handled.
            private _lossSide = _killed getVariable ["Waldo_AAR_OperationalSide", sideUnknown];
            if (_lossSide == sideUnknown) then {
                _lossSide = [east, west, independent, civilian] param [getNumber (configOf _killed >> "side"), civilian];
            };
            private _vIdx = _sides find _lossSide;
            if (_vIdx >= 0) then {
                private _veh = +(missionNamespace getVariable ["Waldo_AAR_VehKIA", [0,0,0,0]]);
                _veh set [_vIdx, (_veh select _vIdx) + 1];
                missionNamespace setVariable ["Waldo_AAR_VehKIA", _veh, true];
                diag_log format ["[WMP AAR] vehicle loss class=%1 stableSide=%2 sideIndex=%3 totals=%4", typeOf _killed, _lossSide, _vIdx, _veh];
            };
        };
    };
}];
