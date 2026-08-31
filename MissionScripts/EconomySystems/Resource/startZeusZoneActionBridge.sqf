/*
 * Author: WaldoTheWarfighter
 * Start Zeus zone action bridge.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 * Locality / Authority: Server-only zone-anchor and action-publication bridge. Client interactions
 * submit zone-capture requests to the existing authoritative server processor.
 * Repeat / JIP Behaviour: Existing bridge guards prevent duplicate installation. Obsolete pre-V4
 * player flags are cleared once at startup; new/JIP player objects cannot inherit those local flags.
 * Zone actions retain their object-bound named JIP replay and the live zone loop remains unchanged.
 *
 * Arguments:
 * 0: _target <ANY> - target
 * 1: _caller <ANY> - caller
 *
 * Return Value:
 * Nothing
 *
 * Current Callers: Economy Resource client bootstrap.
 *
 * Example:
 * [_target, _caller] call Waldo_fnc_EcoResource_startZeusZoneActionBridge;
 */

    if (!([] call Waldo_fnc_EcoCore_canRunBackgroundAuthority)) exitWith {};
    if (missionNamespace getVariable ["WaldoEcoResource_ZeusZoneActionBridgeStarted", false]) exitWith {};
    missionNamespace setVariable ["WaldoEcoResource_ZeusZoneActionBridgeStarted", true];

    // Compatibility cleanup applies only to player objects that existed under an older bridge
    // version in this running mission. A newly created JIP player cannot carry these obsolete flags,
    // so walking every player on every two-second zone pass only repeated an already-complete check.
    {
        private _unit = _x;
        if (!isNull _unit && {!(_unit getVariable ["WaldoEcoResource_LegacyZoneActionsCleaned", false])}) then {
            {
                [_unit, _x] call Waldo_fnc_EcoCore_clearZeusObjectAction;
            } forEach [
                "WaldoEcoResource_ZeusZoneCaptureActionAddedLocal",
                "WaldoEcoResource_ZeusZoneInfoActionAddedLocal",
                "WaldoEcoResource_ZeusZoneCaptureActionAddedLocalV2",
                "WaldoEcoResource_ZeusZoneInfoActionAddedLocalV2"
            ];
            _unit setVariable ["WaldoEcoResource_ZeusCanCaptureZone", false, true];
            _unit setVariable ["WaldoEcoResource_ZeusInResourceZone", false, true];
            _unit setVariable ["WaldoEcoResource_ZeusCurrentZoneId", "", true];
            _unit setVariable ["WaldoEcoResource_LegacyZoneActionsCleaned", true];
        };
    } forEach allPlayers;

    [] spawn {
        while {[] call Waldo_fnc_EcoCore_isModuleActive} do {
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
                            (_anchor getVariable ["WaldoEcoResource_ZeusZoneCaptureActionAddedLocalV3_Published", false])
                            || {_anchor getVariable ["WaldoEcoResource_ZeusZoneInfoActionAddedLocalV3_Published", false]}
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

                    if ((_anchor getVariable ["WaldoEcoResource_ZoneId", ""]) != _zoneId) then {
                        _anchor setVariable ["WaldoEcoResource_ZoneId", _zoneId, true];
                    };
                    private _actionRadius = 10 max ((_zone param [3, 0]) + 8);

                    [
                        _anchor,
                        "WaldoEcoResource_ZeusZoneCaptureActionAddedLocalV4",
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
                                    ["Only BLUFOR, OPFOR, and INDEP can capture resource areas."] call Waldo_fnc_EcoCore_notifyActorLocal;
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
                                    ["No capturable resource area nearby."] call Waldo_fnc_EcoCore_notifyActorLocal;
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

                                ["ZONE_CAPTURE", _target, _request] call Waldo_fnc_EcoCore_submitRequestServer;
                                ["Capture request sent."] call Waldo_fnc_EcoCore_notifyActorLocal;
                            },
                            nil,
                            1.5,
                            true,
                            true,
                            "",
                            "private _moduleActive = missionNamespace getVariable ['WaldoEcoCore_ModuleActive', true]; private _actor = _this; private _cameraTarget = cameraOn; if (!isNull _cameraTarget) then {if (_cameraTarget isKindOf 'Man') then {if (alive _cameraTarget) then {_actor = _cameraTarget;};};}; private _targetZoneId = _target getVariable ['WaldoEcoResource_ZoneId', '']; private _sideKey = switch (side group _actor) do {case west: {'WEST'}; case east: {'EAST'}; case independent: {'GUER'}; default {'NONE'};}; private _ok = false; if (_moduleActive) then {if (_sideKey != 'NONE') then {private _zones = missionNamespace getVariable ['WaldoEcoResource_ResourceZones', []]; {if (!_ok) then {private _zoneId = _x param [0, '']; if (_zoneId == _targetZoneId) then {private _zonePos = _x param [2, [0, 0, 0]]; private _zoneRadius = _x param [3, 0]; if (((getPosATL _actor) distance2D _zonePos) <= _zoneRadius) then {private _ownerSideKey = _x param [5, 'NONE']; if (_ownerSideKey != _sideKey) then {_ok = true;};};};};} forEach _zones;};}; _ok",
                            _actionRadius
                        ]
                    ] call Waldo_fnc_EcoCore_publishZeusObjectAction;

                    [
                        _anchor,
                        "WaldoEcoResource_ZeusZoneInfoActionAddedLocalV4",
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
                                    ["AREA INFORMATION | No resource area nearby."] call Waldo_fnc_EcoCore_notifyActorLocal;
                                };

                                private _ownerSideKey = _zone param [5, "NONE"];
                                private _ownerText = switch (_ownerSideKey) do {
                                    case "WEST": {"BLUFOR"};
                                    case "EAST": {"OPFOR"};
                                    case "GUER": {"INDEP"};
                                    default {"NONE"};
                                };
                                private _nl = toString [10];
                                private _text = format [
                                    "AREA INFORMATION" + _nl + _nl + "Name: %1" + _nl + "Owner: %2" + _nl + "Radius: %3 m" + _nl + "Generation Interval: %4 sec" + _nl + _nl + "Resources:",
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
                                    private _line = format [_nl + "%1: %2 per tick", _resourceName, _amount];
                                    if (_total > 0) then {
                                        _line = _line + format [" (%1/%2 remaining)", _remaining, _total];
                                    };
                                    _text = _text + _line;
                                } forEach _rows;

                                [_text, 18] call Waldo_fnc_EcoCore_notifyActorLocal;
                            },
                            nil,
                            1.5,
                            true,
                            true,
                            "",
                            "private _moduleActive = missionNamespace getVariable ['WaldoEcoCore_ModuleActive', true]; private _actor = _this; private _cameraTarget = cameraOn; if (!isNull _cameraTarget) then {if (_cameraTarget isKindOf 'Man') then {if (alive _cameraTarget) then {_actor = _cameraTarget;};};}; private _targetZoneId = _target getVariable ['WaldoEcoResource_ZoneId', '']; private _ok = false; if (_moduleActive) then {private _zones = missionNamespace getVariable ['WaldoEcoResource_ResourceZones', []]; {if (!_ok) then {private _zoneId = _x param [0, '']; if (_zoneId == _targetZoneId) then {private _zonePos = _x param [2, [0, 0, 0]]; private _zoneRadius = _x param [3, 0]; if (((getPosATL _actor) distance2D _zonePos) <= _zoneRadius) then {_ok = true;};};};} forEach _zones;}; _ok",
                            _actionRadius
                        ]
                    ] call Waldo_fnc_EcoCore_publishZeusObjectAction;
            } forEach (call Waldo_fnc_EcoResource_getResourceZones);

            uiSleep 2;
        };

        missionNamespace setVariable ["WaldoEcoResource_ZeusZoneActionBridgeStarted", false];
    };
