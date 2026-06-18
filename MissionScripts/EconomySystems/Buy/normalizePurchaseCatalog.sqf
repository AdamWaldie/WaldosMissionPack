/*
 * Author: Waldo
 * Normalize purchase catalog.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _catalog <ARRAY> - catalog (optional, default: [])
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_catalog] call Waldo_fnc_EcoBuy_normalizePurchaseCatalog;
 */

        params [["_catalog", []]];

        private _result = [];
        {
            private _entry = [_x] call Waldo_fnc_EcoBuy_normalizePurchaseEntry;
            if ((count _entry) <= 0) then {continue;};

            private _name = _entry param [0, ""];
            if ((_result findIf {(toLower (_x param [0, ""])) isEqualTo (toLower _name)}) >= 0) then {continue;};
            _result pushBack _entry;
        } forEach _catalog;

        _result

