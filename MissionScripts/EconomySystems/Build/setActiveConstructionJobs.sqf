/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - setActiveConstructionJobs
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_setActiveConstructionJobs via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_rows", []]];
        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
        missionNamespace setVariable ["WaldoEcoBuild_ActiveConstructionJobs", _rows, true];

