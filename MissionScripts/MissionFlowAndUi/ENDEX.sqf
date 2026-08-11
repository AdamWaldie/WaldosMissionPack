/*
 * Author: WaldoTheWarfighter
 * ENDEX (exercise end) - freezes the mission: broadcasts "ENDEX ENDEX ENDEX", puts weapons on ACE
 * safety, heals all players, deletes fired rounds, sets all AI to CARELESS/BLUE, makes players
 * invincible, and shows the WMP debrief panel (including the After-Action Report when AAR tracking
 * ran). The AAR report includes a "Confirmed deaths" section from Waldo_AAR_Obituary when the
 * Obituary system has recorded any medic-pronounced deaths. Also available via the Zeus "Waldos
 * Mission Modules - Call Endex" module.
 * Locality and authority: server publishes the authoritative Waldo_ENDEX_Active transition once,
 * then every interface client applies the local freeze/report itself; safe to call on any machine.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] spawn Waldo_fnc_ENDEX;
 * Result: the mission freezes and every interface client shows the debrief panel with the AAR.
 * Current callers: mission-maker scripting/triggers and the Zeus "Call Endex" module.
 */

params [["_applyLocal", false, [false]]];

// One server-owned transition publishes the state before clients apply the
// freeze. This makes ENDEX idempotent and lets SafeStart report which system
// still owns weapon protection.
if (!_applyLocal) exitWith {
    if (!isServer) then {
        [] remoteExecCall ["Waldo_fnc_ENDEX", 2];
    } else {
        if !(missionNamespace getVariable ["Waldo_ENDEX_Active", false]) then {
            missionNamespace setVariable ["Waldo_ENDEX_Active", true, true];
            [true] remoteExecCall ["Waldo_fnc_ENDEX", -2];
            if (hasInterface) then {[true] call Waldo_fnc_ENDEX;};
            diag_log "[WMP ENDEX] state=ACTIVE weapons=LOCKED damage=DISABLED";
        };
    };
};
if (!hasInterface) exitWith {};
if (isNil {player getVariable "Waldo_WMPProtection_DamageBaseline"}) then {
    player setVariable ["Waldo_WMPProtection_DamageBaseline", isDamageAllowed player];
};
private _text1 = "<t align='center'>Weapons locked | Damage disabled | Players healed | AI pacified</t><br /><t align='center'>Remain in place and review the after-action report below.</t><br />";

// After-action report block (populated by Waldo_fnc_AARTrack; gracefully empty if unused)
private _aar = "";
if !(isNil {missionNamespace getVariable "Waldo_AAR_StartTime"}) then {
    private _start = missionNamespace getVariable ["Waldo_AAR_StartTime", time];
    private _elapsed = (time - _start) max 0;
    private _mins = floor (_elapsed / 60);
    private _secs = floor (_elapsed % 60);
    private _kia = missionNamespace getVariable ["Waldo_AAR_KIA", [0,0,0,0]];
    private _playerKia = missionNamespace getVariable ["Waldo_AAR_PlayerKIA", 0];
    private _vehKia = missionNamespace getVariable ["Waldo_AAR_VehKIA", [0,0,0,0]];
    private _wia = missionNamespace getVariable ["Waldo_AAR_WIA", [0,0,0,0]];
    private _ff = missionNamespace getVariable ["Waldo_AAR_FF", 0];
    private _frags = missionNamespace getVariable ["Waldo_AAR_Frags", []];
    private _tasks = missionNamespace getVariable ["Waldo_AAR_Tasks", []];
    _kia params ["_wKia", "_eKia", "_iKia", "_cKia"];

    _aar = "<br /><t color='#106bb5' size='1.0' align='center'>- AFTER ACTION REPORT -</t><br />";
    _aar = _aar + format ["<t align='center'>Duration: %1m %2s</t><br />", _mins, _secs];
    _aar = _aar + format ["<t align='center'>KIA - BLUFOR %1 | OPFOR %2 | INDEP %3 | CIV %4</t><br />", _wKia, _eKia, _iKia, _cKia];
    _aar = _aar + format ["<t align='center'>Player losses: %1</t><br />", _playerKia];

    // Vehicles destroyed (only shown if any were lost)
    if ((_vehKia findIf {_x > 0}) >= 0) then {
        _vehKia params ["_wVeh", "_eVeh", "_iVeh", "_cVeh"];
        _aar = _aar + format ["<t align='center'>Vehicles lost - BLUFOR %1 | OPFOR %2 | INDEP %3 | CIV %4</t><br />", _wVeh, _eVeh, _iVeh, _cVeh];
    };

    // WIA (only shown if any were recorded - requires ACE)
    if ((_wia findIf {_x > 0}) >= 0) then {
        _wia params ["_wWia", "_eWia", "_iWia", "_cWia"];
        _aar = _aar + format ["<t align='center'>WIA - BLUFOR %1 | OPFOR %2 | INDEP %3 | CIV %4</t><br />", _wWia, _eWia, _iWia, _cWia];
    };

    // Friendly-fire incidents (only shown if any)
    if (_ff > 0) then {
        _aar = _aar + format ["<t align='center'>Friendly-fire incidents: %1</t><br />", _ff];
    };

    // Confirmed deaths (only shown if any were pronounced via the medic Pronounce Dead action)
    private _obituary = missionNamespace getVariable ["Waldo_AAR_Obituary", []];
    if (count _obituary > 0) then {
        private _sortedObituary = [_obituary, [], {toLower (_x select 0)}, "ASCEND"] call BIS_fnc_sortBy;
        _aar = _aar + "<t align='center'>Confirmed deaths:</t><br />";
        {
            _x params ["_obitName", "_obitCount"];
            _aar = _aar + format ["<t align='center'>%1 (%2)</t><br />", _obitName, _obitCount];
        } forEach _sortedObituary;
    };

    // Objective summary (only shown if any tasks were registered via Waldo_fnc_CreateObjective)
    if (count _tasks > 0) then {
        private _succeeded = {(toUpper (_x select 1)) == "SUCCEEDED"} count _tasks;
        private _failed = {(toUpper (_x select 1)) in ["FAILED", "CANCELED"]} count _tasks;
        private _objLine = format ["<t align='center'>Objectives: %1/%2 complete", _succeeded, count _tasks];
        if (_failed > 0) then { _objLine = _objLine + format [", %1 failed", _failed]; };
        _aar = _aar + _objLine + "</t><br />";
    };

    // Top fraggers leaderboard (only shown if any player kills were recorded)
    if (count _frags > 0) then {
        private _sorted = [_frags, [], {_x select 1}, "DESCEND"] call BIS_fnc_sortBy;
        _aar = _aar + "<t align='center'>Top fraggers:</t><br />";
        {
            _x params ["_fragName", "_fragCount"];
            _aar = _aar + format ["<t align='center'>%1 (%2)</t><br />", _fragName, _fragCount];
        } forEach (_sorted select [0, 3]);
    };
};

private _endexDuration = missionNamespace getVariable ["Waldo_ENDEX_ReportDuration", 45];
[
    "ENDEX // EXERCISE FROZEN",
    _text1 + _aar,
    "WARNING",
    _endexDuration,
    "TOP_RIGHT",
    "ENDEX",
    "WMP OPERATIONS",
    "REPLACE",
    100,
    false
] call Waldo_fnc_ShowUiNotification;

// Claim the exact ACE safety state independently of SafeStart. The shared
// protection manager releases it only after every active WMP source is clear.
["ENDEX"] call Waldo_fnc_ProtectionAcquireSafety;

//Heal All Players
[player, player] call ace_medical_treatment_fnc_fullHeal;

// Delete bullets from fired weapons
if (isNil "Waldo_PreventWeaponsFireEventHandler") then {
    Waldo_PreventWeaponsFireEventHandler = player addEventHandler ["Fired", {
        deleteVehicle (_this select 6);
        private _message = parseText "<t color='#FF6161' size='1.5' shadow='1' align='center'>ENDEX ACTIVE</t><br/><t align='center'>Weapons remain locked until the exercise is reset.</t>";
        [_message, 5] call Waldo_fnc_SafeStartNotice;
    }];
};

// Disable guns and damage for vehicles if player is crewing a vehicle
if (vehicle player != player && {player in [gunner vehicle player,driver vehicle player,commander vehicle player]}) then {
    player setVariable ["Waldo_PreventVehicleFire",vehicle player];
    if (isNil {(player getVariable "Waldo_PreventVehicleFire") getVariable "Waldo_WMPProtection_DamageBaseline"}) then {
        (player getVariable "Waldo_PreventVehicleFire") setVariable ["Waldo_WMPProtection_DamageBaseline", isDamageAllowed (player getVariable "Waldo_PreventVehicleFire")];
    };
    missionNamespace setVariable ["Waldo_ENDEX_VehicleDamageWasAllowed", isDamageAllowed (player getVariable "Waldo_PreventVehicleFire")];
    (player getVariable "Waldo_PreventVehicleFire") allowDamage false;

    if (isNil "Waldo_PreventVehicleFireEventHandler") then {
        Waldo_PreventVehicleFireEventHandler = (player getVariable "Waldo_PreventVehicleFire") addEventHandler ["Fired", {
            deleteVehicle (_this select 6);
            private _message = parseText "<t color='#FF6161' size='1.5' shadow='1' align='center'>ENDEX ACTIVE</t><br/><t align='center'>Vehicle weapons remain locked until the exercise is reset.</t>";
            [_message, 5] call Waldo_fnc_SafeStartNotice;
        }];
    };
};

// Make player invincible
missionNamespace setVariable ["Waldo_ENDEX_PlayerDamageWasAllowed", isDamageAllowed player];
player allowDamage false;

//Pacify AI
{
    (group _x) setBehaviourStrong "CARELESS";
    (group _x) setCombatMode "BLUE";
} forEach ((allUnits) - (allPlayers));
