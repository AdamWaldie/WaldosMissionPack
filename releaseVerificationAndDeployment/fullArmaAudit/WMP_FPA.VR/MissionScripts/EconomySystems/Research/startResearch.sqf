/*
 * Author: WaldoTheWarfighter
 * Validates a side's research choice, spends its costs and begins the authoritative timer.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * 0: _sideKey <STRING> - side key (WEST/EAST/GUER/CIV)
 * 1: _researchName <STRING> - technology name in the current catalog
 * 2: _caller <OBJECT> - caller (optional, default: objNull)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_sideKey, _researchName, _caller] call Waldo_fnc_EcoResearch_startResearch;
 * Locality/Authority: Economy authority only; client actions submit a validated request.
 * Repeat/JIP Behaviour: A side cannot start a second concurrent technology. Active research
 * state and completion are published to JIP clients.
 * Current Callers: Research centre action and Economy start-research request handler.
 * Result: Starts research only when command authority, requirements and resources permit it;
 * otherwise the caller receives the relevant WMP notice.
 */

        params ["_sideKey", "_researchName", ["_caller", objNull]];

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
        if (!(isNil "Waldo_fnc_EcoCommand_hasCommandAuthority") && {!([_caller] call Waldo_fnc_EcoCommand_hasCommandAuthority)}) exitWith {};

        private _entry = [_researchName, call Waldo_fnc_EcoResearch_getResearchCatalog] call Waldo_fnc_EcoResearch_getResearchEntryByName;
        if ((count _entry) <= 0) exitWith {};
        if ([_entry, call Waldo_fnc_EcoResearch_getResearchCatalog] call Waldo_fnc_EcoResearch_hasResearchEntryError) exitWith {};
        if ([_sideKey, _researchName] call Waldo_fnc_EcoResearch_isResearchCompletedForSide) exitWith {
            [_caller, format ["%1: already researched.", _researchName]] call Waldo_fnc_EcoCore_notifyActor;
        };
        if ((count ([_sideKey] call Waldo_fnc_EcoResearch_getSideActiveResearch)) > 0) exitWith {
            [_caller, "Research already in progress for your side."] call Waldo_fnc_EcoCore_notifyActor;
        };
        if !([_sideKey, _entry] call Waldo_fnc_EcoResearch_areResearchRequirementsMet) exitWith {
            [_caller, format ["%1: requirements not met.", _researchName]] call Waldo_fnc_EcoCore_notifyActor;
        };
        if ([_sideKey, _entry] call Waldo_fnc_EcoResearch_isResearchExclusiveBlocked) exitWith {
            [_caller, format ["%1: blocked by a conflicting research choice.", _researchName]] call Waldo_fnc_EcoCore_notifyActor;
        };
        if !([_sideKey, _entry] call Waldo_fnc_EcoResearch_spendResearchCosts) exitWith {
            [_caller, format ["%1: not enough resources.", _researchName]] call Waldo_fnc_EcoCore_notifyActor;
        };

        [_caller, format ["%1: research started.", _researchName]] call Waldo_fnc_EcoCore_notifyActor;
        [_sideKey, [_entry param [0, ""], 1 max (_entry param [4, 60]), 0, 0, serverTime]] call Waldo_fnc_EcoResearch_setSideActiveResearch;

