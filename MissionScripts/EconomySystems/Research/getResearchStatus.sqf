/*
 * Author: Waldo
 * Get research status.
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
 * [_sideKey, _entry] call Waldo_fnc_EcoResearch_getResearchStatus;
 */

        params ["_sideKey", "_entry"];

        private _name = _entry param [0, ""];
        if (_name isEqualTo "") exitWith {"invalid"};
        if ([_entry, call Waldo_fnc_EcoResearch_getResearchCatalog] call Waldo_fnc_EcoResearch_hasResearchEntryError) exitWith {"invalid"};
        if ([_sideKey, _name] call Waldo_fnc_EcoResearch_isResearchCompletedForSide) exitWith {"done"};

        private _active = [_sideKey] call Waldo_fnc_EcoResearch_getSideActiveResearch;
        if ((count _active) > 0 && {toLower (_active param [0, ""]) isEqualTo toLower _name}) exitWith {"active"};
        if ((count _active) > 0) exitWith {"busy"};
        if (!(isNil "Waldo_fnc_EcoCommand_hasCommandAuthority") && {!([player] call Waldo_fnc_EcoCommand_hasCommandAuthority)}) exitWith {"command"};
        if !([_sideKey, _entry] call Waldo_fnc_EcoResearch_areResearchRequirementsMet) exitWith {"locked"};
        if ([_sideKey, _entry] call Waldo_fnc_EcoResearch_isResearchExclusiveBlocked) exitWith {"exclusive"};
        if !([_sideKey, _entry] call Waldo_fnc_EcoResearch_canAffordResearch) exitWith {"unaffordable"};

        "ready"

