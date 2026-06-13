Associated Files: MissionScripts\MissionInit\ACRE2\SquadLevelRadios.sqf

This function sets up AN/PRC-343 Radio channels based on the group of the player based on callsign breakdown. 

This handles the group-to-channel mapping and ensures that all clients share these channels.

It sets up Block And Channel allocation based upon the callsigns list provided. This is by default via ACRE2Init.sqf as below:
![](https://i.imgur.com/3CHplvL.png)

# Logic Used

The logic behind this setup is as follows:
1. If a callsign has two numbers separated by either a hyphen or a full stop then the block number is designated as the first number, and the channel is the second. 
2. If a callsign has either no number, or a single number a block is selected based on the index of the callsign in the list of callsigns provided. 
    * In the case of the above example SUNRAY is Block 1, Foxhound is Block 2 and so on.
    * If a callsign then has a number, its channel is set to that number in the block.
    * If a callsign does not have a number, its channel is assigned based on the lowest number available in that block.
3. If any of this fails, it assigns each squad a unique channel working backwards from 256. If a double up is detected due to a conflict in logic, the channel is set to the highest available.

