/*
 * Author: WaldoTheWarfighter
 * Chooses a valid map-marker type for a detector contact.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _entity <OBJECT> - entity (optional, default: objNull)
 * 1: _sideKey <STRING> - side key (optional, default: "NONE")
 *
 * Return Value:
 * <STRING> CfgMarkers type, falling back to mil_dot.
 *
 * Example:
 * [_entity, _sideKey] call Waldo_fnc_EcoBuild_getDetectorMarkerType;
 * Locality/Authority: Any machine; read-only entity/config lookup.
 * Repeat/JIP Behaviour: Stateless; no JIP effect.
 * Current Callers: Detector contact marker construction.
 * Result: Unsupported entity markers display as a dot.
 */

        params [["_entity", objNull], ["_sideKey", "NONE"]];

        private _prefix = [_sideKey] call Waldo_fnc_EcoBuild_getMarkerSidePrefix;
        private _suffix = "unknown";
        if (!isNull _entity) then {
            if ((getNumber (configOf _entity >> "isUav")) > 0) then {
                _suffix = "uav";
            } else {
                if (_entity isKindOf "Plane") then {
                    _suffix = "plane";
                } else {
                    if (_entity isKindOf "Helicopter") then {
                        _suffix = "air";
                    } else {
                        if (_entity isKindOf "Tank") then {
                            _suffix = "armor";
                        } else {
                            if ((_entity isKindOf "Wheeled_APC_F") || {_entity isKindOf "Tracked_APC_F"}) then {
                                _suffix = "mech_inf";
                            } else {
                                if ((_entity isKindOf "Ship_F") || {_entity isKindOf "Boat_F"}) then {
                                    _suffix = "naval";
                                } else {
                                    if (_entity isKindOf "Car") then {
                                        _suffix = "motor_inf";
                                    } else {
                                        if (_entity isKindOf "Man") then {
                                            _suffix = "inf";
                                        };
                                    };
                                };
                            };
                        };
                    };
                };
            };
        };

        private _markerClass = format ["%1_%2", _prefix, _suffix];
        if !(isClass (configFile >> "CfgMarkers" >> _markerClass)) then {
            _markerClass = format ["%1_unknown", _prefix];
        };
        if !(isClass (configFile >> "CfgMarkers" >> _markerClass)) then {
            _markerClass = "mil_dot";
        };
        _markerClass

