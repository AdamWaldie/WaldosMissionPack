/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuy system - normalizePurchaseCatalog
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuy_normalizePurchaseCatalog via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
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

