/*
 * Author: Waldo
 * Get build marker class.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _iconPath <STRING> - icon path (optional, default: "")
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_iconPath] call Waldo_fnc_EcoBuild_getBuildMarkerClass;
 */

        params [["_iconPath", ""]];

        private _choices = call Waldo_fnc_EcoResource_getMarkerIconChoices;
        private _index = _choices findIf {
            ((_x param [1, ""]) isEqualTo _iconPath)
        };

        if (_index < 0) exitWith {"mil_dot"};
        (_choices select _index) param [0, "mil_dot"]

