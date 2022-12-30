/*
Vehicle Camo Script

Authors: Val & Waldo

A script which allows for the creation of "camo" objects to assist in hiding of a vehicle in ambush. The script also accounts for limited dismounted movement around the vehicle, in concealment (civ).

Designed for tanks.

Setting Up in Eden;
	- Place the vehicle or object that you want to have the respawn deployable from, and provide it a variable name
	- Place a Game Logic down close to the vehicle. This can be found near the same menu as Modules.
	- Place any objects you wish to appear when the camo is deployed.
	- If you are using a vehicle as your primary object and any of your deployable objects should be resting on the floor, then raise them about a foot, to allow for the drop of the vehicle's suspension once the game has initialised.
	- Select all the objects that will be deployable, right-click and synchronise them to the Game Logic.
	- In the init of the MHQ/CP, paste the example below, and alter it to suit the needs you have.
Features;
	- Allows any Vehicle or Object to be a deployable respawn. Vehicle respawns will be attached to the vehicle during movement while object respawns are static.
	- Creates a randomised Command Post name and marker on the map.
	- Changes the respawn side depending on who deployed it.

Parameters:
_target - Vehicle or Object to use as the Mobile headquarters
_playerSide - original side of the player

Example:

[this,west] call Waldo_fnc_VehicleCamo;

*/

params ["_target","_playerSide"];
	//Catch all for any not using ACE to prevent bad things
	if !(isClass(configFile >> "CfgPatches" >> "ace_main")) exitwith {};
	
	// Finds all synced Objects. Hides the model and attaches the object to vehicle.
	_syncLogic = nearestObject [_target, "Logic"]; 
	_camoParts = synchronizedObjects _syncLogic;
	[_syncLogic, _target] call BIS_fnc_attachToRelative;
	{[_x, _target] call BIS_fnc_attachToRelative;} forEach _camoParts;
	{[_x, true] remoteExec ["hideObjectGlobal", 2];} forEach _camoParts;
	_target setVariable ['waldo_camoDeployed', false, true];

	waldo_civillianSideChange = {
		params ["_commander"];
		_originGroup = group _commander;
		_originGroupUnits = units _originGroup;
		_originLeader = leader _originGroup;

		_incogGroup = createGroup civilian;
		_originGroupUnits joinSilent _incogGroup;
		[_incogGroup, _originLeader] remoteExec ["selectLeader", groupOwner _incogGroup];
		_originGroupUnits
	};

	waldo_returnSideChange = {
		params ["_commander","_playerSide"];
		_incogGroup = group _commander;
		_incogGroupUnits = units _incogGroup;
		_incogLeader = leader _incogGroup;

		_originGroup = createGroup _playerSide; // CHANGE THIS SIDE TO REFLECT ALLY FACTION
		_incogGroupUnits joinSilent _originGroup;
		[_originGroup, _incogLeader] remoteExec ["selectLeader", groupOwner _originGroup];
		_incogGroupUnits
	};

	waldo_deployCamo = {
		params ["_target", "_player","_playerSide"];
		["Tank Camouflage Deployed.", _player] call waldo_fnc_DynamicText;
		_syncLogic = nearestObject [_target, "Logic"]; 
		_camoParts = synchronizedObjects _syncLogic;
		{[_x, false] remoteExec ["hideObjectGlobal", 2];} forEach _camoParts;
		_target setVariable ['waldo_camoDeployed', true, true];
		_playerGroup = group _player;
		[_player] call waldo_civillianSideChange;

		// Check crew for distance from Tank

		[_target, _player,_playerSide] spawn {
			params ["_target","_player","_playerSide"];
			private _distFromTankBOOL = false;
				while {!_distFromTankBOOL} do {
					sleep 10;
					_playerGroup = Group _player;
					{
						if ((_x distance _target) > 40) then {
							[_x,_playerSide] call waldo_returnSideChange;
							{["You are too far from your tank.<br/>Reposition or redeploy.", _x] call waldo_fnc_DynamicText;} forEach units group _x;
							private _distFromTankBOOL = true;
							_ehTypes = ["GetIn", "GetOut", "Hit", "Fired"];
							_playerGroupIF = units group _player;
							{_target removeAllEventHandlers _x;} forEach _ehTypes;
							{_x removeAllEventHandlers "Hit";} forEach _playerGroupIF;
						};
					} forEach units _playerGroup;

					_list = _player nearEntities 300;
					_eastIndex = _list findIf {side _x == _playerSide}; // CHANGE THIS SIDE TO REFLECT ENEMY FACTION
					if (_eastIndex >= 0) then {
						_nearestEnemy = _list select _eastIndex;
						//_eastKnows = _nearestEnemy knowsAbout _target;  && _eastKnows > 1.5
						if (_nearestEnemy distance _target < 150) then {
							{["The Tank has been spotted.<br/>Reposition or redeploy.", _x] call waldo_fnc_DynamicText;} forEach units group _player;
							[_player] call waldo_returnSideChange;
							_ehTypes = ["GetIn", "GetOut", "Hit", "Fired"];
							{_target removeAllEventHandlers _x;} forEach _ehTypes;
							{_x removeAllEventHandlers "Hit";} forEach units _playerGroup;
						};
					};
				if !(_target getVariable 'waldo_camoDeployed') exitWith {};
			};
		};

		// Establish distance to enemy

		_nearestEnemy = _player findNearestEnemy _target;
		if (_nearestEnemy distance _target < 200) then {
			_ehTypes = ["GetIn", "GetOut", "Hit", "Fired"];
			{_target removeAllEventHandlers _x;} forEach _ehTypes;
			{_x removeAllEventHandlers "Hit";} forEach _playerGroup;
		};

		// Switch Vehicle to West if crew is shot
		{_x addEventHandler ["Hit", {
			params ["_unit", "_source", "_damage", "_instigator"];
			[_unit] call waldo_returnSideChange;

		}];} forEach units group _player;

		// Switch Vehicle to West if Vehicle hit
		_target addEventHandler ["Hit", {
			params ["_unit", "_source", "_damage", "_instigator"];
			_crew = crew _unit select 0;
			[_crew] call waldo_returnSideChange;
			["Tank Hit - Revealed", crew _unit] call waldo_fnc_DynamicText;

			_ehTypes = ["GetIn", "GetOut", "Hit", "Fired"];
			{_unit removeAllEventHandlers _x;} forEach _ehTypes;
			{_x removeAllEventHandlers "Hit";} forEach _playerGroup;

		}];

		// Switch Vehicle to West if Vehicle fires.
		_target addEventHandler ["Fired", {
			params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_gunner"];
			_crew = crew _unit select 0;
			[_crew] call waldo_returnSideChange;
			["Tank Fired - Revealed", crew _unit] call waldo_fnc_DynamicText;

			_ehTypes = ["GetIn", "GetOut", "Hit", "Fired"];
			{_unit removeAllEventHandlers _x;} forEach _ehTypes;
			{_x removeAllEventHandlers "Hit";} forEach _playerGroup;
		}];

		// Switch Vehicle to West and Hide Camo if engine started
		_target addEventHandler ["Engine", {
			params ["_vehicle", "_engineState"];
			_unit = crew _vehicle select 0;
			[_unit] call waldo_returnSideChange;
			["Engine On - Revealed", crew _unit] call waldo_fnc_DynamicText;
			_syncLogic = nearestObject [_vehicle, "Logic"]; 
			_camoParts = synchronizedObjects _syncLogic;
			{[_x, true] remoteExec ["hideObjectGlobal", 2];} forEach _camoParts;
			_vehicle setVariable ['waldo_camoDeployed', false, true];	
			// Resets all EH types.
			_ehTypes = ["GetIn", "GetOut", "Hit", "Fired", "Engine"];
			{_vehicle removeAllEventHandlers _x;} forEach _ehTypes;
			{_x removeAllEventHandlers "Hit";} forEach _playerGroup;

		}];
	};

	//Action Start
	waldo_initVehicleCamo = [
		"waldo_initVehicleCamo",
		"Deploy Tank Camouflage",
		"\a3\data_f_destroyer\data\UI\IGUI\Cfg\holdactions\holdAction_unloadVehicle_ca.paa",
		{
			// Runs on Action Called
			
			[10, [_target, _player,_playerSide], {
				_args call waldo_deployCamo;
				_args select 0 engineOn false;
			}, {["Camouflage not deployed.", _player] call waldo_fnc_DynamicText;}, "Deploying Tank Camouflage"] call ace_common_fnc_progressBar;
			
		},
		{
			//[_target, _player, _actionParams] Condition
			!(_target getVariable 'waldo_camoDeployed') && (_player distance _target) < 7 && speed _target < 2 && isTouchingGround _target && count nearestTerrainObjects [_target, ["Tree","Bush"], 20] > 5;
		},
		{},
		[],
		[],
		0,
		[false, false, false, false, false]
	] call ace_interact_menu_fnc_createAction;
	
	// Action for removing Camo

	waldo_removeVehicleCamo = [
		"waldo_removeVehicleCamo",
		"Remove Tank Camouflage",
		"\a3\data_f_destroyer\data\UI\IGUI\Cfg\holdactions\holdAction_loadVehicle_ca.paa",
		{
			// Runs on Action Called
			
			[10, [_target, _player,_playerSide], {
				_target = _args select 0;
				_player = _args select 1;
				_unit = crew _target select 0;
				[_unit] call waldo_returnSideChange;
				[_player,_playerSide] call waldo_returnSideChange;
				_syncLogic = nearestObject [_target, "Logic"]; 
				_camoParts = synchronizedObjects _syncLogic;
				{[_x, true] remoteExec ["hideObjectGlobal", 2];} forEach _camoParts;
				_target setVariable ['waldo_camoDeployed', false, true];	
				// Resets all EH types.
				_ehTypes = ["GetIn", "GetOut", "Hit", "Fired", "Engine"];
				{_target removeAllEventHandlers _x;} forEach _ehTypes;
				{_x removeAllEventHandlers "Hit";} forEach _playerGroup;
				{["Tank Camouflage Removed", _x] call waldo_fnc_DynamicText;} forEach units group _player;
			}, {["Camouflage Still Deployed.", _player] call waldo_fnc_DynamicText;}, "Removing Tank Camouflage"] call ace_common_fnc_progressBar;
			
		},
		{
			//[_target, _player, _actionParams] Condition
			(_target getVariable 'waldo_camoDeployed') && (_player distance _target) < 7 && speed _target < 2 && isTouchingGround _target;
		},
		{},
		[],
		[],
		0,
		[false, false, false, false, false]
	] call ace_interact_menu_fnc_createAction;
	

	// Add action to Vehicle
	[_target,
		0, 
		["ACE_MainActions"], 
		waldo_initVehicleCamo
	] call ace_interact_menu_fnc_addActionToObject;

	[_target,
		0, 
		["ACE_MainActions"], 
		waldo_removeVehicleCamo
	] call ace_interact_menu_fnc_addActionToObject;


//>>> ===================================================================================================================================================


