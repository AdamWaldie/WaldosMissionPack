/*

Call as follows:
[] spawn Waldo_fnc_ENDEX;

*/
//systemChat Endex message
systemchat "ENDEX ENDEX ENDEX";
systemChat "Weapons safe";
systemChat "Mission Roll At Zeus Discretion";
//hint Endex message
private _title = "<t color='#106bb5' size='1.2' shadow='1' shadowColor='#106bb5' align='center'>ENDEX ENDEX ENDEX!</t><br />";
private _text0 = "<t font='PuristaMedium' size='1.1'>Mission complete</t><br /><br />";
private _text1 = "Hold your fire!<br />Debrief To Follow!<br />";

// After-action report block (populated by Waldo_fnc_AARTrack; gracefully empty if unused)
private _aar = "";
if !(isNil {missionNamespace getVariable "Waldo_AAR_StartTime"}) then {
    private _start = missionNamespace getVariable ["Waldo_AAR_StartTime", time];
    private _elapsed = (time - _start) max 0;
    private _mins = floor (_elapsed / 60);
    private _secs = floor (_elapsed % 60);
    private _kia = missionNamespace getVariable ["Waldo_AAR_KIA", [0,0,0,0]];
    private _playerKia = missionNamespace getVariable ["Waldo_AAR_PlayerKIA", 0];
    _kia params ["_wKia", "_eKia", "_iKia", "_cKia"];

    _aar = "<br /><t color='#106bb5' size='1.0' align='center'>- AFTER ACTION REPORT -</t><br />";
    _aar = _aar + format ["<t align='center'>Duration: %1m %2s</t><br />", _mins, _secs];
    _aar = _aar + format ["<t align='center'>KIA - BLUFOR %1 | OPFOR %2 | INDEP %3 | CIV %4</t><br />", _wKia, _eKia, _iKia, _cKia];
    _aar = _aar + format ["<t align='center'>Player losses: %1</t><br />", _playerKia];
};

hint parseText(_title + _text0 + _text1 + _aar);

// If ACE loaded, put weapons on safe
if (isClass(configFile >> "CfgPatches" >> "ace_main")) then {
    private _weapon = currentWeapon player; 
    private _safedWeapons = player getVariable ['ace_safemode_safedWeapons', []]; 
    if !(_weapon in _safedWeapons) then {  
        [player, currentWeapon player, currentMuzzle player] call ace_safemode_fnc_lockSafety;
    };
};

//Heal All Players
[player, player] call ace_medical_treatment_fnc_fullHeal;

// Delete bullets from fired weapons
if (isNil "Waldo_PreventWeaponsFireEventHandler") then {
    Waldo_PreventWeaponsFireEventHandler = player addEventHandler["Fired", {deletevehicle (_this select 6);private _HoldFireMessage = "<t color='#8B0000' size='2' shadow='1' shadowColor='#8B0000' align='center'>Hold Fire!</t><br />";_HoldFireMessage = parseText (_HoldFireMessage); [_HoldFireMessage,5] spawn Waldo_fnc_TimedHint;}];
};

// Disable guns and damage for vehicles if player is crewing a vehicle
if (vehicle player != player && {player in [gunner vehicle player,driver vehicle player,commander vehicle player]}) then {
    player setVariable ["Waldo_PreventVehicleFire",vehicle player];
    (player getVariable "Waldo_PreventVehicleFire") allowDamage false;

    if (isNil "Waldo_PreventVehicleFireEventHandler") then {
        Waldo_PreventVehicleFireEventHandler = (player getVariable "Waldo_PreventVehicleFire") addEventHandler["Fired", {deletevehicle (_this select 6);private _HoldFireMessage = "<t color='#8B0000' size='2' shadow='1' shadowColor='#8B0000' align='center'>Hold Fire!</t><br />";_HoldFireMessage = parseText (_HoldFireMessage); [_HoldFireMessage,5] spawn Waldo_fnc_TimedHint;}];
    };
};

// Make player invincible
player allowDamage false;

//Pacify AI
{
    (group _x) setBehaviourStrong "CARELESS";
    (group _x) setCombatMode "BLUE";
} forEach ((allUnits) - (allPlayers));