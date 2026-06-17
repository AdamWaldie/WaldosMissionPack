/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - validateBuildImportPayload
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_validateBuildImportPayload via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params ["_payload"];

        if !(_payload isEqualType []) exitWith {false};
        if ((count _payload) < 3) exitWith {false};
        if !((_payload param [0, ""]) in ["WaldoEcoBuild_BUILD_V1", "WaldoEcoBuild_BUILD_V2", "WaldoEcoBuild_BUILD_V3"]) exitWith {false};
        if !((_payload param [1, false]) isEqualType true) exitWith {false};
        if !((_payload param [2, []]) isEqualType []) exitWith {false};

        true

