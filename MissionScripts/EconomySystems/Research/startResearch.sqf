/*
 * Author: Waldo
 * Start research.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * 0: _sideKey <ANY> - side key
 * 1: _researchName <ANY> - research name
 * 2: _caller <OBJECT> - caller (optional, default: objNull)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_sideKey, _researchName, _caller] call Waldo_fnc_EcoResearch_startResearch;
 */

        params ["_sideKey", "_researchName", ["_caller", objNull]];

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
        if (!(isNil "Waldo_fnc_EcoCommand_hasCommandAuthority") && {!([_caller] call Waldo_fnc_EcoCommand_hasCommandAuthority)}) exitWith {};

        private _entry = [_researchName, call Waldo_fnc_EcoResearch_getResearchCatalog] call Waldo_fnc_EcoResearch_getResearchEntryByName;
        if ((count _entry) <= 0) exitWith {};
        if ([_entry, call Waldo_fnc_EcoResearch_getResearchCatalog] call Waldo_fnc_EcoResearch_hasResearchEntryError) exitWith {};
        if ([_sideKey, _researchName] call Waldo_fnc_EcoResearch_isResearchCompletedForSide) exitWith {};
        if ((count ([_sideKey] call Waldo_fnc_EcoResearch_getSideActiveResearch)) > 0) exitWith {};
        if !([_sideKey, _entry] call Waldo_fnc_EcoResearch_areResearchRequirementsMet) exitWith {};
        if ([_sideKey, _entry] call Waldo_fnc_EcoResearch_isResearchExclusiveBlocked) exitWith {};
        if !([_sideKey, _entry] call Waldo_fnc_EcoResearch_spendResearchCosts) exitWith {};

        [_sideKey, [_entry param [0, ""], 1 max (_entry param [4, 60]), 0, 0, serverTime]] call Waldo_fnc_EcoResearch_setSideActiveResearch;

