/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - getResourceCratePlacementPos
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_getResourceCratePlacementPos via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    if (!hasInterface) exitWith {[0, 0, 0]};

    private _posATL = [];
    private _hover = curatorMouseOver;
    private _hoverType = toUpper (_hover param [0, ""]);

    switch (_hoverType) do {
        case "OBJECT": {
            private _obj = _hover param [1, objNull];
            if (!isNull _obj) then {
                _posATL = getPosATLVisual _obj;
            };
        };
        case "GROUP": {
            private _grp = _hover param [1, grpNull];
            if (!isNull _grp) then {
                _posATL = getPosATLVisual (leader _grp);
            };
        };
        case "MARKER": {
            private _marker = _hover param [1, ""];
            if (_marker isNotEqualTo "") then {
                _posATL = getMarkerPos _marker;
            };
        };
        case "EMPTY": {
            _posATL = +(_hover param [1, []]);
        };
    };

    if ((count _posATL) isEqualTo 0) then {
        private _cam = curatorCamera;
        if (!isNull _cam) then {
            private _mouse = getMousePosition;
            private _screenATL = screenToWorld _mouse;
            private _originASL = getPosASLVisual _cam;
            private _targetASL = ATLToASL _screenATL;
            private _dir = _originASL vectorFromTo _targetASL;

            if ((vectorMagnitude _dir) < 0.001) then {
                _dir = vectorDirVisual _cam;
            };

            _dir = vectorNormalized _dir;

            private _hits = lineIntersectsSurfaces [
                _originASL,
                _originASL vectorAdd (_dir vectorMultiply 5000),
                _cam,
                objNull,
                true,
                1,
                "GEOM",
                "VIEW"
            ];

            if ((count _hits) > 0) then {
                _posATL = ASLToATL ((_hits select 0) select 0);
            } else {
                _posATL = _screenATL;
            };
        };
    };

    if ((count _posATL) < 3) then {
        _posATL resize 3;
    };

    _posATL set [2, 0 max (_posATL select 2)];
    _posATL
