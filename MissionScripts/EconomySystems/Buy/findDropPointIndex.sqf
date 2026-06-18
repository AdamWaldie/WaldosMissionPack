/*
 * Author: Waldo
 * Find drop point index.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _dropPointId <STRING> - drop point id (optional, default: "")
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_dropPointId] call Waldo_fnc_EcoBuy_findDropPointIndex;
 */

        params [["_dropPointId", ""]];

        private _rows = call Waldo_fnc_EcoBuy_getDropPoints;
        _rows findIf {((_x param [0, ""]) isEqualTo _dropPointId)}

