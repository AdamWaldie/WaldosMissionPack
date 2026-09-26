/*
 * Author: WaldoTheWarfighter
 * Checks a build definition's side-availability list.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _entry <ARRAY> - entry (optional, default: [])
 * 1: _sideKey <STRING> - side key (optional, default: "NONE")
 *
 * Return Value:
 * <BOOL> true for ALL entries or an included side.
 *
 * Example:
 * [_entry, _sideKey] call Waldo_fnc_EcoBuild_isBuildAvailableForSide;
 * Locality/Authority: Any machine; pure catalog-row check.
 * Repeat/JIP Behaviour: Stateless; JIP receives the same catalog row.
 * Current Callers: Construction catalog filters and job-start validation.
 * Result: A side-restricted mismatch is rejected.
 */

        params [["_entry", []], ["_sideKey", "NONE"]];

        if ((count _entry) <= 0) exitWith {false};

        private _availability = [(_entry param [20, ["ALL"]])] call Waldo_fnc_EcoBuild_normalizeBuildAvailability;
        if ((_availability find "ALL") >= 0) exitWith {true};

        _sideKey in _availability

