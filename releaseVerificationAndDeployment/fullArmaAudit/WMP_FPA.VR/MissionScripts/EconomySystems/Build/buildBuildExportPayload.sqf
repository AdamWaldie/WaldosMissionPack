/*
 * Author: WaldoTheWarfighter
 * Serialize the build catalog for a portable Economy configuration export.
 *
 * Locality / Authority: Runs where the current catalog is held; this is a read-only helper.
 * Repeat/JIP: Safe to repeat; it does not change the catalog or publish JIP state.
 * Current Callers: EcoCore_buildUnifiedSaveExportPayload.
 *
 * Arguments:
 * 0: _includeBuilt <BOOL> - retained compatibility argument (default: false);
 *    the export always omits live built-object state.
 *
 * Return Value:
 * STRING - SQF-formatted BUILD_V3 catalog payload.
 * Result: Returns definitions with their runtime built flags cleared, so
 * importing a preset cannot claim that its world objects already exist.
 *
 * Example:
 * [_includeBuilt] call Waldo_fnc_EcoBuild_buildBuildExportPayload;
 */

        params [["_includeBuilt", false]];

        private _catalog = call Waldo_fnc_EcoBuild_getBuildCatalog;
        private _payloadCatalog = [];

        {
            private _entry = +_x;
            _entry set [7, false];
            _payloadCatalog pushBack _entry;
        } forEach _catalog;

        str ["WaldoEcoBuild_BUILD_V3", false, _payloadCatalog]

