/*
 * Author: Waldo
 * Get detector marker type.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _entity <OBJECT> - entity (optional, default: objNull)
 * 1: _sideKey <STRING> - side key (optional, default: "NONE")
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_entity, _sideKey] call Waldo_fnc_EcoBuild_getDetectorMarkerType;
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

