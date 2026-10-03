/*
 * Author: WaldoTheWarfighter
 * Classifies one technology's current availability to a side/player.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * 0: _sideKey <ANY> - side key
 * 1: _entry <ANY> - entry
 *
 * Return Value:
 * <STRING> invalid, done, active, busy, command, locked, exclusive,
 * unaffordable or ready.
 *
 * Example:
 * [_sideKey, _entry] call Waldo_fnc_EcoResearch_getResearchStatus;
 * Locality/Authority: Interface/authority query; reads published research and resource state
 * and uses the local player for the Ground Command gate.
 * Repeat/JIP Behaviour: Repeat-safe read; JIP clients see current published state.
 * Current Callers: Research centre action visibility and status display.
 * Result: Returns the first reason the technology cannot start, or "ready".
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

