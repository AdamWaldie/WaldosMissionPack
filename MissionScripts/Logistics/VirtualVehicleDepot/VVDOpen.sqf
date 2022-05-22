#include "\A3\ui_f\hpp\defineDIKCodes.inc"
#include "\A3\Ui_f\hpp\defineResinclDesign.inc"

#include "VVDIDC.inc"

disableSerialization;
params["_depotSpawnPoint", "_types", ["_limitToSideVehicles",false], ["_removeUAVs",false]];

fnc_Garage_load = {
	//If already the window open, close it by "Cancel"
	if !(isNull(uiNamespace getVariable [ "Garage_Display_Loadout", displayNull ])) then
	{
		_display = uiNamespace getVariable "Garage_Display_Loadout";
		_display closeDisplay 1;
	};

	_depotSpawnPoint = _this select 0;
	_depotSpawnPointName = vehicleVarName _depotSpawnPoint;
	_pos = (getPosASL _depotSpawnPoint) vectorAdd [0,0,0.5];
	_dir = getDir _depotSpawnPoint;

	_types = _this select 1;
	_limitToSideVehicles  = _this select 2;
	_removeUAVs = _this select 3;

	_existCount = 0;
	_allVehicles = nearestObjects [ ASLToAGL _pos, [ "AllVehicles" ], 20 ];
	{
	  if !(_x isKindOf "Man") then
	  {
	    _existCount = _existCount + 1;
	  };
	} forEach _allVehicles;

	if (_existCount > 0) exitwith
	{
	  ["Vehicles Occupy The Spawn Area"] call BIS_fnc_guiMessage;
	};

	//If someone open garage in same place, warn and exit.
	if (missionNamespace getVariable [format["Open_Garage_%1", _depotSpawnPointName], false]) exitwith
	{
		["This Virtual Depot Is Already In Use"] call BIS_fnc_guiMessage;
	};
	missionNamespace setVariable [format["Open_Garage_%1", _depotSpawnPointName], true, true];

	_helipad = createVehicle [ "Land_HelipadEmpty_F", _pos, [], 0, "CAN_COLLIDE" ];
	missionNamespace setVariable [ "BIS_fnc_arsenal_fullGarage", [ true, 0, false, [ false ] ] call bis_fnc_param ];
	with missionNamespace do { BIS_fnc_garage_center = [ true, 1, _helipad, [ objNull ] ] call bis_fnc_param; };
	missionNameSpace setVariable ["Garage_Vehicle", objNull];
	missionNameSpace setVariable ["Garage_Spawn_Flag", false];

	_display = (findDisplay 46) createDisplay "GarageLoadDisplay";
	uiNamespace setVariable ["Garage_Display_Loadout", _display];

	//Spawn type
	if(isNil "Garage_SpawnType") then {
		missionNamespace setVariable ["Garage_SpawnType", 0];
	};

	_ctrlMouseArea = _display displayctrl IDC_RSCDISPLAYARSENAL_MOUSEAREA;
	_ctrlMouseArea ctrladdeventhandler ["mousebuttonclick","
		call sel_toggleShown;
	"];
	_ctrlButtonInterface = _display displayctrl IDC_RSCDISPLAYARSENAL_CONTROLSBAR_BUTTONINTERFACE;
	_ctrlButtonInterface ctrladdeventhandler ["buttonclick","
		call sel_toggleShown;
	"];

	//Wait until garage is ready.
	waitUntil {!isNull (missionnamespace getvariable ["BIS_fnc_arsenal_center", objNull])};
	waitUntil {(missionnamespace getvariable "BIS_fnc_arsenal_center") != _helipad};

	_centerVeh = missionnamespace getvariable "BIS_fnc_arsenal_center";

	//Convert types to corresponding number and check vehicle type.
	_fitNum = 0;
	_typeNums = [];
	{
		if (_x == "Car") then { _typeNums set [_forEachIndex, 0]; };
		if (_x == "Tank") then { _typeNums set [_forEachIndex, 1]; };
		if (_x == "Helicopter") then { _typeNums set [_forEachIndex, 2]; };
		if (_x == "Plane") then { _typeNums set [_forEachIndex, 3]; };
		if (_x == "Ship") then { _typeNums set [_forEachIndex, 4]; };
		if (_x == "StaticWeapon") then { _typeNums set [_forEachIndex, 5]; };
		if (_centerVeh isKindOf _x) then {
			_fitNum = _fitNum + 1;
		};
	} forEach _types;

	//Select vehicle random following types.
	if (_fitNum == 0) then {
		{
			if !("Logic" in (_x call BIS_fnc_objectType)) then {
				deleteVehicle _x;
			};
		} forEach (attachedObjects _centerVeh);
		[_typeNums] call sel_random;
	};

	_console = [_pos, _dir, _typeNums,_limitToSideVehicles,_removeUAVs] spawn set_dlconsole;

	waitUntil {isNull _display || !alive player};

	{
		_x ctrlRemoveAllEventHandlers "LBSelChanged";
		_x ctrlRemoveAllEventHandlers "CheckedChanged";
		_x ctrlRemoveAllEventHandlers "ButtonClick";
		ctrlDelete _x;
	} forEach Garage_Loadout_Controls;

	terminate _console;

	deleteVehicle _helipad;

	_veh = missionNamespace getVariable "BIS_fnc_garage_center";

	//If pushed spawn button, call createVehicle. If not, delete it.
	if((missionNamespace getVariable "Garage_Spawn_Flag") && (alive player)) then {
		[_depotSpawnPoint] call fnc_Garage_CreateVehicle;
	} else {
		{
			_veh deleteVehicleCrew _x;
		} forEach (crew _veh);
		{
			deleteVehicle _x;
		} forEach (attachedObjects _veh);
		deleteVehicle _veh;
	};

	if(!alive player) then {
		_display = uiNamespace getVariable "Garage_Display_Loadout";
		_display closeDisplay 1;
	};

	missionNamespace setVariable [format["Open_Garage_%1", _depotSpawnPointName], false, true];
};

set_dlconsole = {
	params["_pos", "_dir", "_typeNums","_sideLimit","_UAVRemoval"];
	_display = uiNamespace getVariable "Garage_Display_Loadout";

	//Make Insignia Data
	if(isNil "GarageInsigniaData") then {
		_insigniaCFG = "true" configClasses (configFile >> "CfgUnitInsignia");
		_insigniaData = [[],[]]; //[[Names], [Tex]]
		{
			_insigniaName = getText (_x >> "displayName");
			_insigniaTex = getText (_x >> "texture");
			(_insigniaData select 0) pushBack _insigniaName;
			(_insigniaData select 1) pushBack _insigniaTex;
		} forEach _insigniaCFG;
		missionNameSpace setVariable ["GarageInsigniaData", _insigniaData];
	};
	//systemChat str GarageInsigniaData;

	_attachedObj = [];

	while {true} do {
		sleep 0.1;

		//Don't show unneccessary ctrls.
		{
			(_display displayCtrl (930+_x)) ctrlShow false;
		} forEach ([0,1,2,3,4,5] - _typeNums);

		//If change vehicle selection, it will be executed.
		if ((missionNameSpace getVariable "BIS_fnc_arsenal_center") != (missionNameSpace getVariable "Garage_Vehicle")) then
		{
			//Attached obj can't delete in changing garage selection, so delete them here.
			{
				if !("Logic" in (_x call BIS_fnc_objectType)) then {
					deleteVehicle _x;
				};
			} forEach _attachedObj;

			_veh = missionNameSpace getVariable "BIS_fnc_arsenal_center";
			_typeVeh = typeOf _veh;
			_veh setPosASL _pos;
			_veh setDir _dir;
			missionNameSpace setVariable ["Garage_Vehicle", _veh];

			_attachedObj = attachedObjects _veh;

			{
				_x ctrlRemoveAllEventHandlers "LBSelChanged";
				_x ctrlRemoveAllEventHandlers "CheckedChanged";
				_x ctrlRemoveAllEventHandlers "ButtonClick";
				ctrlDelete _x;
			} forEach (missionNameSpace getVariable ["Garage_Loadout_Controls", []]);
			missionNameSpace setVariable ["Garage_Loadout_Controls", []];

			_ctrls = [];

			//Setting stats ctrls
			_modPic = _display displayctrl IDC_GARAGEDISPLAY_STATS_MODPIC;
			_addons = configSourceAddonList (configFile >> "CfgVehicles" >> _typeVeh);
			_modPicText = "a3\ui_f\data\logos\arma3_white_ca.paa";
			if (count _addons > 0) then {
				_dlcs = configSourceModList (configfile >> "CfgPatches" >> _addons select 0);
				if (count _dlcs > 0) then {
					private _dlcName = _dlcs select 0;
					if (_dlcName != "") then {
						_modPicText = (modParams [_dlcName,["logo"]]) param [0,""];
					}else{
						_modPicText = getText ((configfile >> "cfgMods" >> getText (configFile >> "CfgVehicles" >> _typeVeh >> "dlc")) >> "logo");
					};
				};
			};
			_modPic ctrlSetText _modPicText;

			_statsExtremes = uinamespace getVariable "BIS_fnc_garage_stats";
			if !(isnil "_statsExtremes") then {
				_barMin = 0.01;
				_barMax = 1;

				_statsMin = _statsExtremes select 0;
				_statsMax = _statsExtremes select 1;

				_stats = [[configfile >> "cfgvehicles" >> _typeVeh],	["maxspeed","armor"], [false,true], _statsMin] call BIS_fnc_configExtremes;
				_stats = _stats select 1;
				_statMaxSpeed = linearConversion [_statsMin select 0,_statsMax select 0,_stats select 0,_barMin,_barMax];
				_statArmor = linearConversion [_statsMin select 1,_statsMax select 1,_stats select 1,_barMin,_barMax];

				_ctrlMaxspeed = _display displayctrl IDC_GARAGEDISPLAY_STATS_MAXSPD;
				_ctrlMaxspeed progressSetPosition _statMaxSpeed;

				_ctrlArmor = _display displayctrl IDC_GARAGEDISPLAY_STATS_ARMOR;
				_ctrlArmor progressSetPosition _statArmor;
			};

			//Spawn button
			_useList = [];

			_vehicleList = [];
			{
				_vehicleList set [_forEachIndex, toLower _x];
			} forEach (_useList);

			//test: true => disabled
			_vehFindNum = _vehicleList find (toLower _typeVeh); //Check List

			_vehicleSide = (getNumber (configfile >> "cfgvehicles" >> _typeVeh >> "side")) call BIS_fnc_sideType;
			_testSide = _sideLimit && (side player != _vehicleSide) && ([civilian, resistance, sideUnknown, sideFriendly] find _vehicleSide == -1);
			_testUAV = ("VehicleAutonomous" in (_typeVeh call BIS_fnc_objectType)) && _UAVRemoval;

			_spawnEnable = true;
			_ctrlSpawnButton = _display displayctrl IDC_GARAGEDISPLAY_SPAWNBUTTON;
			if (_testSide || _testUAV) then {
				_ctrlSpawnButton ctrlEnable false;
				_ctrlSpawnButton ctrlSetTooltip "Spawn is Disabled!";
				_spawnEnable = false;
			} else {
				_ctrlSpawnButton ctrlEnable true;
				_ctrlSpawnButton ctrlSetTooltip "Ready?";
			};

			if (_spawnEnable) then {
				//Setting display group.
				_settingGroup = _display ctrlCreate ["GarageSettingGroup", IDC_GARAGEDISPLAY_SETTINGGROUP];
				_ctrls pushBack _settingGroup;

				_pylonGroup = _display displayctrl IDC_GARAGEDISPLAY_PYLON_GROUP;
				_optionGroup = _display displayctrl IDC_GARAGEDISPLAY_OPTION_GROUP;
				_optionToggleButton = _display displayCtrl IDC_GARAGEDISPLAY_OPTION_TOGGLE;

				//Setting Pylon
				if (isText(configFile >> "CfgVehicles" >> _typeVeh >> "Components" >> "TransportPylonsComponent" >> "uiPicture")) then
				{
					//Setting console
					_settingShown = [true, true, false];
					missionNameSpace setVariable ["GarageSettingShown", _settingShown];
					{
						_show = _settingShown select (_forEachIndex + 1);
						_x ctrlSetFade ([1,0] select _show);
						_x ctrlCommit 0;
						_x ctrlShow _show;
					} forEach [_pylonGroup, _optionGroup];
					//Enable toggle button.
					_optionToggleButton ctrlEnable true;
					_optionToggleButton ctrlSetTooltip "Change display";

					_pylons = (configProperties [configFile >> "CfgVehicles" >> _typeVeh >> "Components" >> "TransportPylonsComponent" >> "Pylons", "isClass _x"]) apply {configName _x};
					_countPylons = count _pylons;

					if (isNil (format ["Garage_Loadout_%1", _typeVeh])) then
					{
						missionNamespace setVariable [format ["Garage_Loadout_%1", _typeVeh], getPylonMagazines _veh];
					};
					_last_loadout = missionNamespace getVariable (format ["Garage_Loadout_%1", _typeVeh]);

					/*if (isNil (format ["Garage_Turret_%1", _typeVeh])) then
					{
						_magTurret = [];
						{
							_magTurret pushBack getArray(configfile >> "CfgVehicles" >> _typeVeh >> "Components" >> "TransportPylonsComponent" >> "Pylons" >> _x >> "turret");
						} forEach _pylons;
						missionNamespace setVariable [format ["Garage_Turret_%1", _typeVeh], _magTurret];
					};
					_last_turret = missionNamespace getVariable (format ["Garage_Turret_%1", _typeVeh]);
*/
					_last_turret = [];
					if (count allTurrets [_veh, false] > 0) then {
						if (isNil (format ["Garage_Turret_%1", _typeVeh])) then {
							_magTurret = [];
							{
								_magTurret pushBack getArray(configfile >> "CfgVehicles" >> _typeVeh >> "Components" >> "TransportPylonsComponent" >> "Pylons" >> _x >> "turret");
							} forEach _pylons;
							missionNamespace setVariable [format ["Garage_Turret_%1", _typeVeh], _magTurret];
						};
						_last_turret = missionNamespace getVariable (format ["Garage_Turret_%1", _typeVeh]);
					};
					//systemChat str [format ["Garage_Turret_%1", _typeVeh], isNil (format ["Garage_Turret_%1", _typeVeh])];

					_last_preset = missionNamespace getVariable [format ["Pylons_Preset_%1", _typeVeh], 0];

					_pylonGroupPos = ctrlPosition _pylonGroup;
					_pylonGroupSize_x = _pylonGroupPos select 2;
					_pylonGroupSize_y = _pylonGroupPos select 3;

					//Pylons setting ctrls
					_ctrlpic = _display displayctrl IDC_GARAGEDISPLAY_PYLON_UIPIC;
					_textIMG = getText(configFile >> "CfgVehicles" >> _typeVeh >> "Components" >> "TransportPylonsComponent" >> "uiPicture");
					_ctrlpic ctrlSetText _textIMG;

					_height = ((((safezoneW / safezoneH) min 1.2) / 1.2) / 25)*0.9; //GUI_GRID_H*0.9

					_ctrl_preset = _display displayctrl IDC_GARAGEDISPLAY_PYLON_PRESET;
					_ctrl_mirror = _display displayctrl IDC_GARAGEDISPLAY_PYLON_MIRROR;

					//Preset
					_presetsCFG = "true" configClasses (configfile >> "CfgVehicles" >> _typeVeh >> "Components" >> "TransportPylonsComponent" >> "presets");
					_preset = [];
					if(_last_preset > 0) then
					{
						_preset = getArray((_presetsCFG select (_last_preset-1)) >> "attachment");
					};

					{
						_ctrl_preset lbAdd getText(_x >> "displayName");
					} forEach _presetsCFG;
					_ctrl_preset lbSetCurSel _last_preset;

					//If change preset, change pylon loadouts.
					_ctrl_preset ctrlAddEventHandler ["LBSelChanged",{
						[] call fnc_preset_change;
					}];

					//Mirror settings
					_ctrl_mirror cbSetChecked false;
					_ctrl_mirror ctrlAddEventHandler ["CheckedChanged", {
						[] call fnc_pylon_mirror;
					}];

					//Pylons' ctrls
					_i = 0;
					while{_i < _countPylons} do
					{
						_ctrl = _display ctrlCreate ["GaragePylons", IDC_GARAGEDISPLAY_PYLON_WEAPON+_i, _pylonGroup];
						_ctrl ctrlSetTooltip (_pylons select _i);

						_offset = getArray (configfile >> "CfgVehicles" >> _typeVeh >> "Components" >> "TransportPylonsComponent" >> "pylons" >> (_pylons select _i) >> "UIposition");
						_offset_final = [0,0];
						_break = 0;
						{
							if(_x isEqualType "") then
							{
								_offset_final set [_forEachIndex, call (compile _x)];
							};
							if (_x isEqualType 0) then
							{
								_offset_final set [_forEachIndex, _x];
							};
							if(_offset_final select _forEachIndex > 1) then
							{
								_break = _break + 1;
							};
						} forEach _offset;

						//If inside of box, continue. If out of box, delete ctrl.
						if (_break == 0) then
						{
							_pos_offset = [0, _pylonGroupSize_y*0.07];

							_pos_x = _pylonGroupSize_x * (_offset_final select 0) / 0.87 + (_pos_offset select 0);
							_pos_y = _pylonGroupSize_y*0.93 * (_offset_final select 1) / 0.614 + (_pos_offset select 1);
							_ctrl ctrlSetPosition [_pos_x,_pos_y];
							_ctrl ctrlCommit 0;

							_ctrls pushBack _ctrl;

							if (count allTurrets [_veh, false] > 0) then
							{
								_turret = [];
								_ctrl_turret = _display ctrlCreate ["GaragePylonTurrets", IDC_GARAGEDISPLAY_PYLON_MIRROR+_i, _pylonGroup];
								_ctrl_turret ctrlSetPosition [_pos_x-_height,_pos_y];
								_ctrl_turret ctrlCommit 0;

								if (count (_last_turret select _i) == 0) then
								{
									_ctrl_turret ctrlSetText "a3\ui_f\data\IGUI\RscIngameUI\RscUnitInfo\role_driver_ca.paa";
									_ctrl_turret ctrlSetTooltip localize "str_driver";
								} else {
									_ctrl_turret ctrlSetText "a3\ui_f\data\IGUI\RscIngameUI\RscUnitInfo\role_gunner_ca.paa";
									_ctrl_turret ctrlSetTooltip localize "str_gunner";
									_turret = [0];
								};
								_ctrl_turret setVariable ["Owner", _turret];
								_ctrls pushBack _ctrl_turret;

								_ctrl_turret ctrlAddEventHandler ["ButtonClick", {
									[_this select 0] call fnc_toggle_turret;
								}];
							};

							_veh animateBay [_i, 1];

							//Set last loadout
							if(_last_preset == 0) then
							{
								if(!isNil "_last_loadout") then {
									_veh setPylonLoadOut [_i+1, _last_loadout select _i,true];
								};
							} else {
								if ((count _preset) != 0 && (count _preset) >= _i) then {
									_veh setPylonLoadOut [_i+1, _preset select _i,true];
								} else {
									_veh setPylonLoadOut [_i+1, "",true];
								};
							};

							//Insert weapon to the list, and select current weapon.
							_current_wep = (getPylonMagazines _veh) select _i;
							_magList = ["None"]; //empty pylon
							_magList append (_veh getCompatiblePylonMagazines (_pylons select _i));
							_selected = 0;
							{
								_magName = if (_forEachIndex == 0) then {
									"<empty>";
								} else {
									getText(configFile >> "CfgMagazines" >> _x >> "displayName");
								};
								_ctrl lbAdd _magName;
								_ctrl lbSetData [_forEachIndex, format["%1^%2", _x, _i]];

								_toolTip = getText(configFile >> "CfgMagazines" >> _x >> "descriptionShort");
								if (_toolTip != "") then
								{
									_ctrl lbSetTooltip [_forEachIndex, _toolTip];
								};

								if(_current_wep == _x) then {
									_selected = _forEachIndex;
								};
							} forEach _magList;
							_ctrl lbSetCurSel _selected;

							//When a pylon weapon change, model's pylon weapon change.
							_ctrl ctrlAddEventHandler ["LBSelChanged",{
								[_this select 0, _this select 1] call sel_weapon;
							}];
						} else {
							ctrlDelete _ctrl;
						};

						_i = _i + 1;
					};
				} else {
					//[Garage, Pylon, Option]
					_settingShown = [true, false, true];
					missionNameSpace setVariable ["GarageSettingShown", _settingShown];
					{
						_show = _settingShown select (_forEachIndex + 1);
						_x ctrlSetFade ([1,0] select _show);
						_x ctrlCommit 0;
						_x ctrlShow _show;
					} forEach [_pylonGroup, _optionGroup];
					//Disable toggle button.
					_optionToggleButton ctrlEnable false;
					_optionToggleButton ctrlSetTooltip "No Pylon!";
				};

				//Setting damages
				_allHitpoints = getAllHitPointsDamage _veh;
				_damageList = _display displayctrl IDC_GARAGEDISPLAY_DAMAGE_LIST;
				//Some vehicle have no hitpoints, so branching.
				if ((count _allHitpoints) != 0) then {
					_damageList ctrlEnable true;
					_hitpointNames = _allHitpoints select 0;
					/*if (isNil (format ["Garage_Damage_%1", _typeVeh])) then {
						missionNamespace setVariable [format ["Garage_Damage_%1", _typeVeh], _allHitpoints select 2];
					};*/
					_hitpointsDamage = missionNamespace getVariable [format ["Garage_Damage_%1", _typeVeh], _allHitpoints select 2];

					_i = 0;
					{
						if (_x find "#" == -1) then {
							_damage = (_hitpointsDamage select _forEachIndex) * 100;
							_damageList lnbAddRow [_x, format["%1%2", _damage, "%"]];
							_damageList lnbSetValue [[_i, 0], _forEachIndex];
							_damageList lnbSetValue [[_i, 1], _damage];
							_i = _i + 1;
						};
					} forEach _hitpointNames;

					_damageList lnbSetCurSelRow 0;
				} else {
					_damageList lnbAddRow ["None", format["---%1", "%"]];
					_damageList lnbSetValue [[0, 1], -1];
					_damageList ctrlEnable false;
				};

				//Damage delay set
				/*if (isNil (format ["Garage_DamageDelay_%1", _typeVeh])) then {
					missionNamespace setVariable [format ["Garage_DamageDelay_%1", _typeVeh], [0,0]];
				};*/
				_damageDelays = missionNameSpace getVariable [format ["Garage_DamageDelay_%1", _typeVeh], [0,0]];
				(_display displayctrl IDC_GARAGEDISPLAY_DAMAGE_DELAY_MIN) ctrlSetText (str (_damageDelays select 0));
				(_display displayctrl IDC_GARAGEDISPLAY_DAMAGE_DELAY_MAX) ctrlSetText (str (_damageDelays select 1));

				//Setting Insignia
				_insigniaPointList = _display displayctrl IDC_GARAGEDISPLAY_INSIGNIA_POINT;
				_insigniaTexList = _display displayctrl IDC_GARAGEDISPLAY_INSIGNIA_TEX;
				_ctrls append [_insigniaPointList, _insigniaTexList];

				_insigniaData = missionNameSpace getVariable "GarageInsigniaData";
				_hiddenSelections = getArray (configfile >> "CfgVehicles" >> _typeVeh >> "hiddenSelections");

				_insigniaPos = ["insignia", "decal_nose", "decal_wing", "decal_tail", "front_logo", "tail_logo"]; //Maybe FIR or USAF only
				_insigniaSelectExist = !isNil (format ["Garage_Insignia_%1", _typeVeh]);

				_insigniaPoint = [];
				_insigniaTexSelect = [];
				_hiddenIndex = [];

				_i = 0;
				{
					if ((_insigniaPos find (toLower _x)) != -1) then {
						_selectedTex = if (_insigniaSelectExist) then {
							_insigniaSelect = missionNameSpace getVariable (format ["Garage_Insignia_%1", _typeVeh]);
							(_insigniaSelect select 1) select _i;
						} else {
							0;
						};

						_insigniaPoint pushBack _x;
						_insigniaTexSelect pushBack _selectedTex;
						_hiddenIndex pushBack _forEachIndex;

						_i = _i + 1;
					};
				} forEach _hiddenSelections;

				if (_i == 0) then {
					_insigniaPointList ctrlEnable false;
					_insigniaTexList ctrlEnable false;

					_insigniaPointList lbAdd "None";
					_insigniaTexList lbAdd "None";
				} else {
					_insigniaPointList ctrlEnable true;
					_insigniaTexList ctrlEnable true;

					_insigniaTexList lbAdd "Default";

					_insigniaData = missionNameSpace getVariable "GarageInsigniaData";

					{
						_insigniaTexList lbAdd _x;
						_insigniaTexList lbSetPicture [_forEachIndex + 1, (_insigniaData select 1) select _forEachIndex];
					} forEach (_insigniaData select 0);

					_hiddenSelectionsTextures = getArray (configfile >> "CfgVehicles" >> _typeVeh >> "hiddenSelectionsTextures");

					{
						_index = _hiddenIndex select _forEachIndex; //_hiddenSelections Index

						_insigniaPointList lbAdd _x;
						_insigniaPointList lbSetValue [_forEachIndex, _index];

						_defaultTex = if ((count _hiddenSelectionsTextures) >= (_index + 1)) then {
							_hiddenSelectionsTextures select _index;
						} else {
							"";
						};
						_insigniaPointList lbSetData [_forEachIndex, _defaultTex];

						_texSelectNum = _insigniaTexSelect select _forEachIndex;
						_objTex = if (_texSelectNum == 0) then {
							_defaultTex;
						} else {
							(_insigniaData select 1) select (_texSelectNum - 1);
						};

						_veh setObjectTextureGlobal [_index, _objTex];
					} forEach _insigniaPoint;

					_insigniaPointList lbSetCurSel 0;
					_insigniaTexList lbSetCurSel (_insigniaTexSelect select 0);

					if !(_insigniaSelectExist) then {
						missionNameSpace setVariable [format ["Garage_Insignia_%1", _typeVeh], [_insigniaPoint,_insigniaTexSelect]];
					};

					_insigniaPointList ctrlAddEventHandler ["LBSelChanged",{
						(_this select 1) call sel_insignia_depotSpawnPoint;
					}];
					_insigniaTexList ctrlAddEventHandler ["LBSelChanged",{
						(_this select 1) call sel_insignia_tex;
					}];
				};
			} else {
				missionNameSpace setVariable ["GarageSettingShown", [true, false, false]];
			};
			missionNameSpace setVariable ["Garage_Loadout_Controls", _ctrls];
		};
	};
};

sel_toggleShown = {
	_display = uiNamespace getVariable "Garage_Display_Loadout";

	_dummyBarGroup = _display displayctrl IDC_GARAGEDISPLAY_CONTROLBARDUMMY;
	_statsGroup = _display displayctrl IDC_GARAGEDISPLAY_STATS_GROUP;
	_settingGroup = _display displayctrl IDC_GARAGEDISPLAY_SETTINGGROUP;
	_pylonGroup = _display displayctrl IDC_GARAGEDISPLAY_PYLON_GROUP;
	_optionGroup = _display displayctrl IDC_GARAGEDISPLAY_OPTION_GROUP;

	_ctrls = [_dummyBarGroup, _statsGroup, _settingGroup, _pylonGroup, _optionGroup];

	_settingShown = missionNameSpace getVariable "GarageSettingShown";
	_garageShown = ctrlshown (_display displayctrl IDC_RSCDISPLAYARSENAL_CONTROLSBAR_CONTROLBAR);
	//Excute when display status change
	if ((str (_settingShown select 0)) != (str _garageShown)) then {
		if (_garageShown) then {
			_showns = [true, true, true, _settingShown select 1, _settingShown select 2];

			{
				if (_x != controlNull) then {
					_show = _showns select _forEachIndex;
					_x ctrlSetFade ([1,0] select _show);
					_x ctrlCommit 0;
					_x ctrlShow _show;
				};
			} forEach _ctrls;

			_settingShown set [0, true];
			missionNameSpace setVariable ["GarageSettingShown", _settingShown];
		} else {
			if (_settingGroup == controlNull) then {
				missionNameSpace setVariable ["GarageSettingShown", [false, false, false]];
			} else {
				missionNameSpace setVariable ["GarageSettingShown", [false, ctrlShown _pylonGroup, ctrlShown _optionGroup]];
			};

			{
				if (_x != controlNull) then {
					_x ctrlSetFade 0;
					_x ctrlCommit 0;
					_x ctrlShow false;
				};
			} forEach _ctrls;
		};
	};
};

sel_random = {
	_display = uiNamespace getVariable "Garage_Display_Loadout";
	_selNum = selectRandom (_this select 0);

	//--- Select random vehicle type
	for "_i" from 0 to 5 do {
		_ctrlList = _display displayctrl (960 + _i);
		_ctrlList lbSetCurSel -1;
	};

	//--- Select random item
	_ctrlLineicon = _display displayctrl 1803;
	waitUntil {!ctrlShown _ctrlLineicon}; //wait for loading lists.
	_ctrlList = _display displayctrl (960 + _selNum);
	_ctrlList lbSetCurSel (floor random ((lbSize _ctrlList) - 1));
};

sel_weapon = {
	//systemChat "Sel weapon";
	_ctrl = _this select 0;
	_index = lbCurSel _ctrl;
	_str = (_ctrl lbData _index) splitString "^";
	_pylon_index = parseNumber (_str select 1);

	[_pylon_index] call fnc_weapon_change;
};

sel_toggle_setting = {
	params["_ctrl"];
	_display = uiNamespace getVariable 'Garage_Display_Loadout';
	_IDC = ctrlIDC _ctrl;

	// [Pylon, Option]
	_showns = switch (_IDC) do {
		case IDC_GARAGEDISPLAY_PYLON_TOGGLE: { [false, true] }; //Pylon click
	  case IDC_GARAGEDISPLAY_OPTION_TOGGLE: { [true, false] }; //Option click
	};

	_pylonGroup = _display displayctrl IDC_GARAGEDISPLAY_PYLON_GROUP;
	_optionGroup = _display displayctrl IDC_GARAGEDISPLAY_OPTION_GROUP;
	{
		_show = _showns select _forEachIndex;
		_x ctrlSetFade ([1,0] select _show);
		_x ctrlCommit 0;
		_x ctrlShow _show;
	} forEach [_pylonGroup, _optionGroup];

	_settingShown = missionNameSpace getVariable "GarageSettingShown";
	_settingShown = [_settingShown select 0] + _showns;
	missionNameSpace setVariable ["GarageSettingShown", _settingShown];
};

sel_damage_arrow = {
	params["_damageArrow"];
	_display = uiNamespace getVariable 'Garage_Display_Loadout';
	_damageList = _display displayctrl IDC_GARAGEDISPLAY_DAMAGE_LIST;
	_currentSelect = lnbCurSelRow _damageList;
	_currentValue = _damageList lnbValue [_currentSelect, 1];
	//-: IDC_GARAGEDISPLAY_DAMAGE_LISTARROW_LEFT, +: IDC_GARAGEDISPLAY_DAMAGE_LISTARROW_RIGHT
	_newValue = [(_currentValue - 10) max 0, (_currentValue + 10) min 100] select ((ctrlIDC _damageArrow) - IDC_GARAGEDISPLAY_DAMAGE_LISTARROW_LEFT);

	_damageList lnbSetText [[_currentSelect, 1], format["%1%2", _newValue, "%"]];
	_damageList lnbSetValue [[_currentSelect, 1], _newValue];

	_veh = missionNameSpace getVariable "Garage_Vehicle";
	_typeVeh = typeOf _veh;
	//_hitpointsDamage = missionNameSpace getVariable (format ["Garage_Damage_%1", _typeVeh]);
	_hitpointsDamage = missionNamespace getVariable [format ["Garage_Damage_%1", _typeVeh], (getAllHitPointsDamage _veh) select 2];
	_hitpointIndex = _damageList lnbValue [_currentSelect, 0];
	_hitpointsDamage set [_hitpointIndex, _newValue/100];
	missionNameSpace setVariable [format ["Garage_Damage_%1", _typeVeh], _hitpointsDamage];
};

sel_damage_delay = {
	params["_damageDelay"];
	_display = uiNamespace getVariable 'Garage_Display_Loadout';

	_text = ctrlText _damageDelay;
	_value = parseNumber _text;
	//Change non numecal string to 0.
	if (count (_text splitString "0123456789") != 0) then {
		_damageDelay ctrlSetText "0";
		_value = 0;
	};

	_typeVeh = typeOf (missionNameSpace getVariable "Garage_Vehicle");
	//_damageDelays = missionNameSpace getVariable (format ["Garage_DamageDelay_%1", _typeVeh]);
	_damageDelays = missionNameSpace getVariable [format ["Garage_DamageDelay_%1", _typeVeh], [0,0]];
	_damageDelays set [(ctrlIDC _damageDelay) - IDC_GARAGEDISPLAY_DAMAGE_DELAY_MIN, _value]; //min: IDC_GARAGEDISPLAY_DAMAGE_DELAY_MIN, Max: IDC_GARAGEDISPLAY_DAMAGE_DELAY_MAX
	missionNameSpace setVariable [format ["Garage_DamageDelay_%1", _typeVeh], _damageDelays];
};

sel_damage_reset = {
	_veh = missionNameSpace getVariable "Garage_Vehicle";
	_typeVeh = typeOf _veh;

	if (isNil (format ["Garage_Damage_%1", _typeVeh])) exitWith {};

	_display = uiNamespace getVariable 'Garage_Display_Loadout';
	_damageList = _display displayctrl IDC_GARAGEDISPLAY_DAMAGE_LIST;

	//Reset List
	for "_i" from 0 to ((lnbSize _damageList) select 0) do {
		_damageList lnbSetText [[_i, 1], format["0%1", "%"]];
		_damageList lnbSetValue [[_i, 1], 0];
	};

	//Reset Garage_Damage
	_hitpointsDamage = missionNameSpace getVariable (format ["Garage_Damage_%1", _typeVeh]);
	for "_i" from 0 to (count _hitpointsDamage) do {
		_hitpointsDamage set [_i, 0];
	};
	missionNameSpace setVariable [format ["Garage_Damage_%1", _typeVeh], _hitpointsDamage];
};

sel_insignia_depotSpawnPoint = {
	params["_selectedIndex"];
	_display = uiNamespace getVariable 'Garage_Display_Loadout';
	_insigniaPointList = _display displayctrl IDC_GARAGEDISPLAY_INSIGNIA_POINT;
	_insigniaTexList = _display displayctrl IDC_GARAGEDISPLAY_INSIGNIA_TEX;

	_veh = missionNameSpace getVariable "Garage_Vehicle";
	_typeVeh = typeOf _veh;

	_insigniaSelect = missionNameSpace getVariable (format ["Garage_Insignia_%1", _typeVeh]);
	_insigniaTexList lbSetCurSel ((_insigniaSelect select 1) select _selectedIndex);
};

sel_insignia_tex = {
	params["_selectedIndex"];
	_display = uiNamespace getVariable 'Garage_Display_Loadout';
	_insigniaPointList = _display displayctrl IDC_GARAGEDISPLAY_INSIGNIA_POINT;
	_insigniaTexList = _display displayctrl IDC_GARAGEDISPLAY_INSIGNIA_TEX;

	_veh = missionNameSpace getVariable "Garage_Vehicle";
	_typeVeh = typeOf _veh;

	_currentPoint = lbCurSel _insigniaPointList;

	_index = _insigniaPointList lbValue _currentPoint;

	_insigniaData = missionNameSpace getVariable "GarageInsigniaData";

	_objTex = if (_selectedIndex == 0) then {
		_insigniaPointList lbData _currentPoint;
	} else {
		(_insigniaData select 1) select (_selectedIndex - 1);
	};
	_veh setObjectTextureGlobal [_index, _objTex];

	_insigniaSelect = missionNameSpace getVariable (format ["Garage_Insignia_%1", _typeVeh]);
	(_insigniaSelect select 1) set [_currentPoint, _selectedIndex];
	missionNameSpace setVariable [format ["Garage_Insignia_%1", _typeVeh], _insigniaSelect];
};

sel_insignia_reset = {
	_veh = missionNameSpace getVariable "Garage_Vehicle";
	_typeVeh = typeOf _veh;

	if (isNil (format ["Garage_Insignia_%1", _typeVeh])) exitWith {};

	_display = uiNamespace getVariable 'Garage_Display_Loadout';
	_insigniaPointList = _display displayctrl IDC_GARAGEDISPLAY_INSIGNIA_POINT;
	_insigniaTexList = _display displayctrl IDC_GARAGEDISPLAY_INSIGNIA_TEX;

	//Delete event
	{
		_x ctrlRemoveAllEventHandlers "LBSelChanged";
	} forEach [_insigniaPointList, _insigniaTexList];

	//Reset Texture and List
	_insigniaTexSelect = [];
	for "_i" from 0 to ((lbSize _insigniaPointList) - 1) do {
		_veh setObjectTextureGlobal [_insigniaPointList lbValue _i, ""];
		_insigniaTexSelect set [_i, 0];
	};

	missionNameSpace setVariable [format ["Garage_Insignia_%1", _typeVeh], [_insigniaPoint,_insigniaTexSelect]];

	_insigniaPointList lbSetCurSel 0;
	_insigniaTexList lbSetCurSel 0;

	//Reset event
	_insigniaPointList ctrlAddEventHandler ["LBSelChanged",{
		(_this select 1) call sel_insignia_depotSpawnPoint;
	}];
	_insigniaTexList ctrlAddEventHandler ["LBSelChanged",{
		(_this select 1) call sel_insignia_tex;
	}];
};

fnc_toggle_turret = {
	_ctrl = _this select 0;
	_display = uiNamespace getVariable "Garage_Display_Loadout";
	_pylon_index = (ctrlIDC _ctrl) - IDC_GARAGEDISPLAY_PYLON_MIRROR;

	_veh = missionNameSpace getVariable "Garage_Vehicle";
	_typeVeh = typeOf _veh;

	_last_turret = missionNamespace getVariable (format ["Garage_Turret_%1", _typeVeh]);

	_ctrls = [_ctrl];
	//If mirroring, change together.
	if (cbChecked (_display displayCtrl IDC_GARAGEDISPLAY_PYLON_MIRROR)) then
	{
		_pylons = (configProperties [configFile >> "CfgVehicles" >> _typeVeh >> "Components" >> "TransportPylonsComponent" >> "Pylons", "isClass _x"]) apply {configName _x};
		_countPylons = count _pylons;

		_mirrorPos = [];
		{
			_mirrorPos pushBack (getNumber (configfile >> "CfgVehicles" >> _typeVeh >> "Components" >> "TransportPylonsComponent" >> "Pylons">> _x >> "mirroredMissilePos"));
		} forEach _pylons;

		{
			_mirror_id = _x - 1;
			if (((_mirrorPos select _pylon_index) <= 0) && (_mirror_id == _pylon_index)) then {
				_ctrls pushBack (_display displayCtrl (IDC_GARAGEDISPLAY_PYLON_MIRROR+_forEachIndex));
			};
		} forEach _mirrorPos;
	};

	{
		//Toggle selection.
		_turret = [];
		if (count (_x getVariable "Owner") == 0) then
		{
			_x ctrlSetText "a3\ui_f\data\IGUI\RscIngameUI\RscUnitInfo\role_gunner_ca.paa";
			_x ctrlSetTooltip localize "str_gunner";
			_turret = [0];
		} else {
			_x ctrlSetText "a3\ui_f\data\IGUI\RscIngameUI\RscUnitInfo\role_driver_ca.paa";
			_x ctrlSetTooltip localize "str_driver";
		};
		_x setVariable ["Owner", _turret];

		_index = (ctrlIDC _x) - IDC_GARAGEDISPLAY_PYLON_MIRROR;
		_last_turret set [_index, _turret];
	} forEach _ctrls;

	missionNamespace setVariable [format ["Garage_Turret_%1", _typeVeh], _last_turret];
};

//0 : vehicle, 1 : pylon index (0~), 2 : weapon class
fnc_set_pylon = {
	_veh = _this select 0;
	_pylonIndex = _this select 1;
	_weaponClass = _this select 2;

	if (_weaponClass == "None") then
	{
		_veh setPylonLoadOut [_pylonIndex+1, "", true];
	} else {
		_veh setPylonLoadOut [_pylonIndex+1, _weaponClass, true];
		_veh setAmmoOnPylon [_pylonIndex+1, getNumber (configfile >> "CfgMagazines" >> _weaponClass >> "count")];
	};
};

fnc_preset_change = {
	_veh = missionNameSpace getVariable "Garage_Vehicle";
	_typeVeh = typeOf _veh;

	_display = uiNamespace getVariable "Garage_Display_Loadout";

	_ctrl_preset = _display displayCtrl (IDC_GARAGEDISPLAY_PYLON_PRESET);
	_index = lbCurSel _ctrl_preset;

	_pylons = (configProperties [configFile >> "CfgVehicles" >> _typeVeh >> "Components" >> "TransportPylonsComponent" >> "Pylons", "isClass _x"]) apply {configName _x};
	_countPylons = count _pylons;

	//Load selected preset's weapons.
	_preset = missionNamespace getVariable format ["Garage_Loadout_%1", _typeVeh];
	if (_index > 0) then
	{
		_presetsCFG = ("true" configClasses (configfile >> "CfgVehicles" >> _typeVeh >> "Components" >> "TransportPylonsComponent" >> "presets")) select (_index-1);
		_preset = getArray(configfile >> "CfgVehicles" >> _typeVeh >> "Components" >> "TransportPylonsComponent" >> "presets" >> configName _presetsCFG >> "attachment");
	};

	_i = 0;
	while{_i < _countPylons} do
	{
		_ctrl = _display displayCtrl (IDC_GARAGEDISPLAY_PYLON_WEAPON+_i);
		if (!isNull _ctrl) then {
			_ctrl ctrlRemoveAllEventHandlers "LBSelChanged";
			//Find id in select box.
			_selected = 0;
			_class = "";
			if ((count _preset) != 0 && (count _preset) > _i) then {
				_preset_mag = _preset select _i;
				_magList = [""]; //empty pylon
				_magList append (_veh getCompatiblePylonMagazines (format ["%1",_pylons select _i]));
				{
					if(_preset_mag == _x) then {
						_class = _x;
						_selected = _forEachIndex;
					};
				} forEach _magList;
			};

			//While change selection of weapon, remove selchange action.
			_ctrl lbSetCurSel _selected;
			[_veh, _i, _class] call fnc_set_pylon;
			waitUntil {(lbCurSel _ctrl) == _selected};
			_ctrl ctrlAddEventHandler ["LBSelChanged",{
				[_this select 0, _this select 1] call sel_weapon;
			}];
		};
		_i = _i + 1;
	};
	missionNamespace setVariable [format["Pylons_Preset_%1", _typeVeh], _index];

	//While change selection of mirroring, remove checkbox action.
	_ctrl_mirror = _display displayCtrl (IDC_GARAGEDISPLAY_PYLON_MIRROR);
	//_ctrl_mirror ctrlRemoveAllEventHandlers "CheckedChanged";
	if (cbChecked _ctrl_mirror) then
	{
		_ctrl_mirror cbSetChecked false;
		[] call fnc_pylon_mirror;
		waitUntil {!cbChecked _ctrl_mirror};
	};
	/*_ctrl_mirror ctrlAddEventHandler ["CheckedChanged",{
		[] call fnc_pylon_mirror;
	}];*/
};

fnc_pylon_mirror = {
	//systemChat "In pylon mirror";
	_veh = missionNameSpace getVariable "Garage_Vehicle";
	_typeVeh = typeOf _veh;

	_display = uiNamespace getVariable "Garage_Display_Loadout";

	_ctrl_mirror = _display displayCtrl IDC_GARAGEDISPLAY_PYLON_MIRROR;

	_pylons = (configProperties [configFile >> "CfgVehicles" >> _typeVeh >> "Components" >> "TransportPylonsComponent" >> "Pylons", "isClass _x"]) apply {configName _x};
	_countPylons = count _pylons;

	_mirrorPos = [];
	{
		_mirrorPos pushBack (getNumber (configfile >> "CfgVehicles" >> _typeVeh >> "Components" >> "TransportPylonsComponent" >> "Pylons">> _x >> "mirroredMissilePos"));
	} forEach _pylons;

	//_last_turret = missionNamespace getVariable (format ["Garage_Turret_%1", _typeVeh]);
	_last_turret = missionNamespace getVariable [format ["Garage_Turret_%1", _typeVeh], []];

	_i = 0;
	_call_id = [];
	while {_i < _countPylons} do {
		_ctrl = _display displayCtrl (IDC_GARAGEDISPLAY_PYLON_WEAPON+_i);
		_ctrl_turret = _display displayCtrl (IDC_GARAGEDISPLAY_PYLON_MIRROR+_i);
		_mirror_id = _mirrorPos select _i;
		if (_mirror_id > 0) then
		{
			if (cbChecked _ctrl_mirror) then
			{
				_ctrl ctrlRemoveAllEventHandlers "LBSelChanged";
				_ctrl ctrlCommit 0;
				_ctrl ctrlEnable false;

				//systemChat str _mirror_id;
				if ((_call_id find _mirror_id) == -1) then {
					_call_id pushBack _mirror_id;
				};

				if (count allTurrets [_veh, false] > 0) then
				{
					_ctrl_turret ctrlRemoveAllEventHandlers "ButtonClick";
					_ctrl_turret ctrlCommit 0;
					_ctrl_turret ctrlEnable false;

					//If selection is different, toggle it.
					_ctrl_turret_mirror = _display displayCtrl (IDC_GARAGEDISPLAY_PYLON_MIRROR+(_mirror_id-1));
					_owner = _ctrl_turret getVariable "Owner";
					if (count (_ctrl_turret_mirror getVariable "Owner") != count _owner) then
					{
						_turret = [];
						if (count _owner == 0) then
						{
							_ctrl_turret ctrlSetText "a3\ui_f\data\IGUI\RscIngameUI\RscUnitInfo\role_gunner_ca.paa";
							_ctrl_turret ctrlSetTooltip localize "str_gunner";
							_turret = [0];
						} else {
							_ctrl_turret ctrlSetText "a3\ui_f\data\IGUI\RscIngameUI\RscUnitInfo\role_driver_ca.paa";
							_ctrl_turret ctrlSetTooltip localize "str_driver";
						};
						_ctrl_turret setVariable ["Owner", _turret];

						_last_turret set [_i, _turret];
					};
				};
			} else {
				_ctrl ctrlAddEventHandler ["LBSelChanged",{
					[_this select 0, _this select 1] call sel_weapon;
				}];
				_ctrl ctrlEnable true;

				if (count allTurrets [_veh, false] > 0) then
				{
					_ctrl_turret ctrlAddEventHandler ["ButtonClick", {
						[_this select 0] call fnc_toggle_turret;
					}];
					_ctrl_turret ctrlEnable true;
				};
			};
		};
		_i = _i + 1;
	};

	if (!isNil (format ["Garage_Turret_%1", _typeVeh])) then {
		missionNamespace setVariable [format ["Garage_Turret_%1", _typeVeh], _last_turret];
	};

	{
		[_x - 1] spawn fnc_weapon_change;
	} forEach _call_id;
};

//0 : pylon index
fnc_weapon_change = {
	//systemChat "In weapon change";
	_veh = missionNameSpace getVariable "Garage_Vehicle";
	_typeVeh = typeOf _veh;
	_pylon_index = _this select 0;

	_display = uiNamespace getVariable "Garage_Display_Loadout";

	//While change selection of preset, remove selchange action.
	_ctrl_preset = _display displayCtrl IDC_GARAGEDISPLAY_PYLON_PRESET;
	_ctrl_preset ctrlRemoveAllEventHandlers "LBSelChanged";

	_ctrl = _display displayCtrl (IDC_GARAGEDISPLAY_PYLON_WEAPON+_pylon_index);
	_index = lbCurSel _ctrl;
	_str = (_ctrl lbData _index) splitString "^";
	_class = (_str select 0);

	_ctrl ctrlRemoveAllEventHandlers "LBSelChanged";

	//Change weapon
	[_veh, _pylon_index, _class] call fnc_set_pylon;

	//If mirroring, change together.
	if (cbChecked (_display displayCtrl IDC_GARAGEDISPLAY_PYLON_MIRROR)) then
	{
		_pylons = (configProperties [configFile >> "CfgVehicles" >> _typeVeh >> "Components" >> "TransportPylonsComponent" >> "Pylons", "isClass _x"]) apply {configName _x};
		_countPylons = count _pylons;

		_mirrorPos = [];
		{
			_mirrorPos pushBack (getNumber (configfile >> "CfgVehicles" >> _typeVeh >> "Components" >> "TransportPylonsComponent" >> "Pylons">> _x >> "mirroredMissilePos"));
		} forEach _pylons;

		{
			_mirror_id = _x - 1;
			if (((_mirrorPos select _pylon_index) <= 0) && (_mirror_id == _pylon_index)) then {
				_magList = ["None"]; //empty pylon
				_magList append (_veh getCompatiblePylonMagazines (format ["%1",_pylons select _forEachIndex]));

				_ctrl_mirrored = _display displayCtrl (IDC_GARAGEDISPLAY_PYLON_WEAPON+_forEachIndex);
				_selected = lbCurSel _ctrl_mirrored;
				_selFind = _magList find _class;
				if (_selFind != -1) then {
					_ctrl_mirrored lbSetCurSel _selFind;
					_str_mirrored = (_ctrl_mirrored lbData _selFind) splitString "^";
					_class_mirrored = _str_mirrored select 0;
					[_veh, _forEachIndex, _class_mirrored] call fnc_set_pylon;
				};
			};
		} forEach _mirrorPos;
	};

	missionNamespace setVariable [format ["Garage_Loadout_%1", _typeVeh], getPylonMagazines _veh];

	//While change selection of preset, remove selchange action.
	if ((lbCurSel _ctrl_preset) != 0) then
	{
		_ctrl_preset lbSetCurSel 0;
		missionNamespace setVariable [format["Pylons_Preset_%1", _typeVeh], 0];
		waitUntil {(lbCurSel _ctrl_preset) == 0};
	};

	_ctrl_preset ctrlAddEventHandler ["LBSelChanged",{
		[] call fnc_preset_change;
	}];

	_ctrl ctrlAddEventHandler ["LBSelChanged",{
		[_this select 0, _this select 1] call sel_weapon;
	}];
};

//hint "Create";
fnc_Garage_CreateVehicle = {
	_depotSpawnPoint = _this select 0;
	_veh = missionNamespace getVariable "BIS_fnc_garage_center";
	_typeVeh = typeOf _veh;

	_animationNames = animationNames _veh;
	_animationValues = [];
	{
		_animationValues pushBack (_veh animationPhase _x);
	} forEach _animationNames;

	_textures = getObjectTextures _veh;

	_magsNew = getPylonMagazines _veh;
	//_turretNew = missionNamespace getVariable format (["Garage_Turret_%1", _typeVeh]);
	_turretNew = [];
	if (isNil (format ["Garage_Turret_%1", _typeVeh])) then {
		_pylons = (configProperties [configFile >> "CfgVehicles" >> _typeVeh >> "Components" >> "TransportPylonsComponent" >> "Pylons", "isClass _x"]) apply {configName _x};
		{
			_turretNew pushBack getArray(configfile >> "CfgVehicles" >> _typeVeh >> "Components" >> "TransportPylonsComponent" >> "Pylons" >> _x >> "turret");
		} forEach _pylons;
	} else {
		_turretNew = missionNamespace getVariable format (["Garage_Turret_%1", _typeVeh]);
	};

	_fullCrewParams = fullCrew _veh;

	_special = "CAN_COLLIDE";
	_movein = false;
	switch (missionNamespace getVariable "Garage_SpawnType") do {
		case 1 : {
			_movein = true;
		};
		case 2 : {
			_movein = true;
			if ((_veh isKindOf "plane") || (_veh isKindOf "helicopter")) then
			{
				_special = "FLY";
			};
		};
	};

	{
		_veh deleteVehicleCrew _x;
	} forEach (crew _veh);
	{
		deleteVehicle _x;
	} forEach (attachedObjects _veh);
	deleteVehicle _veh;
	waitUntil {!alive _veh};

	sleep 0.1;

	_veh = createVehicle [_typeVeh, _depotSpawnPoint, [], 0, _special];
	if (_special != "FLY") then
	{
		_veh setPosASL ((getPosASL _depotSpawnPoint) vectorAdd [0,0,0.5]);
	};
	_veh setDir (getDir _depotSpawnPoint);

	{
		_veh animate [_x,_animationValues select _forEachIndex,true];
	} forEach _animationNames;

	{
		_veh setObjectTextureGlobal [_forEachIndex,_x];
	} forEach _textures;

	//Store non pylon weapons.
	_nonPylonWeapons = [];
	{
 		//_nonPylonWeapons append (getArray (_x >> "weapons"));
		{
			_nonPylonWeapons pushBack (toLower _x);
		} forEach (getArray (_x >> "weapons"));
	} forEach ([_veh, configNull] call BIS_fnc_getTurrets);

	//Delete pylon weapons.
	{
		_turretPath = _x;
		_allTurretWeapons = [];
		{
			_allTurretWeapons pushBack (toLower _x);
		} forEach (_veh weaponsTurret _turretPath);
		{
			//_veh removeWeaponGlobal _x;
			_veh removeWeaponTurret [_x, _turretPath];
		} forEach (_allTurretWeapons - _nonPylonWeapons);
	} forEach ([[-1]] + (allTurrets _veh));

	//Set weapons.
	{
		_veh setPylonLoadOut [_forEachIndex+1, _x, true, _turretNew select _forEachIndex];
		_veh setAmmoOnPylon [_forEachIndex+1, getNumber (configfile >> "CfgMagazines" >> _x >> "count")];
	} forEach _magsNew;

	//Set damage
	//_hitpointsDamage = missionNameSpace getVariable (format ["Garage_Damage_%1", _typeVeh]);
	_hitpointsDamage = missionNamespace getVariable [format ["Garage_Damage_%1", _typeVeh], (getAllHitPointsDamage _veh) select 2];
	if (_hitpointsDamage findIf {_x != 0} != -1) then {
		//_damageDelays = missionNameSpace getVariable (format ["Garage_DamageDelay_%1", _typeVeh]);
		_damageDelays = missionNameSpace getVariable [format ["Garage_DamageDelay_%1", _typeVeh], [0,0]];
		[_veh, _hitpointsDamage, _damageDelays] spawn Waldo_fnc_VVDVehicleDamage;
	};

	if("VehicleAutonomous" in (_typeVeh call BIS_fnc_objectType)) then
	{
		createVehicleCrew _veh;
		_veh setAutonomous (player connectTerminalToUAV _veh);
		(crew _veh) joinSilent (createGroup [playerSide, true]);

		if(_moveIn) then
		{
			_ai = driver _veh;
			if(isNull _ai) then
			{
				_ai = gunner _veh;
			};

			if (player connectTerminalToUAV _veh) then
			{
				player action ["UAVTerminalOpen", player];
				player remoteControl _ai;
				_ai switchCamera "INTERNAL";
			};
		};
	} else {
		{
			_unitType = switch (side player) do {
			  case west; case blufor : {"B_crew_F";};
			  case east; case opfor : {"O_crew_F";};
			  case independent; case resistance : {"I_crew_F";};
			  case civilian : {"C_man_w_worker_F";};
				default {"C_man_w_worker_F"};
			};
			_aiUnit = (group player) createUnit [_unitType, _depotSpawnPoint, [], 0, "CAN_COLLIDE"];
			waitUntil {alive _aiUnit};

			//Assign new ai unit to their roles.
			switch (toLower (_x select 1)) do {
				case "driver" : {
					_aiUnit assignAsDriver _veh;
					_aiUnit moveInDriver _veh;
				};
				case "commander" : {
					_aiUnit assignAsCommander _veh;
					_aiUnit moveInCommander _veh;
				};
				case "gunner" : {
					_aiUnit assignAsGunner _veh;
					_aiUnit moveInGunner _veh;
				};
				case "turret" : {
					_turretPath = _x select 3;
					_aiUnit assignAsTurret [_veh, _turretPath];
					_aiUnit moveInturret [_veh, _turretPath];
				};
				case "cargo" : {
					_cargoIndex = _x select 2;
					_aiUnit assignAsCargoIndex [_veh, _cargoIndex];
					_aiUnit moveInCargo [_veh, _cargoIndex];
				};
			};
		} forEach _fullCrewParams;
		if(_movein) then
		{
			player moveInAny _veh;
		};
	};

	//When the vehicle is plane, set initial speed.
	if (_veh isKindOf "plane" && _special == "FLY") then
	{
		_dir = getDir _veh;
		_speed = 80;
		_veh setVelocity [
			sin _dir * _speed,
			cos _dir * _speed,
			0
		];
		_veh setAirplaneThrottle 1;
	};

	//Execute additional script.
	_depotSpawnPointName = format["%1", _depotSpawnPoint];
	_script = missionNamespace getVariable format["Garage_Script_%1", _depotSpawnPointName];
	call (compile _script);
};

//call garage function
[_depotSpawnPoint, _types, _limitToSideVehicles, _removeUAVs] call fnc_Garage_load;
