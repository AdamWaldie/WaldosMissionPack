/*
Author: Waldo
This function takes available ACRE information and documents it in a CEOI for the player to referance.
Covered:
- All LR channels and their dennotation
- Highlighting of LR channels if the players squad is noted as supposed to be on that net.
- AN/PRC-343 Block & Channel for the squad that the player is in.
- Babel Languages spoken in this "Area"

Arguments:
_LRAssignments - from init.sqd via ACRE2Init.sqf - contains player squad LR channels from init.sqf ONLY.
_SquadCallsigns - from ACRE2Init.sqf - contains a list of callsigns only

Returns:
N/A

Example:

Should only really be called from ACRE2Init.sqf
[[1,5,7],["Viking-1","Viking-2"]] call Waldo_fnc_CreateACRECEOI;

*/
params["_LRAssignments","_SquadCallsigns"];

//Inital Text
private _CEOIText = "<font size='16'>Communications Electronics Operating Instructions</font><br/><font color='#47ff47'>Green</font> highlight is used to mark a channel to which you are assigned.<br/><br/>";


// I hate that I'm doing it this way but I do not have the energy or time to change my implementation at the moment so this isnt nessicary
// Gets side specific group callsigns for CEOI per side
_westSquads = [];
_eastSquads = [];
_independentSquads = [];
_arrayCivSide = [];

{
    private _group = _x;
    if (((groupId _group)) in _SquadCallsigns) then {
        switch (side _group) do {
            case west: {
                _westSquads pushBackUnique (groupId _group);
            };
            case east: {
                _eastSquads pushBackUnique (groupId _group);
            };
            case independent: {
                _independentSquads pushBackUnique (groupId _group);
            };
            case civilian: {
                _arrayCivSide pushBackUnique (groupId _group);
            };
        };
    };
} forEach allGroups;

//Get player group
_playerGroup = groupId (group player);


_SRChannelAssignments = missionNamespace getVariable ["Waldo_ACRE2Setup_CallsignChannelAssignments","FAIL"];

private _SRChannelText = "<font size='14'>Squad Radio Assignments:</font><br/><br/>";

if (missionNamespace getVariable ["Waldo_ACRE2Setup_CallsignChannelAssignments_flag",false]) then {
	switch (side player) do {
		case west: {
			{
				_sideCallsign = _x;
				{
					if (_sideCallsign == (_x select 0)) then {
						_SrChannel = [(_x select 1)] call  Waldo_fnc_GetSRChannelName;
						if (toUpper (_playerGroup) == toUpper (_sideCallsign)) then {
							_SRChannelText =  _SRChannelText + format ["<font color='#47ff47'>%1 - %2</font><br/>",_SrChannel, _sideCallsign];
						} else {
							_SRChannelText =  _SRChannelText + format ["%1 - %2<br/>",_SrChannel, _sideCallsign];
						};
					};
				} foreach _SRChannelAssignments;
			} foreach _westSquads;
		};
		case east: {
			{
				_sideCallsign = _x;
				{
					if (_sideCallsign == (_x select 0)) then {
						_SrChannel = [(_x select 1)] call  Waldo_fnc_GetSRChannelName;
						if (toUpper (_playerGroup) == toUpper (_sideCallsign)) then {
							_SRChannelText =  _SRChannelText + format ["<font color='#47ff47'>%1 - %2</font><br/>",_SrChannel, _sideCallsign];
						} else {
							_SRChannelText =  _SRChannelText + format ["%1 - %2<br/>",_SrChannel, _sideCallsign];
						};
					};
				} foreach _SRChannelAssignments;
			} foreach _eastSquads;
		};
		case independent: {
			{
				_sideCallsign = _x;
				{
					if (_sideCallsign == (_x select 0)) then {
						_SrChannel = [(_x select 1)] call  Waldo_fnc_GetSRChannelName;
						if (toUpper (_playerGroup) == toUpper (_sideCallsign)) then {
							_SRChannelText =  _SRChannelText + format ["<font color='#47ff47'>%1 - %2</font><br/>",_SrChannel, _sideCallsign];
						} else {
							_SRChannelText =  _SRChannelText + format ["%1 - %2<br/>",_SrChannel, _sideCallsign];
						};
					};
				} foreach _SRChannelAssignments;
			} foreach _independentSquads;
		};
		default {
			{
				_sideCallsign = _x;
				{
					if (_sideCallsign == (_x select 0)) then {
						_SrChannel = [(_x select 1)] call  Waldo_fnc_GetSRChannelName;
						if (toUpper (_playerGroup) == toUpper (_sideCallsign)) then {
							_SRChannelText =  _SRChannelText + format ["<font color='#47ff47'>%1 - %2</font><br/>",_SrChannel, _sideCallsign];
						} else {
							_SRChannelText =  _SRChannelText + format ["%1 - %2<br/>",_SrChannel, _sideCallsign];
						};
					};
				} foreach _SRChannelAssignments;
			} foreach _arrayCivSide;
		};
	};
} else {
	_SRChannelText = _SRChannelText + format["SR Radio Assignments have failed, or a different radio is being utilised.<br/><br/>"]
};

//Add SR Text onto CEOI
_CEOIText = _CEOIText + _SRChannelText;


_LRChannelText = "<br/><br/><font size='14'>Long Range Radio Assignments:</font><br/><br/>";

_lrChannelNames = missionNamespace getVariable ["Waldo_ACRE2Setup_lrChannelNames_CIV", ["PLATOON 1","PLATOON 2","PLATOON 3","COMPANY","AIR 2 GROUND","AIR 2 AIR","CAS 1","CAS 2","CFF 1","CFF 2","CONVOY 1"]];

switch (side player) do {
	case west: {
		_lrChannelNames = missionNamespace getVariable ["Waldo_ACRE2Setup_lrChannelNames_BLUFOR", ["PLATOON 1","PLATOON 2","PLATOON 3","COMPANY","AIR 2 GROUND","AIR 2 AIR","CAS 1","CAS 2","CFF 1","CFF 2","CONVOY 1"]];
	};
	case east: {
		_lrChannelNames = missionNamespace getVariable ["Waldo_ACRE2Setup_lrChannelNames_OPFOR", ["PLATOON 1","PLATOON 2","PLATOON 3","COMPANY","AIR 2 GROUND","AIR 2 AIR","CAS 1","CAS 2","CFF 1","CFF 2","CONVOY 1"]];
	};
	case independent: {
		_lrChannelNames = missionNamespace getVariable ["Waldo_ACRE2Setup_lrChannelNames_IND", ["PLATOON 1","PLATOON 2","PLATOON 3","COMPANY","AIR 2 GROUND","AIR 2 AIR","CAS 1","CAS 2","CFF 1","CFF 2","CONVOY 1"]];
	};
	default {
		_lrChannelNames = missionNamespace getVariable ["Waldo_ACRE2Setup_lrChannelNames_CIV", ["PLATOON 1","PLATOON 2","PLATOON 3","COMPANY","AIR 2 GROUND","AIR 2 AIR","CAS 1","CAS 2","CFF 1","CFF 2","CONVOY 1"]];
	};
};

{
	_ChannelNumber = _foreachIndex+1;
	if ((_LRAssignments find _ChannelNumber) != -1) then {
		_LRChannelText =  _LRChannelText + format ["<font color='#47ff47'>Channel %1: %2</font><br/>",_ChannelNumber,_x];
	} else {
		_LRChannelText =  _LRChannelText + format ["Channel %1: %2<br/>",_ChannelNumber,_x];
	};
} foreach _lrChannelNames;

//Add LR Section
_CEOIText = _CEOIText + _LRChannelText;

_SACs = format ["<br/><font size='16'>Challenges And Contingencies:</font><br/><br/>Challenges and Responses:<br/>    CHALLENGE - FLASH<br/>    RESPONSE - THUNDER<br/><br/>Night Recognition Signal:<br/>    1.Any Three Crossed or grouped lasers/IRs.<br/>    2. Single Green Flare Above Or On Player Unit.<br/><br/>Lines of Communicaion:<br/>    1. Standard Channels<br/>    2. Continency Channels (+10 to all)<br/>    3. Runners and Prearranged signals<br/>"];

_CEOIText = _CEOIText + _SACs;

_SOC = format ["<br/><font size='16'>Succession Of Command:</font><br/>    1. Platoon Leader<br/>    2. Platoon Sergeant<br/>    3. 1st Squad Leader<br/>    4. 2nd Squad Leader<br/>    5. Highest Surviving Leadership"];

_CEOIText = _CEOIText + _SOC;

//Create Records
player createDiarySubject ["ACRE2","ACRE2"];
player createDiaryRecord ["ACRE2", ["CEOI", _CEOIText]];
