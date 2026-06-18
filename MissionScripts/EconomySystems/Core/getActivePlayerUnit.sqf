/*
 * Author: Waldo
 * Get active player unit.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [] call Waldo_fnc_EcoCore_getActivePlayerUnit;
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
