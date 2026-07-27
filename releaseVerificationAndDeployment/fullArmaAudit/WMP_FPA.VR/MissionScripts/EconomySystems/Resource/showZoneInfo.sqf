/*
 * Author: WaldoTheWarfighter
 * Show zone info.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _zoneId <ANY> - zone id
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_zoneId] call Waldo_fnc_EcoResource_showZoneInfo;
 */

    params ["_zoneId"];

    if (!hasInterface) exitWith {};

    [[_zoneId] call Waldo_fnc_EcoResource_getZoneInfoText, 18] call Waldo_fnc_EcoCore_notifyActorLocal;
