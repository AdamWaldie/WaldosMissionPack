/*
Author: Waldo

Description: 
The script activates the Babel system in Arma 3 with Advanced Combat Radio Environment 2 (ACRE2). It sets up the languages spoken by different sides and defines the languages spoken by interpreters. It adds all the necessary languages to the ACRE2 Babel system, assigns them to the respective units based on the side they belong to, and creates a diary record with a list of languages spoken in the area, highlighting the ones the player can speak.

Arguments:
_languages - An array of sub-arrays. Each sub-array contains a side (West, East, Independent, Civilian) and the languages they speak as strings. 
_interpreters - An array of units that are interpreters. These units can speak all languages.

Returns:
N/A. The script operates by side effect, creating diary records and setting up the ACRE2 Babel system.

Example:
[
    [
        [West, "English","French"],
        [East, "Chinese"],
        [independent, "Altian"],
        [civilian, "Altian"]
    ],
    [unit, unit2]
] call Waldo_fnc_BabelActivation;
*/

params ["_languages",["_interpreters",[ ]]];

waitUntil {[] call acre_api_fnc_isInitialized};

private _BabelText = "<font size='16'>Languages Spoken In Area:</font><br/>I can speak any languages that are highlighted in <font color='#47ff47'>green</font><br/><br/>";

_interpreterLangs = [];
_spokenText = "";

{
    private _langs = _x select [1, count _x - 1];
    {
		_curLangId = [_x,0,2] call BIS_fnc_trimString;
        [_curLangId, _x] call acre_api_fnc_babelAddLanguageType;
    } forEach _langs;

    // Set player's spoken languages if they're on this side

	if (_interpreters find player != -1) then {
		{
			if (_interpreterLangs find _x == -1) then {
				_spokenText =  _spokenText + format ["<font color='#47ff47'>%1</font><br/>",_x];
			};
		} foreach _langs;
		_interpreterLangs pushBackUnique _langs;
	} else {
		if (side player == (_x select 0)) then {
			_langs call acre_api_fnc_babelSetSpokenLanguages;
			{
				if (_interpreterLangs find _x == -1) then {
					_spokenText =  _spokenText + format ["<font color='#47ff47'>%1</font><br/>",_x];
				};
			} foreach _langs;
			_interpreterLangs pushBackUnique _langs;
		} else {
			{
				if (_interpreterLangs find _x == -1) then {
					_spokenText =  _spokenText + format ["%1<br/>",_x];
				};
			} foreach _langs;
			_interpreterLangs pushBackUnique _langs;
		};
	};
} forEach _languages;

if (_interpreters find player != -1) then {
	_interpreterLangs call acre_api_fnc_babelSetSpokenLanguages;
	_spokenText = _spokenText + format["%1<br/>","I am an Interpreter, That means can speak all languages.<br/> Press the ACRE cycle language key to cycle through available languages.<br/>"];
};

_BabelText = _BabelText + _spokenText;


//Create Records
player createDiarySubject ["CEOI","CEOI"];
player createDiaryRecord ["CEOI", ["BABEL", _BabelText]];