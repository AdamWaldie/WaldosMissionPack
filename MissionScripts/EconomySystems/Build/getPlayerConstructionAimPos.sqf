/*
 * Author: Waldo
 * Get player construction aim pos.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Any - see function body
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

