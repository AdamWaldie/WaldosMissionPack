0 = [this, Bren44PlatCom] call BIS_fnc_attachToRelative;

[this, this] call ace_common_fnc_claim; // prevent other ACE Options While connected to the object on start

inGameUISetEventHandler ["action",  
  " _action = _this select 4;  
    if ( _action in ['Unmount MG','Turn left','Turn right'] ) then { 
        hint 'You cannot do that!'; 
        true 
    } else { 
        false 
    } 
  "  
];


//From vehicle weapon is mounted in to attached weapon
this addAction ["Get in Top Bren",{moveOut (_this select 1);(_this select 1) moveingunner Bren44GunPlatCom;},nil,1.5,true,true,"","true",4,false,"",""];