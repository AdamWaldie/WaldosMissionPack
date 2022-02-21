/*

Call as follows:

[] spawn Waldo_fnc_ENDEX;

*/

//systemChat Endex message
systemchat "ENDEX ENDEX ENDEX";
systemChat "Weapons safe";
systemChat "Mission Roll In 1 Minute";
//hint Endex message
private _title = "<t color='#0055aa' size='1.2' shadow='1' shadowColor='#ed9d18' align='center'>ENDEX ENDEX ENDEX!</t><br />";
private _text0 = "<t font='PuristaMedium' size='1.1'>Mission complete</t><br /><br />";
private _text1 = "Hold your fire!<br />";
hint parseText(_title + _text0 + _text1);


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

//Pacify AI
{
    (group _x) setBehaviourStrong "CARELESS";
    (group _x) setCombatMode "BLUE";
} forEach ((allUnits) - (allPlayers));

sleep 60;
//End Mission
"end1" call BIS_fnc_endMission;