/*
 * Author: WaldoTheWarfighter
 * Clean a build-definition list and remove duplicate definition names.
 *
 * Locality / Authority: Pure helper; authority uses the result before publishing, while
 * client prompts use it only for local editing.
 * Repeat/JIP: Deterministic and safe to call again on received catalog state.
 * Current Callers: EcoBuild_promptBuildConfig, EcoBuild_setBuildCatalog
 * and EcoBuild_setBuildCatalogLocal.
 *
 * Arguments:
 * 0: _catalog <ARRAY> - catalog (optional, default: [])
 *
 * Return Value:
 * ARRAY - valid normalized entries, first case-insensitive name wins.
 * Result: Invalid entries and duplicate names are omitted.
 *
 * Example:
 * [_catalog] call Waldo_fnc_EcoBuild_normalizeBuildCatalog;
 */

        params [["_catalog", []]];

        private _result = [];

        {
            private _entry = [_x] call Waldo_fnc_EcoBuild_normalizeBuildEntry;
            if ((count _entry) <= 0) then {continue;};

            private _name = _entry param [0, ""];
            if ((_result findIf {(toLower (_x param [0, ""])) isEqualTo (toLower _name)}) >= 0) then {continue;};
            _result pushBack _entry;
        } forEach _catalog;

        _result

