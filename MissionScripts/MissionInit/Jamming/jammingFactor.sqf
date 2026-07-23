/*
 * Author: Waldo
 * Shared jamming-strength calculator - the heart of the jamming model. Given a world position, a
 * side and (optionally) a radio frequency and radio power, it returns how strongly the active
 * jammer registry jams that point, from 0 (clear) to 1 (total blackout). Every part of the system
 * (the ACRE2 signal function, the TFAR loop, the on-screen meter, the RDF detector and the GM
 * overlay) routes through this so they all agree on where each jammer reaches.
 *
 * It applies the full model per jammer: active + duty-cycle window, affected-sides filter,
 * frequency-band filter (ACRE2), a directional cone (bearing + arc), terrain line-of-sight
 * occlusion, radio-power burn-through (stronger radios shrink the effective field) and a
 * linear or inverse-square falloff. Reads only broadcast state; never changes anything. Kept as
 * lean as the feature set allows because the ACRE2 path calls it often.
 *
 * Model toggles (missionNamespace, set in init.sqf):
 *   Waldo_Jamming_LOS            - true = terrain blocks jamming (default true)
 *   Waldo_Jamming_BurnThrough    - true = radio power resists jamming (default true)
 *   Waldo_Jamming_BurnThroughRef - reference radio power in mW (default 500)
 *   Waldo_Jamming_Curve          - "LINEAR" or "INVSQ" falloff (default "LINEAR")
 *
 * Arguments:
 * 0: Position <ARRAY> - ASL position to test (a radio position or getPosASL player)
 * 1: Side <SIDE> - the side of the receiver being tested (for the affected-sides filter)
 * 2: Frequency <NUMBER> - MHz to test against jammer bands, or -1 to ignore bands (optional, default: -1)
 * 3: Radio power <NUMBER> - transmit power in mW for burn-through, or -1 to skip it (optional, default: -1)
 *
 * Return Value:
 * Number <NUMBER> - strongest jamming factor at this point, 0..1
 *
 * Example:
 * private _jam = [getPosASL player, side player, 45, 5000] call Waldo_fnc_JammingFactor;
 */

params ["_pos", "_side", ["_freq", -1], ["_power", -1]];

private _registry = missionNamespace getVariable ["Waldo_Jamming_Registry", []];
if (_registry isEqualTo []) exitWith { 0 };
if !(_pos isEqualType []) exitWith { 0 };
if (count _pos < 3) exitWith { 0 };

private _useLos = missionNamespace getVariable ["Waldo_Jamming_LOS", true];
private _useBurn = missionNamespace getVariable ["Waldo_Jamming_BurnThrough", true];
private _burnRef = missionNamespace getVariable ["Waldo_Jamming_BurnThroughRef", 500];
private _curve = missionNamespace getVariable ["Waldo_Jamming_Curve", "LINEAR"];
private _now = serverTime;

private _max = 0;

{
    _x params ["_id", "_obj", "_radius", "_falloff", "_sides", "_bands", "_strength", "_active", "_mk", ["_sector", []], ["_duty", []]];

    private _skip = !(_active) || {isNull _obj};

    // Duty cycle: only jam during the "on" slice of the on/off period.
    if (!_skip && {_duty isEqualType []} && {count _duty == 2}) then {
        private _onT = _duty select 0;
        private _offT = _duty select 1;
        private _period = _onT + _offT;
        if (_period > 0) then {
            if ((_now % _period) >= _onT) then { _skip = true; };
        };
    };

    // Affected-sides filter: "ALL" (string) hits everyone, else the receiver's side must be listed.
    if (!_skip) then {
        if !((_sides isEqualType "") || {_side in _sides}) then { _skip = true; };
    };

    // Frequency-band filter (ACRE2 only): -1 frequency means broadband (ignore bands).
    if (!_skip && {_freq >= 0} && {!(_bands isEqualType "")}) then {
        private _bandOk = false;
        {
            if (_freq >= (_x select 0) && {_freq <= (_x select 1)}) exitWith { _bandOk = true; };
        } forEach _bands;
        if (!_bandOk) then { _skip = true; };
    };

    if (!_skip) then {
        private _jPos = getPosASL _obj;

        // Directional cone: skip if the target lies outside the jammer's arc.
        if (_sector isEqualType [] && {count _sector == 2} && {(_sector select 1) < 360}) then {
            private _bearing = _sector select 0;
            private _arc = _sector select 1;
            private _to = _obj getDir _pos;
            private _diff = abs (((_to - _bearing) + 540) % 360 - 180);
            if (_diff > (_arc / 2)) then { _skip = true; };
        };

        if (!_skip) then {
            // Terrain line-of-sight: a hill or ridge between jammer and radio blocks the field.
            private _blocked = false;
            if (_useLos) then {
                _blocked = terrainIntersectASL [[_jPos select 0, _jPos select 1, (_jPos select 2) + 2], _pos];
            };

            if (!_blocked) then {
                // Burn-through: a higher-power link shrinks the jammer's effective reach.
                private _effR = _radius;
                private _effF = _falloff;
                if (_useBurn && {_power > 0} && {_burnRef > 0}) then {
                    private _ratio = _power / _burnRef;
                    if (_ratio > 1) then {
                        private _scale = 1 / (_ratio ^ 0.35);
                        _effR = _radius * _scale;
                        _effF = _falloff * _scale;
                    };
                };

                private _d = _pos distance _jPos;
                private _f = 0;
                if (_d <= _effR) then {
                    _f = 1;
                } else {
                    if (_effF > 0 && {_d <= (_effR + _effF)}) then {
                        private _t = (_effR + _effF - _d) / _effF;
                        if (_curve == "INVSQ") then { _f = _t * _t; } else { _f = _t; };
                    };
                };

                _f = _f * _strength;
                if (_f > _max) then { _max = _f; };
            };
        };
    };
} forEach _registry;

_max min 1
