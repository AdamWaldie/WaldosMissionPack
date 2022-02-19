/*

Call as follows:

[] call Waldo_fnc_ENDEX;

*/

//systemChat Endex message
"ENDEX ENDEX ENDEX" remoteExecCall ["systemChat", -2];
"Weapons Safed" remoteExecCall ["systemChat", -2];
"1 Minute Until Mission Rolls" remoteExecCall ["systemChat", -2];

//hint Endex message
private _title = "<t color='#ffc61a' size='1.2' shadow='1' shadowColor='#000000' align='center'>ENDEX ENDEX ENDEX!</t><br />";
private _text0 = "<t font='PuristaMedium' size='1.1'>Mission complete</t><br /><br />";
private _text1 = "Hold your fire!<br />";
parseText(_title + _text0 + _text1) remoteExecCall ["hint", -2];


// If ACE loaded, put weapons on safe
if (isClass(configFile >> "CfgPatches" >> "ace_main")) then {
        {
            private _weapon = currentWeapon player; 
            private _safedWeapons = player getVariable ['ace_safemode_safedWeapons', []]; 
            if !(_weapon in _safedWeapons) then {  
                [player, currentWeapon player, currentMuzzle player] call ace_safemode_fnc_lockSafety;
            };
        } remoteExecCall ["bis_fnc_call", -2]; 
    };

//Heal All Players
<<<<<<< Updated upstream
{
    [player, player] call ace_medical_fnc_treatmentAdvanced_fullHealLocal;
} remoteExecCall ["bis_fnc_call", -2]; 
=======
[objNull, player] call ace_medical_fnc_treatmentAdvanced_fullHealLocal;
>>>>>>> Stashed changes

//Pacify AI
{
    (group _x) setBehaviourStrong "CARELESS";
    (group _x) setCombatMode "BLUE";
} forEach ((allUnits) - (allPlayers));

sleep 60;
//End Mission
"end1" call BIS_fnc_endMission;