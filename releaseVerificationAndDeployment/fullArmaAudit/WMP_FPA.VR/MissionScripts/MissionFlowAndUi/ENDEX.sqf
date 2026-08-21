/*
 * Author: WaldoTheWarfighter
 * ENDEX (exercise end) - freezes the mission: broadcasts "ENDEX ENDEX ENDEX", puts weapons on ACE
 * safety, heals all players, deletes fired rounds, sets all AI to CARELESS/BLUE, makes players
 * invincible, and shows a compact, balanced After-Action Report in the persistent ENDEX UI card.
 * It prioritises KIA, player/vehicle losses, friendly fire, objectives, named confirmed deaths and
 * top fraggers; temporary WIA is intentionally omitted. Also available via the Zeus "Waldos
 * Mission Modules - Call Endex" module.
 * Locality and authority: server publishes the authoritative Waldo_ENDEX_Active transition once,
 * sends the complete server-local AAR counters in the same ordered call, then every interface
 * client applies the local freeze/report itself; safe to call on any machine.
 *
 * Arguments:
 * 0: apply locally <BOOL> (internal, default false)
 * 1: AAR snapshot <ARRAY> (internal, default []) - version, start time, KIA/vehicle counters,
 *    player losses, friendly fire and frag leaderboard.
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] spawn Waldo_fnc_ENDEX;
 * Result: the mission freezes and every interface client shows the debrief panel with the AAR.
 * Current callers: mission-maker scripting/triggers and the Zeus "Call Endex" module.
 */

params [["_applyLocal", false, [false]], ["_aarSnapshot", [], [[]]]];

// One server-owned transition publishes the state before clients apply the
// freeze. This makes ENDEX idempotent and lets SafeStart report which system
// still owns weapon protection.
if (!_applyLocal) exitWith {
    if (!isServer) then {
        [] remoteExecCall ["Waldo_fnc_ENDEX", 2];
    } else {
        if !(missionNamespace getVariable ["Waldo_ENDEX_Active", false]) then {
            private _snapshot = [
                1,
                missionNamespace getVariable ["Waldo_AAR_StartTime", time],
                +(missionNamespace getVariable ["Waldo_AAR_KIA", [0,0,0,0]]),
                +(missionNamespace getVariable ["Waldo_AAR_VehKIA", [0,0,0,0]]),
                missionNamespace getVariable ["Waldo_AAR_PlayerKIA", 0],
                missionNamespace getVariable ["Waldo_AAR_FF", 0],
                +(missionNamespace getVariable ["Waldo_AAR_Frags", []])
            ];
            missionNamespace setVariable ["Waldo_ENDEX_Active", true, true];
            [true, _snapshot] remoteExecCall ["Waldo_fnc_ENDEX", -2];
            if (hasInterface) then {[true, _snapshot] call Waldo_fnc_ENDEX;};
            diag_log "[WMP ENDEX] state=ACTIVE weapons=LOCKED damage=DISABLED";
        };
    };
};
if (!hasInterface) exitWith {};
if (count _aarSnapshot >= 7 && {_aarSnapshot param [0, 0, [0]] == 1}) then {
    missionNamespace setVariable ["Waldo_AAR_StartTime", _aarSnapshot select 1];
    missionNamespace setVariable ["Waldo_AAR_KIA", +(_aarSnapshot select 2)];
    missionNamespace setVariable ["Waldo_AAR_VehKIA", +(_aarSnapshot select 3)];
    missionNamespace setVariable ["Waldo_AAR_PlayerKIA", _aarSnapshot select 4];
    missionNamespace setVariable ["Waldo_AAR_FF", _aarSnapshot select 5];
    missionNamespace setVariable ["Waldo_AAR_Frags", +(_aarSnapshot select 6)];
};
if (isNil {player getVariable "Waldo_WMPProtection_DamageBaseline"}) then {
    player setVariable ["Waldo_WMPProtection_DamageBaseline", isDamageAllowed player];
};
private _text1 = "Weapons locked | Damage disabled | Players healed | AI pacified";

// Split the report into readable UI pages; the renderer replaces the same ENDEX card rather than
// adding notifications or overflowing into other lanes.
private _aarPages = [] call Waldo_fnc_ENDEXBuildReportPages;
if (_aarPages isEqualTo []) then {_aarPages = [["SUMMARY", "No after-action tracking data is available."]]};

private _endexDuration = missionNamespace getVariable ["Waldo_ENDEX_ReportDuration", 45];
private _firstPageLabel = if (count _aarPages > 1) then {
    "AFTER ACTION REPORT - PAGE 1 OF " + str (count _aarPages) + " // " + ((_aarPages select 0) select 0)
} else {
    "AFTER ACTION REPORT"
};
[
    "ENDEX // EXERCISE FROZEN",
    _text1 + "<br/><t color='#106bb5' align='center'>" + _firstPageLabel + "</t><br/>" + ((_aarPages select 0) select 1),
    "WARNING",
    _endexDuration,
    "TOP_RIGHT",
    "ENDEX",
    "WMP OPERATIONS",
    "REPLACE",
    100,
    false
] call Waldo_fnc_ShowUiNotification;

private _pageGeneration = (missionNamespace getVariable ["Waldo_ENDEX_PageGeneration", 0]) + 1;
missionNamespace setVariable ["Waldo_ENDEX_PageGeneration", _pageGeneration];
if (count _aarPages > 1) then {[_aarPages, _text1, _pageGeneration] spawn {
    params ["_pages", "_status", "_generation"];
    private _page = 1 mod (count _pages);
    while {
        missionNamespace getVariable ["Waldo_ENDEX_Active", false]
        && {_generation == missionNamespace getVariable ["Waldo_ENDEX_PageGeneration", -1]}
    } do {
        private _entry = _pages select _page;
        [
            "ENDEX // EXERCISE FROZEN",
            _status + format ["<br/><br/><t color='#106bb5' align='center'>AFTER ACTION REPORT - PAGE %1 OF %2 // %3</t><br/>%4", _page + 1, count _pages, _entry select 0, _entry select 1],
            "WARNING", 10, "TOP_RIGHT", "ENDEX", "WMP OPERATIONS", "REPLACE", 100, false
        ] call Waldo_fnc_ShowUiNotification;
        _page = (_page + 1) mod (count _pages);
        uiSleep 9;
    };
}};

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
