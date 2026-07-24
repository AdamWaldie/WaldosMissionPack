/*
 * Author: Waldo
 * Applies the EMP effect to one entity on the machine that owns it (so the changes replicate
 * correctly). Infantry lose their night-vision goggles and have their TFAR radio disabled for the
 * duration; if the infantryman is the local player they also get a white-out flash and a clear
 * "EMP - electronics down" message. Vehicles have their engine cut (fuel drained) for the duration
 * and restored afterwards. Driven by Waldo_fnc_EMP; not usually called directly.
 *
 * Arguments:
 * 0: Entity <OBJECT> - the unit or vehicle to disable
 * 1: Duration <NUMBER> - seconds the electronics stay down (optional, default: 30)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_unit, 30] call Waldo_fnc_EMPApply;
 */

params [["_entity", objNull], ["_duration", 30]];

if (isNull _entity) exitWith {};

if (_entity isKindOf "Man") then {
    // Fry night-vision.
    private _nvg = hmd _entity;
    if (_nvg != "") then {
        _entity unassignItem _nvg;
        _entity removeItem _nvg;
    };

    // Cut TFAR radio use for the duration (no-op if TFAR is absent - it is just a unit variable).
    _entity setVariable ["tf_unable_to_use_radio", true];
    [_entity, _duration] spawn {
        params ["_u", "_d"];
        sleep _d;
        if (!isNull _u) then { _u setVariable ["tf_unable_to_use_radio", false]; };
    };

    // Local player feedback: white-out flash + explicit message.
    if (_entity == player && {hasInterface}) then {
        [] spawn {
            cutText ["", "WHITE OUT", 0.15];
            sleep 0.2;
            cutText ["", "WHITE IN", 1.2];
        };
        systemChat "*** EMP DETONATION - electronics down (intentional EW effect, not a bug). ***";
        private _msg = parseText "<t color='#7ab8ff' size='2' shadow='1' align='center'>EMP</t><br /><t size='1' align='center'>Electronics disrupted in this area</t><br />";
        [_msg, 4] spawn Waldo_fnc_TimedHint;
    };
} else {
    // Vehicle: kill the engine by draining fuel, restore it afterwards.
    if !(_entity getVariable ["Waldo_EMP_VehDown", false]) then {
        private _fuel = fuel _entity;
        _entity setVariable ["Waldo_EMP_VehDown", true, true];
        _entity engineOn false;
        _entity setFuel 0;
        [_entity, _fuel, _duration] spawn {
            params ["_v", "_f", "_d"];
            sleep _d;
            if (!isNull _v) then {
                _v setFuel (_f max 0.05);
                _v setVariable ["Waldo_EMP_VehDown", false, true];
            };
        };
    };
};
