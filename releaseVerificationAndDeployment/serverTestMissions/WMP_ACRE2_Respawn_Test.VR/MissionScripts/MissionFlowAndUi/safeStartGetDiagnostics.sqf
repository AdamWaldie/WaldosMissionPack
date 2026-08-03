/* Author: WaldoTheWarfighter. Returns normalized SafeStart diagnostics. */
private _active = missionNamespace getVariable ["Waldo_SafeStart_Active", false];
private _endTime = missionNamespace getVariable ["Waldo_SafeStart_EndTime", 0];
private _remaining = if (_active && {_endTime > 0}) then {(_endTime - serverTime) max 0} else {-1};
private _checks = [
    ["mission-flow", "safestart-authority", if (_active) then {"ACTIVE"} else {"LOADED"}, format ["active=%1 endTime=%2 remaining=%3 confine=%4 radius=%5", _active, _endTime, _remaining, missionNamespace getVariable ["Waldo_SafeStart_Confine", true], missionNamespace getVariable ["Waldo_SafeStart_Radius", 75]]]
];

if (hasInterface) then {
    private _hud = (findDisplay 46) displayCtrl 5300;
    private _loop = missionNamespace getVariable ["Waldo_SafeStart_LoopRunning", false];
    private _protectionPresent = !isNil "Waldo_SafeStart_FiredEH" && {!(isDamageAllowed player)};
    private _clientOk = !_active || {_loop && {_protectionPresent}};
    _checks pushBack ["mission-flow", "safestart-client-protection", if (!_clientOk) then {"ERROR"} else {if (_active) then {"ACTIVE"} else {"LOADED"}}, format ["loop=%1 firedHandler=%2 damageAllowed=%3", _loop, !isNil "Waldo_SafeStart_FiredEH", isDamageAllowed player]];
    _checks pushBack ["world-ui", "safestart-hud", if (!_active) then {"LOADED"} else {if (!isNull _hud && {ctrlShown _hud}) then {"ACTIVE"} else {"ERROR"}}, format ["display46=%1 control=%2 shown=%3", !isNull (findDisplay 46), !isNull _hud, !isNull _hud && {ctrlShown _hud}]];
};

["safestart", _checks] call Waldo_fnc_DiagnosticFeatureReport
