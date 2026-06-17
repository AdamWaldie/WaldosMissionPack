/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - removeUnifiedPlayerActionsLocal
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_removeUnifiedPlayerActionsLocal via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    if (!hasInterface || {isNull player}) exitWith {};

    private _captureAction = player getVariable ["WaldoEcoResource_ZoneCaptureAction", -1];
    if (_captureAction >= 0) then {
        player removeAction _captureAction;
        player setVariable ["WaldoEcoResource_ZoneCaptureAction", -1];
    };

    private _infoAction = player getVariable ["WaldoEcoResource_ZoneInfoAction", -1];
    if (_infoAction >= 0) then {
        player removeAction _infoAction;
        player setVariable ["WaldoEcoResource_ZoneInfoAction", -1];
    };

    private _stableCaptureAction = player getVariable ["WaldoEcoResource_StableZoneCaptureAction", -1];
    if (_stableCaptureAction >= 0) then {
        player removeAction _stableCaptureAction;
        player setVariable ["WaldoEcoResource_StableZoneCaptureAction", -1];
    };

    private _stableInfoAction = player getVariable ["WaldoEcoResource_StableZoneInfoAction", -1];
    if (_stableInfoAction >= 0) then {
        player removeAction _stableInfoAction;
        player setVariable ["WaldoEcoResource_StableZoneInfoAction", -1];
    };

    player setVariable ["WaldoEcoResource_StableZoneActionsAddedLocal", false];
