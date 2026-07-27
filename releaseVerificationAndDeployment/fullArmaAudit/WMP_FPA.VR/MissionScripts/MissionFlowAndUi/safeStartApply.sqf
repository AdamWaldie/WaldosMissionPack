/*
 * Author: WaldoTheWarfighter
 * Applies (or removes) the local Safestart effects on the calling machine: full weapons
 * freeze (rifles, grenades, launchers, underbarrel and any crewed vehicle weapon all have
 * their projectiles deleted), invulnerability (no damage dealt or received), an on-screen
 * banner with a live go-live countdown, and safe-zone confinement. Driven globally by
 * Waldo_fnc_SafeStart; also called locally on JIP / respawn to restore the current state.
 * Uses its own variables so it never clashes with the ENDEX freeze.
 *
 * Arguments:
 * 0: Enable <BOOL> (Optional, default: true) - true = apply freeze, false = remove it
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [true] call Waldo_fnc_SafeStartApply;
 */

if !(hasInterface) exitWith {};

params [["_enable", true], ["_reason", "MANUAL"]];

// Shared "Hold Fire!" feedback used by every frozen weapon source.
private _holdFireCode = {
    deletevehicle (_this select 6);
    private _msg = parseText "<t color='#8B0000' size='2' shadow='1' shadowColor='#8B0000' align='center'>Hold Fire!</t><br />";
    [_msg, 3] call Waldo_fnc_SafeStartNotice;
};

if (_enable) then {
    if (isNil {player getVariable "Waldo_WMPProtection_DamageBaseline"}) then {
        player setVariable ["Waldo_WMPProtection_DamageBaseline", isDamageAllowed player];
    };
    // Reference-counted ACE safety. ENDEX may overlap SafeStart and must not
    // inherit or prematurely release this source's exact weapon/muzzle state.
    ["SAFESTART"] call Waldo_fnc_ProtectionAcquireSafety;

    // Freeze the player's own weapons (covers thrown grenades, launchers and underbarrel too).
    if (isNil "Waldo_SafeStart_FiredEH") then {
        Waldo_SafeStart_FiredEH = player addEventHandler ["Fired", _holdFireCode];
    };

    // Freeze the weapons of any vehicle the player is crewing.
    if (vehicle player != player && {player in [gunner vehicle player, driver vehicle player, commander vehicle player]}) then {
        Waldo_SafeStart_Vehicle = vehicle player;
        if (isNil {Waldo_SafeStart_Vehicle getVariable "Waldo_WMPProtection_DamageBaseline"}) then {
            Waldo_SafeStart_Vehicle setVariable ["Waldo_WMPProtection_DamageBaseline", isDamageAllowed Waldo_SafeStart_Vehicle];
        };
        if (isNil "Waldo_SafeStart_VehicleDamageWasAllowed") then {
            Waldo_SafeStart_VehicleDamageWasAllowed = isDamageAllowed Waldo_SafeStart_Vehicle;
        };
        Waldo_SafeStart_Vehicle allowDamage false;
        if (isNil "Waldo_SafeStart_VehFiredEH") then {
            Waldo_SafeStart_VehFiredEH = Waldo_SafeStart_Vehicle addEventHandler ["Fired", _holdFireCode];
        };
    };

    // Invulnerability and the confinement anchor (where this player started the freeze).
    if (isNil "Waldo_SafeStart_PlayerDamageWasAllowed") then {
        Waldo_SafeStart_PlayerDamageWasAllowed = isDamageAllowed player;
    };
    player allowDamage false;
    Waldo_SafeStart_Anchor = getPosATL player;

    // Start the per-client service loop (banner / countdown / confinement). Single instance.
    if !(missionNamespace getVariable ["Waldo_SafeStart_LoopRunning", false]) then {
        missionNamespace setVariable ["Waldo_SafeStart_LoopRunning", true];
        [] spawn {
            while {missionNamespace getVariable ["Waldo_SafeStart_Active", false]} do {
                // Banner + optional countdown clock.
                private _banner = "<t color='#4FA9E8' size='1.4' shadow='1' align='center'>SAFESTART ACTIVE</t><br /><t size='1.0' align='center'>WEAPONS LOCKED | DAMAGE DISABLED</t><br /><t size='0.9' align='center'>Remain inside the marked safe area. Zeus may start or cancel the timer.</t><br />";
                private _endTime = missionNamespace getVariable ["Waldo_SafeStart_EndTime", 0];
                if (_endTime > 0) then {
                    private _rem = (_endTime - serverTime) max 0;
                    private _secs = floor (_rem % 60);
                    private _secStr = if (_secs < 10) then { format ["0%1", _secs] } else { str _secs };
                    _banner = _banner + format ["<t color='#FFD166' size='1.1' align='center'>GO LIVE IN %1:%2</t><br />", floor (_rem / 60), _secStr];
                } else {
                    _banner = _banner + "<t size='0.9' align='center'>No automatic go-live timer is running.</t><br />";
                };
                [true, _banner] call Waldo_fnc_SafeStartHud;

                // Safe-zone confinement.
                if (missionNamespace getVariable ["Waldo_SafeStart_Confine", true]) then {
                    private _marker = missionNamespace getVariable ["Waldo_SafeStart_ZoneMarker", ""];
                    private _radius = missionNamespace getVariable ["Waldo_SafeStart_Radius", 75];
                    private _centre = missionNamespace getVariable ["Waldo_SafeStart_Anchor", getPosATL player];
                    if (_marker != "" && {markerType _marker != ""}) then {
                        _centre = getMarkerPos _marker;
                        private _ms = markerSize _marker;
                        private _mr = (_ms select 0) max (_ms select 1);
                        if (_mr > 0) then { _radius = _mr; };
                    };

                    private _obj = vehicle player;
                    if (alive player && {_obj distance2D _centre > _radius}) then {
                        systemChat "SAFESTART: Return to the safe zone.";
                        private _dir = _centre getDir _obj;
                        private _back = _centre getPos [_radius * 0.8, _dir];
                        _obj setPosATL [_back select 0, _back select 1, (getPosATL _obj) select 2];
                    };
                };

                sleep 1;
            };
            // Lifted - hide only Safestart's own control. Other notifications remain intact.
            [false] call Waldo_fnc_SafeStartHud;
            missionNamespace setVariable ["Waldo_SafeStart_LoopRunning", false];
        };
    };
} else {
    // Remove the player's weapon freeze.
    if !(isNil "Waldo_SafeStart_FiredEH") then {
        player removeEventHandler ["Fired", Waldo_SafeStart_FiredEH];
        Waldo_SafeStart_FiredEH = nil;
    };

    // Restore any crewed vehicle.
    if !(isNil "Waldo_SafeStart_Vehicle") then {
        if !(isNull Waldo_SafeStart_Vehicle) then {
            if !(isNil "Waldo_SafeStart_VehFiredEH") then {
                Waldo_SafeStart_Vehicle removeEventHandler ["Fired", Waldo_SafeStart_VehFiredEH];
            };
            if !(missionNamespace getVariable ["Waldo_ENDEX_Active", false]) then {
                Waldo_SafeStart_Vehicle allowDamage (Waldo_SafeStart_Vehicle getVariable ["Waldo_WMPProtection_DamageBaseline", true]);
                Waldo_SafeStart_Vehicle setVariable ["Waldo_WMPProtection_DamageBaseline", nil];
            };
        };
        Waldo_SafeStart_VehFiredEH = nil;
        Waldo_SafeStart_Vehicle = nil;
        Waldo_SafeStart_VehicleDamageWasAllowed = nil;
    };

    private _endexActive = missionNamespace getVariable ["Waldo_ENDEX_Active", false];
    if (!_endexActive) then {
        player allowDamage (player getVariable ["Waldo_WMPProtection_DamageBaseline", true]);
        player setVariable ["Waldo_WMPProtection_DamageBaseline", nil];
    };
    ["SAFESTART"] call Waldo_fnc_ProtectionReleaseSafety;
    Waldo_SafeStart_PlayerDamageWasAllowed = nil;

    private _duration = missionNamespace getVariable ["Waldo_SafeStart_GoLiveHintDuration", 12];
    private _reasonText = if ((toUpper _reason) == "TIMER") then {"Countdown completed"} else {"Safestart ended manually"};
    private _go = if (_endexActive) then {
        parseText format [
            "<t color='#FFD166' size='1.8' shadow='1' align='center'>SAFESTART ENDED</t><br /><t size='1.1' align='center'>%1</t><br /><t size='0.95' align='center'>ENDEX remains active | Weapons locked | Damage disabled</t><br />",
            _reasonText
        ]
    } else {
        parseText format [
            "<t color='#6CE5A8' size='2' shadow='1' align='center'>GO LIVE</t><br /><t size='1.1' align='center'>%1</t><br /><t size='0.95' align='center'>Weapons released | Damage enabled | Safe-area restriction removed</t><br />",
            _reasonText
        ]
    };
    [_go, _duration] call Waldo_fnc_SafeStartNotice;
    // The service loop terminates itself on its next tick (reads Waldo_SafeStart_Active).
};
