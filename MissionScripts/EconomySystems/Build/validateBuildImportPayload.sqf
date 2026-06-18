/*
 * Author: Waldo
 * Validate build import payload.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _payload <ANY> - payload
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_payload] call Waldo_fnc_EcoBuild_validateBuildImportPayload;
 */

        params ["_payload"];

        if !(_payload isEqualType []) exitWith {false};
        if ((count _payload) < 3) exitWith {false};
        if !((_payload param [0, ""]) in ["WaldoEcoBuild_BUILD_V1", "WaldoEcoBuild_BUILD_V2", "WaldoEcoBuild_BUILD_V3"]) exitWith {false};
        if !((_payload param [1, false]) isEqualType true) exitWith {false};
        if !((_payload param [2, []]) isEqualType []) exitWith {false};

        true

