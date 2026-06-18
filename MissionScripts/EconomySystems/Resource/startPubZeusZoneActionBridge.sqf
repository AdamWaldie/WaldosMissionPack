/*
 * Author: Waldo
 * Start pub zeus zone action bridge.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _target <ANY> - target
 * 1: _caller <ANY> - caller
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_target, _caller] call Waldo_fnc_EcoResource_startPubZeusZoneActionBridge;
 */

    if (!([] call Waldo_fnc_EcoCore_canRunBackgroundAuthority)) exitWith {};
    if (missionNamespace getVariable ["WaldoEcoResource_PubZeusZoneActionBridgeStarted", false]) exitWith {};
    missionNamespace setVariable ["WaldoEcoResource_PubZeusZoneActionBridgeStarted", true];

    [] spawn {
        while {[] call Waldo_fnc_EcoCore_isModuleActive} do {
            {
                private _unit = _x;
                if (isNull _unit) then {continue;};
                {
                    [_unit, _x] call Waldo_fnc_EcoCore_clearPubZeusObjectAction;
                } forEach [
                    "WaldoEcoResource_PubZeusZoneCaptureActionAddedLocal",
                    "WaldoEcoResource_PubZeusZoneInfoActionAddedLocal",
                    "WaldoEcoResource_PubZeusZoneCaptureActionAddedLocalV2",
                    "WaldoEcoResource_PubZeusZoneInfoActionAddedLocalV2"
                ];
                _unit setVariable ["WaldoEcoResource_PubZeusCanCaptureZone", false, true];
                _unit setVariable ["WaldoEcoResource_PubZeusInResourceZone", false, true];
                _unit setVariable ["WaldoEcoResource_PubZeusCurrentZoneId", "", true];
            } forEach allPlayers;

                {
                    private _zone = _x;
                    private _zoneId = _zone param [0, ""];
                    if (_zoneId isEqualTo "") then {continue;};

                    private _anchor = _zone param [10, objNull];
                    if (!isNull _anchor && {(typeOf _anchor) isEqualTo "Land_HelipadEmpty_F"}) then {
                        _anchor setVariable ["WaldoEcoResource_ZoneDeleting", true];
                        deleteVehicle _anchor;
                        _anchor = objNull;
                    };
                    if (
                        !isNull _anchor
                        && {
                            (_anchor getVariable ["WaldoEcoResource_PubZeusZoneCaptureActionAddedLocalV3_Published", false])
                            || {_anchor getVariable ["WaldoEcoResource_PubZeusZoneInfoActionAddedLocalV3_Published", false]}
                        }
                    ) then {
                        _anchor setVariable ["WaldoEcoResource_ZoneDeleting", true];
                        deleteVehicle _anchor;
                        _anchor = objNull;
                    };
                    if (isNull _anchor) then {
                        _anchor = [_zoneId] call Waldo_fnc_EcoResource_createZoneAnchor;
                    };
                    if (isNull _anchor) then {continue;};

                    _anchor setVariable ["WaldoEcoResource_ZoneId", _zoneId, true];
                    private _actionRadius = 10 max ((_zone param [3, 0]) + 8);

                    [
                        _anchor,
                        "WaldoEcoResource_PubZeusZoneCaptureActionAddedLocalV4",
                        [
                            "Capture Resource Area",
                            {
                                params ["_target", "_caller"];

                                private _actor = _caller;
                                private _cameraTarget = cameraOn;
                                if (!isNull _cameraTarget) then {
                                    if (_cameraTarget isKindOf "Man") then {
                                        if (alive _cameraTarget) then {
                                            _actor = _cameraTarget;
                                        };
                                    };
                                };

                                private _targetZoneId = _target getVariable ["WaldoEcoResource_ZoneId", ""];
                                private _sideKey = switch (side group _actor) do {
                                    case west: {"WEST"};
                                    case east: {"EAST"};
                                    case independent: {"GUER"};
                                    default {"NONE"};
                                };
                                if !(_sideKey in ["WEST", "EAST", "GUER"]) exitWith {
                                    hintSilent "Only BLUFOR, OPFOR, and INDEP can capture resource areas.";
                                };

                                private _zoneId = "";
                                private _zones = missionNamespace getVariable ["WaldoEcoResource_ResourceZones", []];
                                {
                                    if (_zoneId == "") then {
                                        private _candidateId = _x param [0, ""];
                                        if (_candidateId == _targetZoneId) then {
                                            private _zonePos = _x param [2, [0, 0, 0]];
                                            private _zoneRadius = _x param [3, 0];
                                            if (((getPosATL _actor) distance2D _zonePos) <= _zoneRadius) then {
                                                private _ownerSideKey = _x param [5, "NONE"];
                                                if (_ownerSideKey != _sideKey) then {
                                                    _zoneId = _candidateId;
                                                };
                                            };
                                        };
                                    };
                                } forEach _zones;

                                if (_zoneId == "") exitWith {
                                    hintSilent "No capturable resource area nearby.";
                                };

                                private _requestId = format [
                                    "%1_%2_%3",
                                    getPlayerUID _caller,
                                    floor (diag_tickTime * 1000),
                                    floor (random 1000000)
                                ];
                                private _request = [
                                    _zoneId,
                                    _sideKey,
                                    getPosATL _actor,
                                    getPlayerUID _caller,
                                    name _caller,
                                    _requestId
                                ];

                                _caller setVariable [
                                    "WaldoEcoResource_ZoneCaptureRequest",
                                    _request,
                                    true
                                ];
                                if (_target != _caller) then {
                                    _target setVariable ["WaldoEcoResource_ZoneCaptureRequest", _request, true];
                                };
                                hintSilent "Capture request sent.";
                            },
                            nil,
                            1.5,
                            true,
                            true,
                            "",
                            "private _moduleActive = missionNamespace getVariable ['WaldoEcoCore_ModuleActive', true]; private _actor = _this; private _cameraTarget = cameraOn; if (!isNull _cameraTarget) then {if (_cameraTarget isKindOf 'Man') then {if (alive _cameraTarget) then {_actor = _cameraTarget;};};}; private _targetZoneId = _target getVariable ['WaldoEcoResource_ZoneId', '']; private _sideKey = switch (side group _actor) do {case west: {'WEST'}; case east: {'EAST'}; case independent: {'GUER'}; default {'NONE'};}; private _ok = false; if (_moduleActive) then {if (_sideKey != 'NONE') then {private _zones = missionNamespace getVariable ['WaldoEcoResource_ResourceZones', []]; {if (!_ok) then {private _zoneId = _x param [0, '']; if (_zoneId == _targetZoneId) then {private _zonePos = _x param [2, [0, 0, 0]]; private _zoneRadius = _x param [3, 0]; if (((getPosATL _actor) distance2D _zonePos) <= _zoneRadius) then {private _ownerSideKey = _x param [5, 'NONE']; if (_ownerSideKey != _sideKey) then {_ok = true;};};};};} forEach _zones;};}; _ok",
                            _actionRadius
                        ]
                    ] call Waldo_fnc_EcoCore_publishPubZeusObjectAction;

                    [
                        _anchor,
                        "WaldoEcoResource_PubZeusZoneInfoActionAddedLocalV4",
                        [
                            "Display Area Information",
                            {
                                params ["_target", "_caller"];

                                private _actor = _caller;
                                private _cameraTarget = cameraOn;
                                if (!isNull _cameraTarget) then {
                                    if (_cameraTarget isKindOf "Man") then {
                                        if (alive _cameraTarget) then {
                                            _actor = _cameraTarget;
                                        };
                                    };
                                };

                                private _targetZoneId = _target getVariable ["WaldoEcoResource_ZoneId", ""];
                                private _zone = [];
                                private _zones = missionNamespace getVariable ["WaldoEcoResource_ResourceZones", []];
                                {
                                    if ((count _zone) == 0) then {
                                        private _candidateId = _x param [0, ""];
                                        if (_candidateId == _targetZoneId) then {
                                            private _zonePos = _x param [2, [0, 0, 0]];
                                            private _zoneRadius = _x param [3, 0];
                                            if (((getPosATL _actor) distance2D _zonePos) <= _zoneRadius) then {
                                                _zone = +_x;
                                            };
                                        };
                                    };
                                } forEach _zones;

                                if ((count _zone) == 0) exitWith {
                                    hint "AREA INFORMATION\n\nNo resource area nearby.";
                                };

                                private _ownerSideKey = _zone param [5, "NONE"];
                                private _ownerText = switch (_ownerSideKey) do {
                                    case "WEST": {"BLUFOR"};
                                    case "EAST": {"OPFOR"};
                                    case "GUER": {"INDEP"};
                                    default {"NONE"};
                                };
                                private _text = format [
                                    "AREA INFORMATION\n\nName: %1\nOwner: %2\nRadius: %3 m\nGeneration Interval: %4 sec\n\nResources:",
                                    _zone param [1, "Resource Zone"],
                                    _ownerText,
                                    _zone param [3, 0],
                                    _zone param [7, 60]
                                ];

                                private _rows = _zone param [4, []];
                                {
                                    private _resourceName = _x param [0, "Resource"];
                                    private _amount = _x param [1, 0];
                                    private _remaining = _x param [2, -1];
                                    private _total = _x param [3, -1];
                                    private _line = format ["\n%1: %2 per tick", _resourceName, _amount];
                                    if (_total > 0) then {
                                        _line = _line + format [" (%1/%2 remaining)", _remaining, _total];
                                    };
                                    _text = _text + _line;
                                } forEach _rows;

                                hint _text;
                            },
                            nil,
                            1.5,
                            true,
                            true,
                            "",
                            "private _moduleActive = missionNamespace getVariable ['WaldoEcoCore_ModuleActive', true]; private _actor = _this; private _cameraTarget = cameraOn; if (!isNull _cameraTarget) then {if (_cameraTarget isKindOf 'Man') then {if (alive _cameraTarget) then {_actor = _cameraTarget;};};}; private _targetZoneId = _target getVariable ['WaldoEcoResource_ZoneId', '']; private _ok = false; if (_moduleActive) then {private _zones = missionNamespace getVariable ['WaldoEcoResource_ResourceZones', []]; {if (!_ok) then {private _zoneId = _x param [0, '']; if (_zoneId == _targetZoneId) then {private _zonePos = _x param [2, [0, 0, 0]]; private _zoneRadius = _x param [3, 0]; if (((getPosATL _actor) distance2D _zonePos) <= _zoneRadius) then {_ok = true;};};};} forEach _zones;}; _ok",
                            _actionRadius
                        ]
                    ] call Waldo_fnc_EcoCore_publishPubZeusObjectAction;
                } forEach (call Waldo_fnc_EcoResource_getResourceZones);

            uiSleep 2;
        };

        missionNamespace setVariable ["WaldoEcoResource_PubZeusZoneActionBridgeStarted", false];
    };
