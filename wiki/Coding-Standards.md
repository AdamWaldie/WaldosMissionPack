The following will note the standards that I attempt to uphold in the making of this pack. As I am but one man, however, and with this being a side project, the pack may not always be to this standard. Refactor and "standard" passes are committed every three months or so to bring severe cases in line with this standard where possible.

# Text Editor
You are free to select your own text editor for the creation or editing of your scripts, but I would advise selecting Visual Studio Code & Its SQF plugins. It'll make any script reading in Arma 3 easier on you! 
- Visual Studio Code: https://code.visualstudio.com/
- SQF Language Extension: https://marketplace.visualstudio.com/items?itemName=vlad333000.sqf
- SQF Debugger Extension: https://marketplace.visualstudio.com/items?itemName=billw2011.sqf-debugger


# Documentation
Document the usage and generalised workings of a script to the best extent possible using comments and a script header. Clarity of the purpose of the script, where and how it can or is used should be the highest priority for maintenance and end-user purposes.

## Script Header Requirements
The script header is a large commented block at the head of the script, usually containing information about the script in question. This should contain the following:
* Author of the script
* Description of the purpose of the script, what it does and how
* Break down the arguments, their position in the call and what type they can be
* Return value if any
* Example usage of the script

### Script Header Example
```
 /*
 * Author: myName, aGuyThatFixedTheFuctionName 
 * Description of the function.
 *
 * Arguments:
 * _argument1 - Vehicle/Object/Crate <OBJECT>
 * _argument2 -  DescriptionOnParam <OBJECT/BOOL/NUMBER/STRING/ARRAY/CODE> (Optional) (Default; MyDefaultValue) 
 * _argument3 -  DescriptionOnParam <OBJECT/BOOL/NUMBER/STRING/ARRAY/CODE> (Optional) 
 *
 * Return Value:
 * PotentialReturnValueDescriprion <BOOL/NUMBER/STRING>
 *
 * Example:
 * [thus,true,1,"string"] call Waldo_fnc_SomeFunction
 *
 * 
 */
```

# Code Conventions
## ACE Coding Guidelines
Please adhere to the [ACE CODING GUIDELINES](https://github.com/acemod/ACE3/blob/master/docs/wiki/development/coding-guidelines.md) where possible

## Specific differences to the ACE Coding Guidelines
* Constants are types in full capitals: CONSTANT
* Variables are to be in lower camel case: variablesAreFun , _variablesAreFun 
* Functions are to be in upper camel case: Waldo_fnc_UpperCamelCaseFunction