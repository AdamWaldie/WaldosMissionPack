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

### In-File Header - the canonical template
Every script file (`.sqf`) should open with this block. Functions that operate on `_this` still list their logical arguments. Use `None` / `Nothing` where appropriate.

```
/*
 * Author: Waldo
 * One-line description of what the script does, and where/how it is used.
 *
 * Arguments:
 * 0: _firstArg <OBJECT> - what it is
 * 1: _secondArg <BOOL> - what it is (optional, default: false)
 * (or "None")
 *
 * Return Value:
 * <TYPE> - description  (or "Nothing")
 *
 * Example:
 * [_firstArg, _secondArg] call Waldo_fnc_SomeFunction;
 */
```
Notes:
* If a file begins with `#include` lines, put the header **after** them (the validator requires `#include` before any block comment).
* For third-party scripts, preserve the original attribution and add a short note on how WMP uses it - do not claim authorship.
* Registering a new function? The header is step one; you must also add the class entry in `MissionScripts\WaldosFunctions.sqf`.

## Feature Documentation Standard
A "feature" is a user-facing capability (a system, a Zeus module, a script a mission maker calls). When you add or change one, document it in **all** of these places so it stays discoverable:
1. **In-file headers** - on every script that makes up the feature (above).
2. **`CLAUDE.md`** - a short section under *Feature Configuration Guide* covering what it does, the config flags/variables, and a minimal usage example; plus a one-line entry in the *MissionScripts Directory Layout* list if it adds a folder.
3. **`README.md`** - one bullet in *Pack Features*.
4. **Wiki** - a feature page following the Wiki Page Standard below, linked from `Feature-Tutorials.md`.

Keep terminology identical across all four (same feature name, same variable names).

## Wiki Page Standard
Wiki pages are the mission-maker-facing guides; optimise them for usability. A feature page should contain, in order:
1. An *Associated Files* italic line naming the scripts/functions involved, e.g. `_Associated Files: MissionScripts\Foo\Bar.sqf (Waldo_fnc_Bar)_`.
2. A one-paragraph **overview** - what the feature is and why a maker would use it.
3. **Setup** - the minimal steps to turn it on (init-file edits, Eden placement, or a composition), with copy-pasteable code blocks.
4. **Usage / options** - parameters and behaviours, ideally in a table.
5. **Examples** - at least one realistic, copy-pasteable example.
6. A **See also** list linking related pages.

Large features get a **hub page** plus one sub-page per sub-system (see *Waldos Economy Systems*). Write in plain language; assume the reader is a mission maker, not a scripter.

## Adding a Feature - documentation checklist
- [ ] Header block on every script file
- [ ] Function(s) registered in `WaldosFunctions.sqf`
- [ ] `CLAUDE.md` feature section (+ directory-layout line if needed)
- [ ] `README.md` Pack Features bullet
- [ ] Wiki page(s) following the Wiki Page Standard, linked from `Feature-Tutorials.md`
- [ ] Both validators pass (`sqf_validator.py`, `config_style_checker.py`)

# Code Conventions
## ACE Coding Guidelines
Please adhere to the [ACE CODING GUIDELINES](https://github.com/acemod/ACE3/blob/master/docs/wiki/development/coding-guidelines.md) where possible

## Specific differences to the ACE Coding Guidelines
* Constants are types in full capitals: CONSTANT
* Variables are to be in lower camel case: variablesAreFun , _variablesAreFun 
* Functions are to be in upper camel case: Waldo_fnc_UpperCamelCaseFunction