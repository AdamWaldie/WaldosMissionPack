/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - ensureStableZonePlayerActionsLocal
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_ensureStableZonePlayerActionsLocal via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    if (!hasInterface) exitWith {};
    if (isNull player) exitWith {};
    if (player getVariable ["WaldoEcoResource_StableZoneActionsAddedLocal", false]) exitWith {};

    private _captureId = player addAction [
        "Capture Resource Area",
        {
            private _actor = call Waldo_fnc_EcoCore_getActivePlayerUnit;
            [_actor] call Waldo_fnc_EcoResource_captureCurrentZoneForUnit;
        },
        nil,
        1.5,
        true,
        true,
        "",
        "!(isNil 'Waldo_fnc_EcoResource_canUnitCaptureCurrentZone') && {[_this] call Waldo_fnc_EcoResource_canUnitCaptureCurrentZone}",
        5
    ];

    private _infoId = player addAction [
        "Display Area Information",
        {
            private _actor = call Waldo_fnc_EcoCore_getActivePlayerUnit;
            [_actor] call Waldo_fnc_EcoResource_showCurrentZoneInfoForUnit;
        },
        nil,
        1.5,
        true,
        true,
        "",
        "!(isNil 'Waldo_fnc_EcoResource_canUnitViewCurrentZone') && {[_this] call Waldo_fnc_EcoResource_canUnitViewCurrentZone}",
        5
    ];

    player setVariable ["WaldoEcoResource_StableZoneCaptureAction", _captureId];
    player setVariable ["WaldoEcoResource_StableZoneInfoAction", _infoId];
    player setVariable ["WaldoEcoResource_StableZoneActionsAddedLocal", true];
