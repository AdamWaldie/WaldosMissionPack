/*

Parameters:
_sideChosen

Details on this call can be found in init.sqf

This searches the mission.sqm for playable units on the side selected, returning an array of their equipment for use in the arsenal and supply boxes scripts.

THIS IS A FIRST PASS. When I get a moment, Ill go back through this and optimise it for time and space complexity.

*/
params[["_sideChosen","West"]];
private _PweapAndSdArm = [];
private _PLauncher = [];
private _launchMagazines = [];
private _NormalMagazines = [];
private _playerGear = [];
private _inventoryItems = [];
private _PBackpacks = [];
private _attachments = [];

{
    private _firstItem = configName _x;
    {
        private _secondItem = configName _x;
        private _isPlayer   = getNumber (missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities" >> _firstItem >> "Entities" >> _secondItem >> "Attributes" >> "isPlayer");
        private _isPlayable = getNumber (missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities" >> _firstItem >> "Entities" >> _secondItem >> "Attributes" >> "isPlayable");
        private _isCorrectSide = getText (missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities" >> _firstItem >> "Entities" >> _secondItem >> "side");
        if (_isCorrectSide == _sideChosen) then {
            if (_isPlayer == 1 || _isPlayable == 1) then {
                //Weapons
                private _MissionSQMPrimary = getText(missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities" >> _firstItem >> "Entities" >> _secondItem >> "Attributes" >> "Inventory" >> "primaryWeapon" >> "name");
                _PweapAndSdArm append [_MissionSQMPrimary];
                private _MissionSQMSidearm = getText(missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities" >> _firstItem >> "Entities" >> _secondItem >> "Attributes" >> "Inventory" >> "handgun" >> "name");
                _PweapAndSdArm append [_MissionSQMSidearm];
                private _MissionSQMBinos = getText(missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities" >> _firstItem >> "Entities" >> _secondItem >> "Attributes" >> "Inventory" >> "binocular" >> "name");
                _PweapAndSdArm append [_MissionSQMBinos];
                private _MissionSQMLauncher = getText(missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities" >> _firstItem >> "Entities" >> _secondItem >> "Attributes" >> "Inventory" >> "secondaryWeapon" >> "name");
                _PLauncher append [_MissionSQMLauncher];
                private _pMagwell = getText(missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities" >> _firstItem >> "Entities" >> _secondItem >> "Attributes" >> "Inventory" >> "primaryWeapon" >> "primaryMuzzleMag" >> "name");
                _NormalMagazines append [_pMagwell];
                private _hMagwell = getText(missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities" >> _firstItem >> "Entities" >> _secondItem >> "Attributes" >> "Inventory" >> "handgun" >> "primaryMuzzleMag" >> "name");
                _NormalMagazines append [_hMagwell];
                private _lMagwell = getText(missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities" >> _firstItem >> "Entities" >> _secondItem >> "Attributes" >> "Inventory" >> "secondaryWeapon" >> "primaryMuzzleMag" >> "name");          
                _launchMagazines append [_lMagwell];

                //Attachments
                //primaryattach
                private _pOptics = getText(missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities" >> _firstItem >> "Entities" >> _secondItem >> "Attributes" >> "Inventory" >> "primaryWeapon" >> "optics");          
                _attachments append [_pOptics];
                private _pMuzzle = getText(missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities" >> _firstItem >> "Entities" >> _secondItem >> "Attributes" >> "Inventory" >> "primaryWeapon" >> "muzzle");          
                _attachments append [_pMuzzle];
                private _pFlashlight = getText(missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities" >> _firstItem >> "Entities" >> _secondItem >> "Attributes" >> "Inventory" >> "primaryWeapon" >> "flashlight");          
                _attachments append [_pFlashlight];
                private _pUnderBarrel = getText(missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities" >> _firstItem >> "Entities" >> _secondItem >> "Attributes" >> "Inventory" >> "primaryWeapon" >> "underBarrel");          
                _attachments append [_pUnderBarrel];
                //sidearmattach
                private _sOptics = getText(missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities" >> _firstItem >> "Entities" >> _secondItem >> "Attributes" >> "Inventory" >> "handgun" >> "optics");          
                _attachments append [_sOptics];
                private _sMuzzle = getText(missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities" >> _firstItem >> "Entities" >> _secondItem >> "Attributes" >> "Inventory" >> "handgun" >> "muzzle");          
                _attachments append [_sMuzzle];
                private _sFlashlight = getText(missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities" >> _firstItem >> "Entities" >> _secondItem >> "Attributes" >> "Inventory" >> "handgun" >> "flashlight");          
                _attachments append [_sFlashlight];
                //launcherattach
                private _lOptics = getText(missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities" >> _firstItem >> "Entities" >> _secondItem >> "Attributes" >> "Inventory" >> "secondaryWeapon" >> "optics");          
                _attachments append [_lOptics];
                private _lMuzzle = getText(missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities" >> _firstItem >> "Entities" >> _secondItem >> "Attributes" >> "Inventory" >> "secondaryWeapon" >> "muzzle");          
                _attachments append [_lMuzzle];
                private _lFlashlight = getText(missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities" >> _firstItem >> "Entities" >> _secondItem >> "Attributes" >> "Inventory" >> "secondaryWeapon" >> "flashlight");          
                _attachments append [_lFlashlight];
                private _lUnderBarrel = getText(missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities" >> _firstItem >> "Entities" >> _secondItem >> "Attributes" >> "Inventory" >> "secondaryWeapon" >> "underBarrel");          
                _attachments append [_lUnderBarrel];

                //Unform
                private _uniform = getText(missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities" >> _firstItem >> "Entities" >> _secondItem >> "Attributes" >> "Inventory" >> "uniform" >> "typeName");
                _playerGear append [_uniform];
                {
                    private _thirdItem = configName _x;
                    private _unformMagazine = getText(missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities" >> _firstItem >> "Entities" >> _secondItem >> "Attributes" >> "Inventory" >> "uniform" >> "MagazineCargo" >> _thirdItem >> "name");
                    _NormalMagazines append [_unformMagazine];
                } forEach (configProperties [(missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities" >> _firstItem >> "Entities" >> _secondItem >> "Attributes" >> "Inventory" >> "uniform" >> "MagazineCargo"), "isClass _x", true]);
                {
                    private _thirdItem = configName _x;
                    private _unformItem = getText(missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities" >> _firstItem >> "Entities" >> _secondItem >> "Attributes" >> "Inventory" >> "uniform" >> "ItemCargo" >> _thirdItem >> "name");
                    _inventoryItems append [_unformItem];
                } forEach (configProperties [(missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities" >> _firstItem >> "Entities" >> _secondItem >> "Attributes" >> "Inventory" >> "uniform" >> "ItemCargo"), "isClass _x", true]);
                
                //Vest
                private _vest = getText(missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities" >> _firstItem >> "Entities" >> _secondItem >> "Attributes" >> "Inventory" >> "vest" >> "typeName");
                _playerGear append [_vest];
                {
                    private _thirdItem = configName _x;
                    private _unformMagazine = getText(missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities" >> _firstItem >> "Entities" >> _secondItem >> "Attributes" >> "Inventory" >> "vest" >> "MagazineCargo" >> _thirdItem >> "name");
                    _NormalMagazines append [_unformMagazine];
                } forEach (configProperties [(missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities" >> _firstItem >> "Entities" >> _secondItem >> "Attributes" >> "Inventory" >> "vest" >> "MagazineCargo"), "isClass _x", true]);
                {
                    private _thirdItem = configName _x;
                    private _unformItem = getText(missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities" >> _firstItem >> "Entities" >> _secondItem >> "Attributes" >> "Inventory" >> "vest" >> "ItemCargo" >> _thirdItem >> "name");
                    _inventoryItems append [_unformItem];
                } forEach (configProperties [(missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities" >> _firstItem >> "Entities" >> _secondItem >> "Attributes" >> "Inventory" >> "vest" >> "ItemCargo"), "isClass _x", true]);

                //Backpack
                private _backpack = getText(missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities" >> _firstItem >> "Entities" >> _secondItem >> "Attributes" >> "Inventory" >> "backpack" >> "typeName");
                _PBackpacks append [_backpack];
                {
                    private _thirdItem = configName _x;
                    private _unformMagazine = getText(missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities" >> _firstItem >> "Entities" >> _secondItem >> "Attributes" >> "Inventory" >> "backpack" >> "MagazineCargo" >> _thirdItem >> "name");
                    _NormalMagazines append [_unformMagazine];
                } forEach (configProperties [(missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities" >> _firstItem >> "Entities" >> _secondItem >> "Attributes" >> "Inventory" >> "backpack" >> "MagazineCargo"), "isClass _x", true]);
                {
                    private _thirdItem = configName _x;
                    private _unformItem = getText(missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities" >> _firstItem >> "Entities" >> _secondItem >> "Attributes" >> "Inventory" >> "backpack" >> "ItemCargo" >> _thirdItem >> "name");
                    _inventoryItems append [_unformItem];
                } forEach (configProperties [(missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities" >> _firstItem >> "Entities" >> _secondItem >> "Attributes" >> "Inventory" >> "backpack" >> "ItemCargo"), "isClass _x", true]);

                private _map = getText(missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities" >> _firstItem >> "Entities" >> _secondItem >> "Attributes" >> "Inventory" >> "map");
                _inventoryItems append [_map];
                private _compass = getText(missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities" >> _firstItem >> "Entities" >> _secondItem >> "Attributes" >> "Inventory" >> "compass");
                _inventoryItems append [_compass];
                //TFAR Helper For Radio (ACRE Unaffected)
                private _radio = getText(missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities" >> _firstItem >> "Entities" >> _secondItem >> "Attributes" >> "Inventory" >> "radio");
                _inventoryItems append [_radio];
                private _gps = getText(missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities" >> _firstItem >> "Entities" >> _secondItem >> "Attributes" >> "Inventory" >> "gps");
                _inventoryItems append [_gps];
                private _goggles = getText(missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities" >> _firstItem >> "Entities" >> _secondItem >> "Attributes" >> "Inventory" >> "goggles");
                _inventoryItems append [_goggles];
                private _hmd = getText(missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities" >> _firstItem >> "Entities" >> _secondItem >> "Attributes" >> "Inventory" >> "hmd");
                _inventoryItems append [_hmd];
                private _headgear = getText(missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities" >> _firstItem >> "Entities" >> _secondItem >> "Attributes" >> "Inventory" >> "headgear");
                _playerGear append [_headgear];
            };
        };
    } forEach (configProperties [(missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities" >> _firstItem >> "Entities"), "isClass _x", true]);
} forEach (configProperties [(missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities"), "isClass _x", true]);

//Get Uniques & Cleanup output

_PweapAndSdArm = str _PweapAndSdArm splitString "[]," joinString ",";
_PweapAndSdArm = parseSimpleArray ("[" + _PweapAndSdArm + "]");
_PweapAndSdArm = _PweapAndSdArm arrayIntersect _PweapAndSdArm select {_x isEqualType "" && {_x != ""}};

_PLauncher = str _PLauncher splitString "[]," joinString ",";
_PLauncher = parseSimpleArray ("[" + _PLauncher + "]");
_PLauncher = _PLauncher arrayIntersect _PLauncher select {_x isEqualType "" && {_x != ""}};

_launchMagazines = str _launchMagazines splitString "[]," joinString ",";
_launchMagazines = parseSimpleArray ("[" + _launchMagazines + "]");
_launchMagazines = _launchMagazines arrayIntersect _launchMagazines select {_x isEqualType "" && {_x != ""}};

_NormalMagazines = str _NormalMagazines splitString "[]," joinString ",";
_NormalMagazines = parseSimpleArray ("[" + _NormalMagazines + "]");
_NormalMagazines = _NormalMagazines arrayIntersect _NormalMagazines select {_x isEqualType "" && {_x != ""}};

_playerGear = str _playerGear splitString "[]," joinString ",";
_playerGear = parseSimpleArray ("[" + _playerGear + "]");
_playerGear = _playerGear arrayIntersect _playerGear select {_x isEqualType "" && {_x != ""}};

_inventoryItems = str _inventoryItems splitString "[]," joinString ",";
_inventoryItems = parseSimpleArray ("[" + _inventoryItems + "]");
_inventoryItems = _inventoryItems arrayIntersect _inventoryItems select {_x isEqualType "" && {_x != ""}};

_PBackpacks = str _PBackpacks splitString "[]," joinString ",";
_PBackpacks = parseSimpleArray ("[" + _PBackpacks + "]");
_PBackpacks = _PBackpacks arrayIntersect _PBackpacks select {_x isEqualType "" && {_x != ""}};

_attachments = str _attachments splitString "[]," joinString ",";
_attachments = parseSimpleArray ("[" + _attachments + "]");
_attachments = _attachments arrayIntersect _attachments select {_x isEqualType "" && {_x != ""}};

//set special variable EMPTY if nothing in that item
if (count _PweapAndSdArm == 0) then {
    _PweapAndSdArm = ["EMPTY"];
};
if (count _PLauncher == 0) then {
    _PLauncher= ["EMPTY"];
};
if (count _launchMagazines == 0) then {
    _launchMagazines= ["EMPTY"];
};
if (count _NormalMagazines == 0) then {
    _NormalMagazines= ["EMPTY"];
};
if (count _playerGear == 0) then {
    _playerGear= ["EMPTY"];
};
if (count _inventoryItems == 0) then {
    _inventoryItems= ["EMPTY"];
};
if (count _PBackpacks == 0) then {
    _PBackpacks= ["EMPTY"];
};
if (count _attachments == 0) then {
    _attachments= ["EMPTY"];
};

private _masterArray = [_PweapAndSdArm,_NormalMagazines,_PLauncher,_launchMagazines,_playerGear,_inventoryItems,_PBackpacks,_attachments];
_masterArray