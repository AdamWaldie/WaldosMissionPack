/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - startClientRuntime
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_startClientRuntime via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    if (!hasInterface) exitWith {};
    if (!isNil "WaldoEcoResource_ZeusHookStarted") exitWith {};

    WaldoEcoResource_ZeusHookStarted = true;

    [] spawn {
        private _wasOpen = false;

        while {[] call Waldo_fnc_EcoCore_isModuleActive} do {
            private _disp = call Waldo_fnc_EcoCore_getZeusDisplay;
            private _isOpen = !isNull _disp;

            if (_isOpen && !_wasOpen) then {
                _wasOpen = true;
                call Waldo_fnc_EcoResource_startAuthorityLoops;

                [] spawn {
                    uiSleep 0.5;

                    private _disp = call Waldo_fnc_EcoCore_getZeusDisplay;
                    if (isNull _disp) exitWith {};
                    if (_disp getVariable ["WaldoEcoResource_MenuInjected", false]) exitWith {};

                    private _tree = [_disp] call Waldo_fnc_EcoCore_getZeusTreeControl;
                    if (isNull _tree) exitWith {};
                    [_tree] call Waldo_fnc_EcoCore_ensureZeusHeaderRoot;

                    private _fallbackClass = "Land_PlasticCase_01_medium_F";

                    private _menuIndexes = [_tree, [
                        "Resource System",
                        "Resource System",
                        _fallbackClass,
                        [
                            ["config", "Configure Resources", "Add or remove resource types"],
                            ["crate", "Create Resource Crate", "Create a resource crate"],
                            ["zone", "Create Resource Zone", "Create a capturable resource zone"],
                            ["groundCommand", "Ground Command", "Promote or remove Ground Command players"],
                            ["settings", "Set Resources", "View and edit side resources"],
                            ["visibility", "Toggle Resource Visibility", "Show or hide resource markers for players"]
                        ]
                    ]] call Waldo_fnc_EcoCore_injectZeusMenu;

                    private _rootIndex = _menuIndexes param [0, -1];
                    private _childIndexes = _menuIndexes param [1, []];
                    private _crateChildIndex = ["crate", _childIndexes] call Waldo_fnc_EcoCore_getInjectedMenuChildIndex;
                    private _zoneChildIndex = ["zone", _childIndexes] call Waldo_fnc_EcoCore_getInjectedMenuChildIndex;
                    private _settingsChildIndex = ["settings", _childIndexes] call Waldo_fnc_EcoCore_getInjectedMenuChildIndex;
                    private _configChildIndex = ["config", _childIndexes] call Waldo_fnc_EcoCore_getInjectedMenuChildIndex;
                    private _visibilityChildIndex = ["visibility", _childIndexes] call Waldo_fnc_EcoCore_getInjectedMenuChildIndex;
                    private _groundCommandChildIndex = ["groundCommand", _childIndexes] call Waldo_fnc_EcoCore_getInjectedMenuChildIndex;

                    _tree setVariable ["WaldoEcoResource_RootIndex", _rootIndex];
                    _tree setVariable ["WaldoEcoResource_CrateChildIndex", _crateChildIndex];
                    _tree setVariable ["WaldoEcoResource_ZoneChildIndex", _zoneChildIndex];
                    _tree setVariable ["WaldoEcoResource_SettingsChildIndex", _settingsChildIndex];
                    _tree setVariable ["WaldoEcoResource_ConfigChildIndex", _configChildIndex];
                    _tree setVariable ["WaldoEcoResource_VisibilityChildIndex", _visibilityChildIndex];
                    _tree setVariable ["WaldoEcoResource_GroundCommandChildIndex", _groundCommandChildIndex];
                    _disp setVariable ["WaldoEcoResource_MenuInjected", true];

                    if (isNil {_tree getVariable "WaldoEcoResource_SelectEH"}) then {
                        private _eh = _tree ctrlAddEventHandler [
                            "TreeSelChanged",
                            {
                                params ["_ctrl", "_path"];

                                if (_ctrl getVariable ["WaldoEcoResource_BlockSelectionEH", false]) exitWith {};

                                private _rootIndex = _ctrl getVariable ["WaldoEcoResource_RootIndex", -1];
                                private _crateChildIndex = _ctrl getVariable ["WaldoEcoResource_CrateChildIndex", -1];
                                private _zoneChildIndex = _ctrl getVariable ["WaldoEcoResource_ZoneChildIndex", -1];
                                private _settingsChildIndex = _ctrl getVariable ["WaldoEcoResource_SettingsChildIndex", -1];
                                private _configChildIndex = _ctrl getVariable ["WaldoEcoResource_ConfigChildIndex", -1];
                                private _visibilityChildIndex = _ctrl getVariable ["WaldoEcoResource_VisibilityChildIndex", -1];
                                private _groundCommandChildIndex = _ctrl getVariable ["WaldoEcoResource_GroundCommandChildIndex", -1];

                                if ((count _path) isEqualTo 2 && {(_path select 0) isEqualTo _rootIndex}) then {
                                    _ctrl setVariable ["WaldoEcoResource_BlockSelectionEH", true];

                                    [_ctrl] spawn {
                                        disableSerialization;
                                        params ["_tree"];

                                        uiSleep 0;
                                        _tree tvSetCurSel [-1];
                                        _tree setVariable ["WaldoEcoResource_BlockSelectionEH", false];
                                    };

                                    if ((_path select 1) isEqualTo _crateChildIndex) then {
                                        [] call Waldo_fnc_EcoResource_beginResourceCratePlacement;
                                    };

                                    if ((_path select 1) isEqualTo _zoneChildIndex) then {
                                        [] call Waldo_fnc_EcoResource_beginResourceZonePlacement;
                                    };

                                    if ((_path select 1) isEqualTo _settingsChildIndex) then {
                                        [] call Waldo_fnc_EcoResource_promptResourceSettings;
                                    };

                                    if ((_path select 1) isEqualTo _configChildIndex) then {
                                        [] call Waldo_fnc_EcoResource_promptResourceConfig;
                                    };

                                    if ((_path select 1) isEqualTo _visibilityChildIndex) then {
                                        [name player] call Waldo_fnc_EcoResource_toggleResourceMarkerVisibility;
                                    };

                                    if ((_path select 1) isEqualTo _groundCommandChildIndex) then {
                                        [] call Waldo_fnc_EcoCommand_promptGroundCommand;
                                    };
                                };
                            }
                        ];

                        _tree setVariable ["WaldoEcoResource_SelectEH", _eh];
                    };
                };
            };

            if (!_isOpen && _wasOpen) then {
                _wasOpen = false;
            };

            uiSleep 0.25;
        };
    };

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
