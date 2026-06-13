_Associated Files: MissionScripts\MissionInit\ACRE2Init.sqf_

This script allows for the automatic pre-setting of radio channels for ACRE 2 Radios based on the group name.

This script Must only be called from the init.sqf.

Your group must be named in the editor, you should use the CBA lobby screen naming functionality as well, and finally, ingame group names must match the name given in the parameters.

The following radios are supported:
* AN/PRC 343 (Setup Automatically and without manual setup in the parameters)
* AN/PRC 152
* AN/PC 148
* AN/PRC 117F

AN/PRC-343 Radios are automatically set up depending on the Squads callsign. See Squad Level Radios for more information, although you do not have to do anything to get that, or the CEOI to work.

LR and SR radios are placed into an automated CEOI after use, see ACRE Automated CEOI for more details. Babel support and Language Documentation is also available - See ACRE Babel Activation for more details.

## Setup And Examples

1. In the init.sqf find the ACRE 2 setup section. It should look similar to the below:

![Image of the ACRE2Init function call in the init.sqf](https://i.imgur.com/17lESXb.jpg)

2. Uncomment the function call if it has been commented out (Remove the /* and */). Use VS code as described in the quickstart to make it easier for you.

3. The mission maker must then specify up to three Long Rang Radio channels:

`["Callsign",[channel_num_1,channel_num_2,channel_num_3]]`

Where the "Callsign" matches the group name you entered in the group's Callsign attribute.

![Example of the Callsign in a group init](https://i.imgur.com/wbOvpxC.jpg)

And where channel_num_1,channel_num_2 and channel_num_3 indicate up to three channels you want that groups Long Range Radio holders to be tuned into. Channels will be set from left to right, starting at channel_num_1 and ending at channel_num_3. Channels will also be set on the shortest range radio first - so the 152 and 148 first, followed by the 117F. Channels will only be assigned if the player has enough LR radios to set the number of channels.

Please note that all parameters must be given regardless of whether that group has or has not got any of those radios and that each line bar the last should have a comma at the end.

Below is an example of the code, and the associated ingame setup to make this system work.

![Example of a ACRE2 setup call from init.sqf](https://i.imgur.com/17lESXb.jpg)

![Example of Thor and Odin groups, named correctly in callsign](https://i.imgur.com/wbOvpxC.jpg)


Channel Naming is not supported. This is due to the fundamental method required to make that function work not being possible with the approach of this pack. For channel naming to work, radios must be added via a loadout script. This is not how we approach loadouts in the pack, and as such, channel naming instead breaks the radios - therefore, I do not support it.