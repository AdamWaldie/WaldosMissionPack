/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuy system - normalizePurchaseType
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuy_normalizePurchaseType via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_value", "Ground"]];

        private _trimmed = [_value] call Waldo_fnc_EcoCore_trimString;
        private _choices = call Waldo_fnc_EcoBuy_getPurchaseTypeChoices;
        private _index = _choices findIf {(toLower _x) isEqualTo (toLower _trimmed)};
        if (_index < 0) exitWith {"Ground"};
        _choices select _index

