/*
 * Author: Waldo
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

params [["_enable", true]];

// Shared "Hold Fire!" feedback used by every frozen weapon source.
private _holdFireCode = {
    deletevehicle (_this select 6);
    private _msg = parseText "<t color='#8B0000' size='2' shadow='1' shadowColor='#8B0000' align='center'>Hold Fire!</t><br />";
    [_msg, 3] spawn Waldo_fnc_TimedHint;
};

if (_enable) then {
    // Weapons on safe (ACE).
    if (isClass(configFile >> "CfgPatches" >> "ace_main")) then {
        private _safedWeapons = player getVariable ["ace_safemode_safedWeapons", []];
        if !(currentWeapon player in _safedWeapons) then {
            [player, currentWeapon player, currentMuzzle player] call ace_safemode_fnc_lockSafety;
        };
    };

    // Freeze the player's own weapons (covers thrown grenades, launchers and underbarrel too).
    if (isNil "Waldo_SafeStart_FiredEH") then {
        Waldo_SafeStart_FiredEH = player addEventHandler ["Fired", _holdFireCode];
    };

    // Freeze the weapons of any vehicle the player is crewing.
    if (vehicle player != player && {player in [gunner vehicle player, driver vehicle player, commander vehicle player]}) then {
        Waldo_SafeStart_Vehicle = vehicle player;
        Waldo_SafeStart_Vehicle allowDamage false;
        if (isNil "Waldo_SafeStart_VehFiredEH") then {
            Waldo_SafeStart_VehFiredEH = Waldo_SafeStart_Vehicle addEventHandler ["Fired", _holdFireCode];
        };
    };

    // Invulnerability and the confinement anchor (where this player started the freeze).
    player allowDamage false;
    Waldo_SafeStart_Anchor = getPosATL player;

    // Start the per-client service loop (banner / countdown / confinement). Single instance.
    if !(missionNamespace getVariable ["Waldo_SafeStart_LoopRunning", false]) then {
        missionNamespace setVariable ["Waldo_SafeStart_LoopRunning", true];
        [] spawn {
            while {missionNamespace getVariable ["Waldo_SafeStart_Active", false]} do {
                // Banner + optional countdown clock.
                private _banner = "<t color='#106bb5' size='1.4' shadow='1' align='center'>SAFESTART ACTIVE</t><br /><t size='1.0' align='center'>Weapons Safe - Hold Fire</t><br />";
                private _endTime = missionNamespace getVariable ["Waldo_SafeStart_EndTime", 0];
                if (_endTime > 0) then {
                    private _rem = (_endTime - serverTime) max 0;
                    private _secs = floor (_rem % 60);
                    private _secStr = if (_secs < 10) then { format ["0%1", _secs] } else { str _secs };
                    _banner = _banner + format ["<t size='1.0' align='center'>Go live in %1:%2</t><br />", floor (_rem / 60), _secStr];
                };
                hintSilent parseText _banner;

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
            // Lifted - clear the banner.
            hintSilent "";
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
            Waldo_SafeStart_Vehicle allowDamage true;
        };
        Waldo_SafeStart_VehFiredEH = nil;
        Waldo_SafeStart_Vehicle = nil;
    };

    player allowDamage true;

    systemChat "SAFESTART LIFTED - GO LIVE";
    private _go = parseText "<t color='#3a9c3a' size='2' shadow='1' align='center'>GO LIVE!</t><br />";
    [_go, 4] spawn Waldo_fnc_TimedHint;
    // The service loop terminates itself on its next tick (reads Waldo_SafeStart_Active).
};
