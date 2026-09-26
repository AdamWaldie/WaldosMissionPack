/*
 * Author: WaldoTheWarfighter
 * Looks up a delivery-point ID in the published registry.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _dropPointId <STRING> - drop point id (optional, default: "")
 *
 * Return Value:
 * <NUMBER> zero-based row index, or -1 when absent.
 *
 * Example:
 * [_dropPointId] call Waldo_fnc_EcoBuy_findDropPointIndex;
 * Locality/Authority: Any machine; read-only lookup.
 * Repeat/JIP Behaviour: Stateless lookup of current published rows.
 * Current Callers: Delivery-point delete and authoring helpers.
 * Result: Returns the matching registry index without changing it.
 */

        params [["_dropPointId", ""]];

        private _rows = call Waldo_fnc_EcoBuy_getDropPoints;
        _rows findIf {((_x param [0, ""]) isEqualTo _dropPointId)}

