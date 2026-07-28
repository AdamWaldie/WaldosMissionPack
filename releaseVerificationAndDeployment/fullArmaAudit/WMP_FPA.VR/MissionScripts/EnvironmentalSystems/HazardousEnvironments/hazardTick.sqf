/*
 * Author: Waldo
 * Evaluates all registered hazard zones for the local player and applies profile effects.
 *
 * Arguments:
 * 0: interval <NUMBER> - seconds represented by this tick
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [1] call Waldo_fnc_HazardTick;
 */

params [["_interval", 1, [0]]];
if (remoteExecutedOwner > 0) exitWith {};
if !(hasInterface && {alive player}) exitWith {};

private _exposures = missionNamespace getVariable ["Waldo_Hazard_LocalExposure", createHashMap];
private _previousInside = missionNamespace getVariable ["Waldo_Hazard_LocalInside", createHashMap];
private _activeText = [];

{
    _x params ["_key", "_area", "_profile"];
    private _inside = false;
    private _intensity = 0;

    if (_area isEqualType []) then {
        private _centre = _area select 0;
        private _axisA = (_area select 1) max 1;
        private _axisB = if (count _area >= 5) then {(_area select 2) max 1} else {_axisA};
        _inside = if (count _area >= 5) then {player inArea [_centre, _axisA, _axisB, _area select 3, _area select 4]} else {player distance2D _centre <= _axisA};
        if (_inside) then {_intensity = 1 - ((player distance2D _centre) / (_axisA max _axisB))};
    };
    if (_area isEqualType "") then {
        _inside = player inArea _area;
        if (_inside) then {
            private _radius = selectMax (markerSize _area) max 1;
            _intensity = 1 - ((player distance2D getMarkerPos _area) / _radius);
        };
    };
    if (_area isEqualType objNull) then {
        if (_area isKindOf "EmptyDetector") then {
            _inside = player inArea _area;
            if (_inside) then {
                private _triggerSize = triggerArea _area;
                private _radius = ((_triggerSize select 0) max (_triggerSize select 1)) max 1;
                _intensity = 1 - ((player distance2D _area) / _radius);
            };
        } else {
            private _radius = (_profile getOrDefault ["emitterRadius", 10]) max 1;
            _inside = player distance2D _area <= _radius;
            if (_inside) then {_intensity = 1 - ((player distance2D _area) / _radius)};
        };
    };

    private _altitude = getPosATL player select 2;
    if (_inside && {_altitude < (_profile getOrDefault ["minimumAltitudeATL", -1e10]) || {_altitude > (_profile getOrDefault ["maximumAltitudeATL", 1e10])}}) then {
        _inside = false;
        _intensity = 0;
    };

    if (toUpperANSI (_profile getOrDefault ["intensityMode", "LINEAR"]) == "CONSTANT" && {_inside}) then {_intensity = 1};

    _intensity = if (_inside) then {
        (_intensity max (_profile getOrDefault ["minimumIntensity", 0.05])) min 1
    } else {
        0
    };
    private _exposure = _exposures getOrDefault [_key, 0];
    if (_inside) then {
        private _protection = [player, _profile] call Waldo_fnc_HazardProtectionFactor;
        _exposure = _exposure + ((_profile getOrDefault ["rate", 1]) * _intensity * _protection * _interval);
        {
            _exposures set [_x, ((_exposures getOrDefault [_x, 0]) - ((_profile getOrDefault ["decontaminationRate", 1]) * _interval)) max 0];
        } forEach (_profile getOrDefault ["reducesChannels", []]);
    } else {
        _exposure = (_exposure - ((_profile getOrDefault ["decay", 0.1]) * _interval)) max 0;
    };
    _exposure = _exposure min (_profile getOrDefault ["maximumExposure", 1e10]);
    _exposures set [_key, _exposure];

    private _wasInside = _previousInside getOrDefault [_key, false];
    if (_inside != _wasInside) then {
        private _transition = _profile getOrDefault [if (_inside) then {"onEnter"} else {"onExit"}, {}];
        if (_transition isEqualType {}) then {[player, _key, _profile] call _transition};
        _previousInside set [_key, _inside];
    };

    if (_inside || {_exposure > 0}) then {
        private _label = _profile getOrDefault ["label", _profile getOrDefault ["type", "HAZARD"]];
        _activeText pushBack format ["%1: %2", _label, (_exposure toFixed 2)];
    };

    private _damage = 0;
    {
        _x params ["_threshold", "_tickDamage"];
        if (_exposure >= _threshold) then {_damage = _tickDamage};
    } forEach (_profile getOrDefault ["damageThresholds", []]);

    if (_damage > 0) then {
        if (isClass (configFile >> "CfgPatches" >> "ace_medical")) then {
            private _bodyPart = selectRandom ["Head", "Body", "LeftArm", "RightArm", "LeftLeg", "RightLeg"];
            [player, _damage, _bodyPart, _profile getOrDefault ["damageType", "burn"]] call ace_medical_fnc_addDamageToUnit;
        } else {
            player setDamage ((damage player) + _damage min 1);
        };
    };
    private _fatalAt = _profile getOrDefault ["fatalExposure", -1];
    if (_fatalAt >= 0 && {_exposure >= _fatalAt}) then {player setDamage 1};

    private _onTick = _profile getOrDefault ["onTick", {}];
    if (_onTick isEqualType {}) then {
        [player, _inside, _intensity, _exposure, _profile] call _onTick;
    };
} forEach +(missionNamespace getVariable ["Waldo_Hazard_Zones", []]);

missionNamespace setVariable ["Waldo_Hazard_LocalExposure", _exposures];
missionNamespace setVariable ["Waldo_Hazard_LocalInside", _previousInside];
if (missionNamespace getVariable ["Waldo_Hazard_ShowStatus", true] && {count _activeText > 0}) then {
    private _text = parseText format ["<t align='right' size='0.75'>%1</t>", _activeText joinString "<br/>" ];
    [_text, safeZoneX + safeZoneW - 0.42, safeZoneY + 0.22, 1.1, 0, 0, 791] spawn BIS_fnc_dynamicText;
};
