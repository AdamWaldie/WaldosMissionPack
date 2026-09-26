/*
 * Author: WaldoTheWarfighter
 * Carries out one AI Orders module order on the machine that owns the group, and tells the curator
 * the real result.
 *
 * The order functions forward to the group's owner when called elsewhere and return true for "sent",
 * which is not the same as "accepted": the owner can still refuse (Zeus hold, exclusion, pass not
 * running, no aircraft). Waldo_fnc_FeatureRuntimeApply therefore sends owner-sensitive orders for a
 * group on another machine (a headless client) here, on that owner, and runs everything else here on
 * the server. The order function then runs where the group is local, and its own answer is what the
 * curator is told. If the group changed owner again before the order arrived, the order is refused
 * and the curator is asked to try again.
 * Locality and authority: the server, or a group owner the server sent the order to; calls from any
 * other machine are refused.
 *
 * Arguments:
 * 0: order <STRING> - GARRISON, DEFEND, RELEASE, CLEAR, AIRBORNE, EXCLUDE, RETURN, ARTY_SUPPORT, ARTY_COUNTER or ARTY_BOTH
 * 1: group <GROUP>
 * 2: position <ARRAY> - garrison, defence or clear position
 * 3: radius <NUMBER> - garrison radius or defence line width
 * 4: building <OBJECT> - building to clear (objNull uses the nearest building to the position)
 * 5: facing <NUMBER> - defence line facing
 * 6: request owner <NUMBER> - client ID of the curator to notify (2 or less: no notification)
 *
 * Return Value:
 * Boolean - true when the order was accepted where the group is local
 *
 * Example:
 * ["GARRISON", _group, getPosATL leader _group, 50, objNull, 0, 3] call Waldo_fnc_AIPassOrderLocal;
 * Result: the group garrisons and client 3 is told whether it did.
 *
 * Current caller: Waldo_fnc_FeatureRuntimeApply (AI_ORDER).
 */

params [["_order", "", [""]], ["_group", grpNull, [grpNull]], ["_position", [], [[]]], ["_radius", 50, [0]],
    ["_building", objNull, [objNull]], ["_facing", 0, [0]], ["_requestOwner", 0, [0]]];
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};
private _moved = !isNull _group && {!local _group} && {_order in ["GARRISON", "DEFEND", "RELEASE", "CLEAR", "AIRBORNE"]};
private _accepted = if (_moved) then {false} else {
    switch (_order) do {
        case "GARRISON": {[_group, _position, (_radius max 15) min 150] call Waldo_fnc_AIPassGarrison};
        case "DEFEND": {[_group, _position, _facing, (_radius max 15) min 150] call Waldo_fnc_AIPassDefend};
        case "RELEASE": {
            private _released = false;
            if ((_group getVariable ["Waldo_AIPass_Garrison", []]) isNotEqualTo []) then {_released = [_group] call Waldo_fnc_AIPassGarrisonRelease};
            if ((_group getVariable ["Waldo_AIPass_Defend", []]) isNotEqualTo []) then {_released = ([_group] call Waldo_fnc_AIPassDefendRelease) || _released};
            _released
        };
        case "EXCLUDE": {
            if (isNull _group) exitWith {false};
            _group setVariable ["Waldo_AIPass_Exclude", true, true];
            true
        };
        case "RETURN": {
            if (isNull _group) exitWith {false};
            _group setVariable ["Waldo_AIPass_Exclude", nil, true];
            _group setVariable ["Waldo_AIPass_ZeusWaypoints", false, true];
            // A zero-length token cancels any remaining Zeus hold on every machine.
            _group setVariable ["Waldo_AIPass_ZeusHold", [random 1e6, 0], true];
            true
        };
        case "CLEAR": {[_group, [_building, _position] select isNull _building] call Waldo_fnc_AIPassClearBuilding};
        case "AIRBORNE": {[_group] call Waldo_fnc_AIPassAirborneDrop};
        case "ARTY_SUPPORT": {[_group, "SUPPORT"] call Waldo_fnc_AIPassSetArtilleryRole};
        case "ARTY_COUNTER": {[_group, "COUNTER"] call Waldo_fnc_AIPassSetArtilleryRole};
        case "ARTY_BOTH": {[_group, "BOTH"] call Waldo_fnc_AIPassSetArtilleryRole};
        default {false};
    };
};
private _message = switch (true) do {
    case (_moved): {format ["The %1 order was not carried out: the group changed owner while the order was on its way. Place the module again.", toLowerANSI _order]};
    case (_accepted): {format ["The %1 order was accepted.", toLowerANSI _order]};
    default {
        format ["The %1 order was refused. Check that the Smart AI Pass is enabled and the group is valid; an airborne drop also needs the squad riding an AI-flown aircraft at least 120 m over land, and an artillery order needs a group crewing artillery.", toLowerANSI _order]
    };
};
diag_log format ["[WMP AI PASS] action=AI_ORDER machine=%1 owner=%2 order=%3 group=%4 accepted=%5", clientOwner, _requestOwner, _order, _group, _accepted];
if (_requestOwner > 2) then {
    ["AI ORDERS", _message, ["ERROR", "SUCCESS"] select _accepted, "AI_ORDERS", 7] remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", _requestOwner];
};
_accepted
