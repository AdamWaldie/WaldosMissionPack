/*
 * Author: Waldo
 * Is research exclusive blocked.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * 0: _sideKey <ANY> - side key
 * 1: _entry <ANY> - entry
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_sideKey, _entry] call Waldo_fnc_EcoResearch_isResearchExclusiveBlocked;
 */

        params ["_sideKey", "_entry"];

        private _blocked = false;
        {
            if ([_sideKey, _x] call Waldo_fnc_EcoResearch_isResearchCompletedForSide) exitWith {
                _blocked = true;
            };
        } forEach (_entry param [8, []]);

        _blocked

