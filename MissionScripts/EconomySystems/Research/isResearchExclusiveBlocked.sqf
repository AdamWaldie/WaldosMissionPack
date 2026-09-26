/*
 * Author: WaldoTheWarfighter
 * Checks whether a completed conflicting technology blocks one Research entry.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * 0: _sideKey <ANY> - side key
 * 1: _entry <ANY> - entry
 *
 * Return Value:
 * <BOOL> true when an exclusive choice is already completed.
 *
 * Example:
 * [_sideKey, _entry] call Waldo_fnc_EcoResearch_isResearchExclusiveBlocked;
 * Locality/Authority: Any machine; reads published completion state.
 * Repeat/JIP Behaviour: Repeat-safe read; no state mutation.
 * Current Callers: Research status and server start validation.
 * Result: Returns false when no conflicting technology has been completed.
 */

        params ["_sideKey", "_entry"];

        private _blocked = false;
        {
            if ([_sideKey, _x] call Waldo_fnc_EcoResearch_isResearchCompletedForSide) exitWith {
                _blocked = true;
            };
        } forEach (_entry param [8, []]);

        _blocked

