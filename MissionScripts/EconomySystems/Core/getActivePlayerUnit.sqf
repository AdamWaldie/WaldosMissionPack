/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - getActivePlayerUnit
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_getActivePlayerUnit via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    if (!hasInterface) exitWith {objNull};
    if (isNull player) exitWith {objNull};

    private _cameraTarget = cameraOn;
    if (
        !isNull _cameraTarget
        && {_cameraTarget isKindOf "Man"}
        && {alive _cameraTarget}
        && {!(_cameraTarget isEqualTo player)}
        && {isNull curatorCamera}
    ) exitWith {_cameraTarget};

    player
