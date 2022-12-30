/*
Mobile Headquarters / Command Post script - Requires ACE 3

Authors: Waldo & Val.

A script which allows for the creation of a command post, acting as a respawn position, you may choose to combine this with the logistics quartermaster script if so desired.

This can be both a stationary object, or a vehicle.

This allows a number of objects, as selected via the syncing of a named gamelogic to be attached to a vehicle, and "deployed"/"undeployed" on request when in a desired location.

Setting Up in Eden;
	- Place the vehicle or object that you want to have the respawn deployable from, and provide it a variable name. This will be known as the MHQ/CP in this tutorial.
	- Place a Game Logic down close to the MHQ/CP. This can be found near the same menu as Modules.
	- Place any objects you wish to appear when the respawn is deployed. Leave some room approx 3m to the left of the primary object to allow space for players to respawn.
	- If you are using a vehicle as your primary object and any of your deployable objects should be resting on the floor, then raise them about a foot, to allow for the drop of the vehicle's suspension once the game has initialised.
	- Select all the objects that will be deployable, right-click and synchronise them to the Game Logic.
	- In the init of the MHQ/CP, paste the following: [this] call Waldo_fnc_MHQSetup;
	- If you desire to utilise the modern construction audio, please use the example noting that below.
	- That's it.
	- (Optional) Line 62 contains an array of all the potential names for the Command Posts, add some if you want or set it to just a smaller amount, just remember it's an array of strings, within the selectRandom square brackets (If you don't know what any of that means, I wouldn't touch it!)

Features;
	- Allows any Vehicle or Object to be a deployable respawn. Vehicle respawns will be attached to the vehicle during movement while object respawns are static.
	- Creates a randomised Command Post name and marker on the map.
	- Changes the respawn side depending on who deployed it.

Parameters:
_target - Vehicle or Object to use as the Mobile headquarters
_constructionAudio - boolean (true/false) | Options: True = Modern construction Noises, False = Old Wooden Sounding Construction Noises.

Example:

// Default old construction audio
[this] call Waldo_fnc_MHQSetup; 

// Modern construction audio
[this,true] call Waldo_fnc_MHQSetup;

*/

params ["_target",["_constructionAudio",false]];
	//Catch all for any not using ACE to prevent bad things
	if !(isClass(configFile >> "CfgPatches" >> "ace_main")) exitwith {};

	//Select Desired Audio For Pack/Unpack
	private _MHQAudioPath = "MissionScripts\Logistics\MHQ\Audio\Audio_Deploy_New.ogg";
	if (_useModernConsturctionAudio == false) then {
		_MHQAudioPath = "MissionScripts\Logistics\MHQ\Audio\Audio_Deploy_Old.ogg"
	};
	
	// Finds all synced Objects. Hides the model and attaches the object to vehicle. !! UPDATE - MOVED TO VEHICLE INIT CODE !!
	_syncLogic = nearestObject [_target, "Logic"]; 
	_deployParts = synchronizedObjects _syncLogic;
	

	if (isServer || isDedicated) then {
		_target setVariable ['Waldo_MHQ_Status', false, true];
		[_syncLogic, _target] call BIS_fnc_attachToRelative;
		{
			[_x, _target] call BIS_fnc_attachToRelative;
			[_x, true] remoteExec ["hideObjectGlobal", 2];
		} forEach _deployParts;
	};

	waldo_CP_Deployment = {
		params ["_target", "_player"];
		["Command Post Deployed.", _player] call Waldo_fnc_DynamicText;
		_syncLogic = nearestObject [_target, "Logic"]; 
		_deployParts = synchronizedObjects _syncLogic;
		{[_x, false] remoteExec ["hideObjectGlobal", 2];} forEach _deployParts;
		_vehiclePositionOffsetOnDirection = getDir _target + 270;
		_knownSafePosition = [getPosATL _target, 2, _vehiclePositionOffsetOnDirection] call BIS_fnc_relPos;
		_FHQNameList = selectRandom ["Dasher","Prancer","Dancer","Cupid","Vixen","Comet","Dunder","Blixem","Eagle","Hawk","Sparrow","Vulture","Condor","Raptor","Cryptid","Corvid","Crow","Raven","Alpha","Able","Bravo","Baker","Charlie","Delta","Dog","Echo","Easy","Foxtrot","Fox","Golf","George","Hotel","How","India","Item","Juliet","Jig","Kilo","Lima","Love","Mike","November","Nan","Oscar","Oboe","Papa","Peter","Quebec","Romeo","Roger","Sierra","Sugar","Tango","Tare","Uniform","Uncle","Victor","Whisky","William","Xray","Yankee","Yoke","Zulu","King","Queen","Prince","Princess","Lion","Tiger","Snake","Spider","Mongoose","Meerkat","Mouse","Rat","Vole","Beever","Antelope","Wolf","Bear","Toucan","Zebra","Blue","Red","Green","Yellow","Orange","Black","White","Moonlight","Sunbeam","Starlight","Northstar","Plough","Candle","Bounty","Iron","Steel","Gold","Silver","Oak","Redwood","Willow","Sequoia","Palm","Pine","Brass","Circlet","Brace","Waterfall","Thunder","Lightning","Odin","Thor","Loki","Balder","Freya","Fenrir","Jotun","Grey","Shortsword","Longsword","Saber","Rapier","Zeus","Ares","Athena","Apollo","Hades","Cerberus","Typhon","Pontus","Gaia","Tartarus","Eros","Aether","Hemera","Uranus","Cronus","Phoebe","Demeter","Poseidon","Artemis","Helios","Hera","Hephaestus","Dionysus","Atlas","Prometheus","Hermes","Aphrodite","Hyperion","Crossroads","Falcon","McKinnon","Kerry","Adams","Lacey","Miller","Nikos","Gavras","Stavrou"];
		_deployedFieldHQ = [side _player, _knownSafePosition, "Command Post " + _FHQNameList] call BIS_fnc_addRespawnPosition;
		{
			_x action ["Eject", vehicle _x];
		} forEach crew _target;
		_target engineOn false;
		[_target ,"LOCKED"] remoteExec ["setVehicleLock", 0];
		_target setVariable ['Waldo_MHQ_Status', true, true];
		["TaskSucceeded",["","Command Post " + _FHQNameList + " Established"]] remoteExec ["BIS_fnc_showNotification", 0];

		_textColour = switch (side _player) do
			{
				case west: {"ColorWEST"};
				case east: {"ColorEAST"};
				case resistance: {"ColorGUER"};
				case civilian: {"ColorCIV"};
				default {"ColorBlack"};
			};
		_markerID = str (_FHQNameList + str time);
		//systemChat _markerID;
		_mapMarker = createMarker [_markerID, getPos _target];
		_mapMarker setMarkerColor _textColour;
		_mapMarker setMarkerType "mil_flag";
		_mapMarker setMarkerText "Command Post " + _FHQNameList;
		playSound3d [getMissionPath _MHQAudioPath, _target, false, getPosASL _target, 4, 1];
		[_target, _deployedFieldHQ, _mapMarker, _FHQNameList] spawn {
			params ["_target", "_deployedFieldHQ","_mapMarker","_FHQNameList"];
			waitUntil {!(_target getVariable 'Waldo_MHQ_Status')};
			_deployedFieldHQ call BIS_fnc_removeRespawnPosition;
			["TaskCanceled",["","Command Post " + _FHQNameList + " Torn Down"]] remoteExec ["BIS_fnc_showNotification", 0];
			deleteMarker _mapMarker;
		};
	};

	waldo_CP_TearDown = {
		params ["_target","_player"];
		_syncLogic = nearestObject [_target, "Logic"]; 
		_deployParts = synchronizedObjects _syncLogic;
		{[_x, true] remoteExec ["hideObjectGlobal", 2];} forEach _deployParts;
		[_target,"UNLOCKED"] remoteExec ["setVehicleLock", 0];
		playSound3d [getMissionPath _MHQAudioPath, _target, false, getPosASL _target, 4, 1];
		_target setVariable ['Waldo_MHQ_Status', false, true];	
		["Command Post Torn Down", _player] call Waldo_fnc_DynamicText;
	};
	
	
	//Action Start for adding RP
	waldo_CP_InitDeployment_ACE = [
		"waldo_CP_InitDeployment_ACE",
		"Deploy Command Post",
		"\a3\data_f_destroyer\data\UI\IGUI\Cfg\holdactions\holdAction_unloadVehicle_ca.paa",
		{
			// Runs on Action Called
			
			[10, [_target, _player], {
				_args call waldo_CP_Deployment;
			}, {["Command Post not Deployed.", _player] call Waldo_fnc_DynamicText;}, "Establishing Command Post"] call ace_common_fnc_progressBar;
		},
		{
			//[_target, _player, _actionParams] Condition
			!(_target getVariable 'Waldo_MHQ_Status') && (_player distance _target) < 6 && speed _target < 1;
		},
		{},
		[],
		[],
		0,
		[false, false, false, false, false]
	] call ace_interact_menu_fnc_createAction;

	// Action for removing RP
	waldo_CP_InitTearDown_ACE = [
		"waldo_CP_InitTearDown_ACE",
		"Tear Down Command Post",
		"\a3\data_f_destroyer\data\UI\IGUI\Cfg\holdactions\holdAction_loadVehicle_ca.paa",
		{
			// Runs on Action Called
			
			[10, [_target, _player], {
				_args call waldo_CP_TearDown;
			}, {[_duration, "Command Post still Deployed", _player] call Waldo_fnc_DynamicText;}, "Tearing Down Command Post"] call ace_common_fnc_progressBar;
		},
		{
			//[_target, _player, _actionParams] Condition
			(_target getVariable 'Waldo_MHQ_Status') && (_player distance _target) < 6 && speed _target < 1;
		},
		{},
		[],
		[],
		0,
		[false, false, false, false, false]
	] call ace_interact_menu_fnc_createAction;
	
	// Add action to Vehicle (ACE 3)
	[_target,
		0, 
		["ACE_MainActions"], 
		waldo_CP_InitDeployment_ACE
	] call ace_interact_menu_fnc_addActionToObject;

	[_target,
		0, 
		["ACE_MainActions"], 
		waldo_CP_InitTearDown_ACE
	] call ace_interact_menu_fnc_addActionToObject;
