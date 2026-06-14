/*
 * Author: Waldo
 * Lightweight, event-driven after-action tracking for the ENDEX debrief.
 * Records mission start time and tallies, via the global EntityKilled mission event
 * handler (fires on every machine for every entity, so a single server-side
 * registration captures all kills regardless of unit locality): infantry KIA per side,
 * player losses, vehicles destroyed per side, friendly-fire kills, and a per-player
 * kill leaderboard. Wounded (WIA) are tallied separately via Waldo_fnc_AARWound, fed
 * by the ACE unconscious listener registered in init.sqf. No per-frame loops.
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
missionNamespace setVariable ["Waldo_AAR_WIA", [0,0,0,0], true];      // unique wounded per side (ACE, see Waldo_fnc_AARWound)
missionNamespace setVariable ["Waldo_AAR_PlayerKIA", 0, true];        // human player deaths
missionNamespace setVariable ["Waldo_AAR_FF", 0, true];              // friendly-fire kills
missionNamespace setVariable ["Waldo_AAR_Frags", [], true];          // [[name, kills], ...] enemy kills by players
missionNamespace setVariable ["Waldo_AAR_StartTime", time, true];

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
            // Vehicle destroyed -> tally by the vehicle's side (skips empty/civilian wrecks).
            private _vIdx = _sides find (side _killed);
            if (_vIdx >= 0) then {
                private _veh = +(missionNamespace getVariable ["Waldo_AAR_VehKIA", [0,0,0,0]]);
                _veh set [_vIdx, (_veh select _vIdx) + 1];
                missionNamespace setVariable ["Waldo_AAR_VehKIA", _veh, true];
            };
        };
    };
}];
