/*
 * Author: WaldoTheWarfighter
 * Checks a side's completed-plus-active count against a definition's build limit.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _entry <ARRAY> - entry (optional, default: [])
 * 1: _sideKey <STRING> - side key (optional, default: "NONE")
 *
 * Return Value:
 * <BOOL> true when a positive limit has been reached.
 *
 * Example:
 * [_entry, _sideKey] call Waldo_fnc_EcoBuild_isBuildLimitReachedForSide;
 * Locality/Authority: Any machine; reads published buildings/jobs; server rechecks before start.
 * Repeat/JIP Behaviour: Repeat-safe read of current registries.
 * Current Callers: Construction status and authoritative start gate.
 * Result: A non-positive limit is treated as unlimited.
 */

        params [["_entry", []], ["_sideKey", "NONE"]];

        if ((count _entry) <= 0) exitWith {false};

        private _buildLimit = 0 max (floor (_entry param [19, 0]));
        if (_buildLimit <= 0) exitWith {false};

        private _buildName = _entry param [0, ""];
        ([_sideKey, _buildName] call Waldo_fnc_EcoBuild_getBuildCountForSide) >= _buildLimit

