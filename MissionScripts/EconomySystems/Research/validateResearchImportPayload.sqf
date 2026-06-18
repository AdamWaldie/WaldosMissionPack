/*
 * Author: Waldo
 * Validate research import payload.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * 0: _payload <ANY> - payload
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_payload] call Waldo_fnc_EcoResearch_validateResearchImportPayload;
 */

        params ["_payload"];

        if !(_payload isEqualType []) exitWith {false};
        if ((count _payload) < 3) exitWith {false};
        if ((_payload param [0, ""]) isNotEqualTo "WaldoEcoResearch_RESEARCH_V1") exitWith {false};
        if !((_payload param [1, false]) isEqualType true) exitWith {false};
        if !((_payload param [2, []]) isEqualType []) exitWith {false};

        true

