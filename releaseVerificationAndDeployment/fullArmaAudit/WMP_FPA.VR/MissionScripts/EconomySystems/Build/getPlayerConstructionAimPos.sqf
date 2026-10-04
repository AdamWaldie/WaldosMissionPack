/*
 * Author: WaldoTheWarfighter
 * Convert the centre of the player's screen to a construction preview position.
 *
 * Locality / Authority: Interface client only; screenToWorld uses that player's camera.
 * Repeat/JIP: Read-only and repeat-safe; each client's camera is independent.
 * Current Callers: EcoBuild_beginPlayerConstructionPlacement.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * ARRAY - three-element world position with Z clamped to at least zero.
 * Result: The preview follows the point beneath the player's crosshair.
 *
 * Example:
 * [] call Waldo_fnc_EcoBuild_getPlayerConstructionAimPos;
 */

        private _pos = screenToWorld [0.5, 0.5];
        if ((count _pos) < 3) then {
            _pos = [_pos select 0, _pos select 1, 0];
        };
        _pos set [2, 0 max (_pos select 2)];
        _pos

