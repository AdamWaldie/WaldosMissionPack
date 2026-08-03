/*
 * Author: WaldoTheWarfighter
 * Start client runtime.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _ctrl <ANY> - ctrl
 * 1: _path <ANY> - path
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_ctrl, _path] call Waldo_fnc_EcoResource_startClientRuntime;
 */

    if (!hasInterface) exitWith {};
    if (!isNil "WaldoEcoResource_ZeusHookStarted") exitWith {};

    WaldoEcoResource_ZeusHookStarted = true;


    [] spawn {
        private _lastVisible = missionNamespace getVariable ["WaldoEcoResource_ResourceMarkersVisible", true];
        private _lastMarkers = [];

        while {[] call Waldo_fnc_EcoCore_isModuleActive} do {
            private _visible = missionNamespace getVariable ["WaldoEcoResource_ResourceMarkersVisible", true];
            private _markers = call Waldo_fnc_EcoResource_getActiveResourceMarkers;

            if ((_visible isNotEqualTo _lastVisible) || {(_markers isNotEqualTo _lastMarkers)}) then {
                call Waldo_fnc_EcoResource_applyResourceMarkerVisibilityLocal;
                _lastVisible = _visible;
                _lastMarkers = +_markers;
            };

            uiSleep 1;
        };
    };
