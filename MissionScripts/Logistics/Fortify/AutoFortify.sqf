/*
This script is designed to dynamically grab all objects syncronised to a game logic, add them to a sides foritfy menu, and price them dynamically based on their volume & mass. 
This isnt perfect, but the log scalars help keep the extreemes (mostly) in step with everything else.

How to use:
 - Make sure your player(s) have a fortify tool in their inventory.
 - Place a game logic down and paste into its init the function call as noted below - alter it to fit your requirements
 - syncronise to the game logic any objects, static weapons or vehicles that you wish to be constructable in fortify.
 - If you require more than one side to use fortify, repeat the above steps in entirety and ensure the function call has the correct side in each.
 - Run the game.

parameters:
_target - the object variable name you want this to apply to (The game logic)
_side - the side that the crate will populate the fortify list to. Each setup is single use as the objects and logic are destroyed afterward. Options: West,East,Independent,Civilian
_budget - user defined starting budget for the side, this can then be added to later on using the ACE_Fortify budget script.

[_target,west,6000] call Waldo_fnc_AutoFortifySetup;

e.g.

[this,west,6000] call Waldo_fnc_AutoFortifySetup;

==================================================================

ACE Fortify Budget Function (use this if you want to add or remove budget to a side during your mission: 

Updates the given sides budget.

 Arguments:
  0: Side <SIDE>
  1: Change <NUMBER> (default: 0)
  2: Display hint <BOOL> (default: true)

 Return Value:
  None

 Example:
  [west, -250, false] call ace_fortify_fnc_updateBudget

I have also created a ZEN module which allows you to do this via zeus during the mission if desired.

*/
if (!isServer) exitwith {}; // server only (per ace requrements)

params ["_targetLogic",["_side",west],["_budget",5000]];

// Init the price mapping list
private _priceMapping = [];

// Define syncedObjects based on fortifyLogic
private _syncedObjects = synchronizedObjects _targetLogic;

{
	if (_x isKindOf "All") then {
        private _mass = getMass _x;
        
        // Get boundingBoxReal dimensions
        private _bb = boundingBoxReal _x;
        private _p1 = _bb select 0;
        private _p2 = _bb select 1;
        
        private _length = abs((_p2 select 0) - (_p1 select 0));
        private _width = abs((_p2 select 1) - (_p1 select 1));
        private _height = abs((_p2 select 2) - (_p1 select 2));
        
        private _volume = _length * _width * _height;

        // Revised price formula
        private _price = ceil(20 + (log(_mass + 10) * 10) + (_volume * 0.5));  // Adjusted coefficients for mass and volume

        if (_x isKindOf "AllVehicles") then {
            _price = ceil(log(_price + 200) * 100);
        };
		if (_x isKindOf "Air") then {
            _price = ceil(log(_price + 2500) * 200); 
        };
		if (_x isKindOf "Car") then {
            _price = ceil(log(_price + 500) * 150); 
        };
		if (_x isKindOf "Tank") then {
            _price = ceil(log(_price + 2000) * 200); 
        };
		if (_x isKindOf "Ship") then {
            _price = ceil(log(_price + 500) * 150); 
        };

		// Set a minimum price for any object, for example, 20
        _price = _price max 20;
		
		// Round the price to the nearest multiple of 5
        _price = ceil(_price / 5) * 5;

        // Append to the price mapping list
        _priceMapping pushBack [typeOf _x, _price];
    };
	deleteVehicle _x;
} forEach _syncedObjects;

//systemChat format["prices: %1",_priceMapping];

// Register the objects with ACE Fortify using the calculated prices
[_side, _budget, _priceMapping] call ace_fortify_fnc_registerObjects;
//cleanup
deleteVehicle _targetLogic;