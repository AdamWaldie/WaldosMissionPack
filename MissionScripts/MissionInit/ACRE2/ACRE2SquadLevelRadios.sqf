/*
Author: Waldo
This function sets up AN/PRC-343 Radio channels based on the group of the player based on callsign breakdown. This simply handles the group to channel mapping and ensure that all clients share these channels, actual radio setup takes place elsewhere.

Arguments:
_callsigns = list of callsigns to assign channels to

Returns:
Sets public variable of Waldo_ACRE2Setup_CallsignChannelAssignments with callsign-channel 2d array.

Example:
[_callsigns] call Waldo_fnc_SquadLevelRadios;
*/

if (!isServer) exitwith {}; //remember to uncomment this when you push to live you moron

params["_callsigns"];

// Gets purely the word part of the callsign (e.g Viking)
private _squadWordPartRegex = ["^([A-Za-z]+)"];
//Gets only the squad number (1-1 or 1 for example)
private _squadNumberPartRegex = ["(?<=[\s-])[.\d]+(?:[-.]\d+)?(?:\.\d+)?"]; //"(?<=[\s-])[.\d]+(?:[-.]\d+)?"


private _allocatedChannels = [];
private _callsignAndChannelAssignments = [];

//Generate Callsign/block dictionary for non [number]-[number] or [number].[number] assignments.
private _callsignBlockKeyPair = createHashMap;

{
    private _matchedCallsigns  = _x regexFind _squadWordPartRegex;
    private _extractedBlockCallsign = _matchedCallsigns  select 0 select 0 select 0;
    //systemChat format["%1",_extractedBlockCallsign];
    _callsignBlockKeyPair set [format["%1",_extractedBlockCallsign], (count _callsignBlockKeyPair + 1),true]; // set only if not existing
} forEach _callsigns;

//{ systemChat str [_x, _y] } forEach _callsignBlockKeyPair;

//Generate block to starting channel number conversion dictionary so that block numbers (1 to 16) can be put in, and the starting channel of that block is returned, and vice versa.
private _blockToStartNumber = createHashMap;

{
    _blockToStartNumber set [(_forEachIndex+1), _x];
} forEach [1, 17, 33, 49, 65, 81, 97, 113, 129, 145, 161, 175, 193, 209, 225, 241];// Verify whether ACRE starts from 0 or 1. Otherwise each of these after block 2 should be +1

//{ systemChat str [_x, _y] } forEach _blockToStartNumber;

{
    // Extract callsign and squad number using regular expressions
    _matchesCallsign = _x regexFind _squadWordPartRegex;
    _matchesSquadNumber = _x regexFind _squadNumberPartRegex;
    _extractedCallsign = "";
    _extractedSquadNumber = "";
    _blockStartNumber = 1;

    if (count _matchesCallsign > 0) then {
        _extractedCallsign = _matchesCallsign select 0 select 0 select 0;
        private _callsignForBlock = _callsignBlockKeyPair getOrDefault [_extractedCallsign,-1];
        if (_callsignForBlock > 16) then {_callsignForBlock = random [1,8,16]}; // If more than 16 distinct callsigns, select random between 1-16.
        if (count _matchesSquadNumber > 0) then {
			_extractedSquadNumber = (_matchesSquadNumber select 0 select 0 select 0);
        };
		//systemChat format ["Callsign: %1, Squad Designation: %2, Run: %3",_extractedCallsign, _extractedSquadNumber, _forEachIndex];

        _blockIndex = 16;
        _channelIndex = 16;
        _assignedChannel = nil;

        // Channel assignment for callsigns without a squad number
        if (_extractedSquadNumber == "") then {
            // Block Assignment
            if (_callsignForBlock != -1) then {
                //Assign channel number
                _blockStartNumber = _blockToStartNumber get _callsignForBlock;
                _blockIndex = _callsignForBlock;
            } else {
                _blockStartNumber = _blockToStartNumber get 16;
            };
            //systemChat format["_blockStartNumber: %1",_blockStartNumber];
            _blockEndNumber = _blockStartNumber + 15;
            {
                if (!(_x in _allocatedChannels)) exitwith {
                    _assignedChannel = _x;
                    _allocatedChannels pushBack _x;
                };
            } forEach [_blockStartNumber, _blockEndNumber];
            if (_assignedChannel == nil) then {
                {
                    if (!(_x in _allocatedChannels)) exitwith {
                        _assignedChannel = _x;
                        _allocatedChannels pushBack _x;
                    };
                } forEach [255, 1];
            };          
        } else {
            // Channel assignment for callsigns with a squad number
            if (_extractedSquadNumber find ["-",0] > 0 || _extractedSquadNumber find [".",0] > 0) then {
                // Platoon and Squad Indicators
                private _numbers = (_extractedSquadNumber splitString "-.");
                if (count _numbers >= 2) then {
                    _blockIndex = floor(parseNumber(_numbers select 0));
                    _blockStartNumber = _blockToStartNumber get _blockIndex;
                    _channelIndex = floor(parseNumber(_numbers select 1)-1); // -1 so that when added to block number, it fits properly in block e.g. Block 2 channel 1 is 17, so _channelIndex must be 1 to add to 16 to get 17.
                    private _hopefullyUnusedChannel = _blockStartNumber + _channelIndex;
                    if ((_hopefullyUnusedChannel in _allocatedChannels)) then {
                        {
                            if (!(_x in _allocatedChannels)) exitwith {
                                _assignedChannel = _x;
                                _allocatedChannels pushBack _x;
                            };
                        } forEach [_blockStartNumber, 255];
                        if (_assignedChannel == nil) then {
                            {
                                if (!(_x in _allocatedChannels)) exitwith {
                                    _assignedChannel = _x;
                                    _allocatedChannels pushBack _x;
                                };
                            } forEach [255, 1];
                        };
                    } else {
                        _assignedChannel = _hopefullyUnusedChannel;
                        _allocatedChannels pushBack _hopefullyUnusedChannel;
                    };
                };
            } else {
                // Just Squad Indicators
                // Block Assignment
                if (_callsignForBlock != -1) then {
                    //Assign channel number
                    _blockStartNumber = _blockToStartNumber get _callsignForBlock;
                    _blockIndex = _callsignForBlock;
                } else {
                    _blockStartNumber = _blockToStartNumber get 16;
                };
                //systemChat format["_blockStartNumber: %1",_blockStartNumber];
                _channelIndex = floor(parseNumber(_extractedSquadNumber)-1);
                //systemChat format["_channelIndex: %1",_channelIndex];
                private _hopefullyUnusedChannel = _blockStartNumber + _channelIndex;
                //systemChat format["_hopefullyUnusedChannel: %1",_hopefullyUnusedChannel];
                if ((_hopefullyUnusedChannel in _allocatedChannels)) then {
                    {
                        if (!(_x in _allocatedChannels)) exitwith {
                            _assignedChannel = _x;
                            _allocatedChannels pushBack _x;
                        };
                    } forEach [_blockStartNumber, 255];
                    if (_assignedChannel == nil) then {
                        {
                            if (!(_x in _allocatedChannels)) exitwith {
                                _assignedChannel = _x;
                                _allocatedChannels pushBack _x;
                            };
                        } forEach [255, 1];
                    };
                } else {
                    _assignedChannel = _hopefullyUnusedChannel;
                    _allocatedChannels pushBack _hopefullyUnusedChannel;
                };
            };
        };

        // Visual Conversion of Block & Channel form int value.
        _blockConvert = floor((_assignedChannel / 16)+1);
        if (_blockConvert < 1) then {_blockConvert = 1};
        _channelConvert = (_assignedChannel % 16);
        if (_channelConvert < 1) then {_channelConvert = 1};

        // Output the assigned channel or a message if no channel is available
        if (isNil "_assignedChannel") then {
            systemChat format ["%1, %2 Channel Not Found",_extractedCallsign, _extractedSquadNumber];
        } else {
            systemChat format ["%1 %2 Block: %3 Channel: %4 (%5)",_extractedCallsign, _extractedSquadNumber, _blockConvert, _channelConvert, _assignedChannel];
            _callsignAndChannelAssignments append [[_x,_assignedChannel]];
        };
    } else {
        systemChat "ACRE2 SLR Setup failed to locate a callsign";
    };
    systemChat "-----";
} forEach _callsigns;

systemchat format ["_callsignAndChannelAssignments: %1",_callsignAndChannelAssignments];

//Make Public Variable with assignments
missionNamespace setVariable ["Waldo_ACRE2Setup_CallsignChannelAssignments", _callsignAndChannelAssignments,true];
missionNamespace setVariable ["Waldo_ACRE2Setup_CallsignChannelAssignments_flag", true,true];