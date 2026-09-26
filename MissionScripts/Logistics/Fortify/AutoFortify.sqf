/*
 * Author: WaldoTheWarfighter
 * Purpose: Price the objects synchronized to a Game Logic by mass and size, then register
 * their classes and a starting budget with ACE Fortify for one side. The source objects and
 * Game Logic are deleted after registration.
 * Locality/authority: server only. Eden Init runs on each machine, but clients exit immediately.
 * ACE Fortify must be loaded before this call; the server owns the class list and budget.
 * Repeat/JIP: one-shot and destructive. Do not call again on the consumed Game Logic. This
 * helper has no WMP JIP replay; test ACE Fortify visibility for players who join later.
 * Arguments:
 * 0: synchronized Game Logic <OBJECT> (required) - catalogue source.
 * 1: side <SIDE> (default west) - Fortify menu owner.
 * 2: starting budget <NUMBER> (default 1000) - side budget passed to ACE.
 * Return Value: Nothing useful; a client call exits without registration.
 * Current callers: mission-maker Game Logic Init fields and scripted server setup.
 * Example: [this, west, 6000] call Waldo_fnc_AutoFortifySetup;
 * Result: supported synced classes enter WEST's ACE Fortify menu, then source objects vanish.
 */
if (!isServer) exitwith {}; // server only (per ace requrements)

params ["_targetLogic",["_side",west],["_budget",1000]];

// Init the price mapping list
private _priceMapping = [];

// Define syncedObjects based on fortifyLogic
private _syncedObjects = synchronizedObjects _targetLogic;

{
    if (_x isKindOf "All") then {
    // Check if the object is not one of the restricted vehicle types
        if (!(_x isKindOf "Air" || _x isKindOf "Car" || _x isKindOf "Tank" || _x isKindOf "Ship")) then {
            private _mass = getMass _x;

            // Get boundingBoxReal dimensions
            private _bb = boundingBoxReal _x;
            private _p1 = _bb select 0;
            private _p2 = _bb select 1;
            
            private _length = abs((_p2 select 0) - (_p1 select 0));
            private _width = abs((_p2 select 1) - (_p1 select 1));
            private _height = abs((_p2 select 2) - (_p1 select 2));
            
            private _volume = _length * _width * _height;

            // Price formula
            _price = ceil(10 + (log(_mass + 10) * 10) + (_volume * 0.5));

            private _objType = typeof _x; 

            // Check for static weapons - both standard and additional checks
            if (_x isKindOf "StaticWeapon" || (toLower _objType) find "staticweapon" > -1 || (toLower _objType) find "static_weapon" > -1) then { 
                _price = _price*1.2;  // You can adjust this if you want to have static weapons slightly more expensive
            };

            // Set a minimum/max price for any object
            _price = _price max 20;
            _price = _price min 1000;
            
            // Round the price to the nearest multiple of 5
            _price = ceil(_price / 5) * 5;

            // Append to the price mapping list
            _priceMapping pushBack [typeOf _x, _price];
        } else {
            systemchat format["%1 is not a static weapon or reasonable deployable object",_x];
        };
    deleteVehicle _x;
    };
} forEach _syncedObjects;

//systemChat format["prices: %1",_priceMapping];

// Register the objects with ACE Fortify using the calculated prices
[_side, _budget, _priceMapping] call ace_fortify_fnc_registerObjects;
//cleanup
deleteVehicle _targetLogic;
