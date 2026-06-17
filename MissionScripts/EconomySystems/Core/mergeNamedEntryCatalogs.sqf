/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - mergeNamedEntryCatalogs
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_mergeNamedEntryCatalogs via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [
        ["_existing", []],
        ["_incoming", []]
    ];

    private _merged = +_existing;

    {
        private _entry = +_x;
        private _name = toLower (_entry param [0, ""]);
        if (_name isEqualTo "") then {continue;};

        private _index = _merged findIf {(toLower (_x param [0, ""])) isEqualTo _name};
        if (_index < 0) then {
            _merged pushBack _entry;
        } else {
            _merged set [_index, _entry];
        };
    } forEach _incoming;

    _merged
