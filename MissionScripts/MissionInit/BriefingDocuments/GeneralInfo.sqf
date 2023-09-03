private _playerRole = call Waldo_fnc_GetPlayerRole;
private _group = groupId (group player);
private _playerGroup = "";
if (_group == "") then { _playerGroup = "in your squad" } else { _playerGroup = formatText["under the callsign <font color='#addde6'>%1</font>", _group]};

private _worldName = getText (configFile >> "CfgWorlds" >> worldName >> "description");
private _serverName = if (serverName != "") then {serverName} else {"localhost"}; 


private _abilityMedic = "";
if (!(isNil {player getUnitTrait "medic"}) && !(isNil {player getVariable "ACE_medical_medicClass"})) then {
    switch (player getVariable "ACE_medical_medicClass") do {
        case 1: { _abilityMedic = " <font color='#addde6'>medic</font> training" };
        case 2: { _abilityMedic = " <font color='#addde6'>doctor</font> training" };
        default { _abilityMedic = "" };
    };
};

private _abilityEngineer = "";
if (!(isNil {player getUnitTrait "engineer"}) && !(isNil {player getVariable "ACE_isEngineer"})) then {
    switch (player getVariable "ACE_isEngineer") do {
        case 1: { _abilityEngineer = " <font color='#addde6'>engineer</font> training" };
        case 2: { _abilityEngineer = " <font color='#addde6'>advanced engineer</font> training" };
        default { _abilityEngineer = "" };
    };
};
private _ability = "";
if (_abilityMedic != "" || _abilityEngineer != "") then {
    private _separateMedicEngineer = if ( (_abilityEngineer == "") && (_abilityMedic == "") ) then { ", " } else {""};
    _ability = formatText["You have%1%2%3.<br/><br/>", _abilityMedic, _separateMedicEngineer, _abilityEngineer];
};

private _document = format [
"<font size=20>Information</font><br/>Welcome to %1 on %2.<br/>Your currently on <font color='#addde6'>%3</font>.<br/><br/>
You're currently slotted in as <font color='#addde6'>%4</font> %5.<br/><br/>
%6
Good luck and have fun!
<br/><br/>
-----------------------------------------------------------------
", briefingName, _worldName, _serverName, _playerRole, _playerGroup, _ability];

player createDiaryRecord["Player Information", ["Player Information", _document]];