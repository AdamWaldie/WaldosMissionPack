/*
 * Author: Waldo
 * Shared jamming-strength calculator. Given a world position, a side and (optionally) a
 * radio frequency, returns how strongly the active jammer registry jams that point, from
 * 0 (no jamming) to 1 (total blackout). Used by both radio engines (ACRE2 signal function
 * and the TFAR loop) and by the on-screen "jamming detected" watcher, so every part of the
 * system agrees on where a jammer reaches. Runs anywhere - it only reads the broadcast
 * registry; it never changes state. Kept lean because the ACRE2 signal path calls it often.
 *
 * Arguments:
 * 0: Position <ARRAY> - ASL position to test (e.g. a radio position or getPosASL player)
 * 1: Side <SIDE> - the side of the receiver being tested (for the affected-sides filter)
 * 2: Frequency <NUMBER> - frequency in MHz to test against jammer bands, or -1 to ignore
 *                         band filtering (broadband, used by TFAR) (optional, default: -1)
 *
 * Return Value:
 * Number <NUMBER> - strongest jamming factor at this point, 0..1
 *
 * Example:
 * private _jam = [getPosASL player, side player, -1] call Waldo_fnc_JammingFactor;
 */

params ["_pos", "_side", ["_freq", -1]];

private _registry = missionNamespace getVariable ["Waldo_Jamming_Registry", []];
if (_registry isEqualTo []) exitWith { 0 };
if !(_pos isEqualType []) exitWith { 0 };
if (count _pos < 3) exitWith { 0 };

private _max = 0;

{
    _x params ["_id", "_obj", "_radius", "_falloff", "_sides", "_bands", "_strength", "_active"];

    if (_active && {!isNull _obj}) then {
        // Affected-sides filter: "ALL" (string) hits everyone, else the receiver's side must be listed.
        private _sideOk = (_sides isEqualType "") || {_side in _sides};

        // Frequency-band filter (ACRE2 only): a frequency of -1 means broadband (ignore bands).
        private _bandOk = true;
        if (_sideOk && {_freq >= 0} && {!(_bands isEqualType "")}) then {
            _bandOk = false;
            {
                if (_freq >= (_x select 0) && {_freq <= (_x select 1)}) exitWith { _bandOk = true; };
            } forEach _bands;
        };

        if (_sideOk && _bandOk) then {
            private _d = _pos distance (getPosASL _obj);
            private _f = 0;
            if (_d <= _radius) then {
                _f = 1;
            } else {
                if (_falloff > 0 && {_d <= (_radius + _falloff)}) then {
                    _f = (_radius + _falloff - _d) / _falloff;
                };
            };
            _f = _f * _strength;
            if (_f > _max) then { _max = _f; };
        };
    };
} forEach _registry;

_max min 1
