/*
Author: Waldo
This is a hollow proceedure to call the headless client, and allow a parameter selector for it in the pre-mission slot screen.

*/

if ((_this select 0) == 1) then
{	// Run on the HC only
	if !(isServer or hasInterface) then
	{
		[true,30,false,true,30,10,true,[]] spawn Waldo_fnc_WerthlesHeadless;
	};
} else {
	// Run on the server only
	if (isServer) then
	{
		[true,30,false,true,30,10,true,[]] spawn Waldo_fnc_WerthlesHeadless;
	};
};