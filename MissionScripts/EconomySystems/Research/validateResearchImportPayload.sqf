/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResearch system - validateResearchImportPayload
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResearch_validateResearchImportPayload via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params ["_payload"];

        if !(_payload isEqualType []) exitWith {false};
        if ((count _payload) < 3) exitWith {false};
        if ((_payload param [0, ""]) isNotEqualTo "WaldoEcoResearch_RESEARCH_V1") exitWith {false};
        if !((_payload param [1, false]) isEqualType true) exitWith {false};
        if !((_payload param [2, []]) isEqualType []) exitWith {false};

        true

