/*
 * Author: Waldo
 * Merge named entry catalogs.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _existing <ARRAY> - existing (optional, default: [])
 * 1: _incoming <ARRAY> - incoming (optional, default: [])
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_existing, _incoming] call Waldo_fnc_EcoCore_mergeNamedEntryCatalogs;
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
