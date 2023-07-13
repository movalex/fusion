# Frame Ranger tools for Fusion

This is a script for managing ranges based on given frames offset.
Set amount of frame handles to offset render range.  If you need 24 frames handles at the start and the end of the main asset, you can set this offset with a shortcut.
Save IN/OUT render points in comp data for later reuse. Set comp render range based on a selected Loader.

_Usage:_

* Set amount of frames handles to offset with a Frame Ranger. The offset amount will be saved in comp data.
* Set/Reset frame handles with `ALT + F` shortcut or with `< >` or `> <` buttons.
* Use `> >`, `< <`, buttons to move In/OUT range to desired direction to the set amount of frames. 
* Reset global render range with `Reset Globals` button. 
* Save multiple IN/OUT ranges with `Save Range` button or with `SHIFT + F` (even if the Frame Ranger is not launched). Set range with doubleclick on a list item.
* Set Global Comp range based on selected Loader with `Set from Loader` button or with `SHIFT + CTRL + F` (`SHIFT + CMD + F` on MacOS).
* Move frame handles to the offset amount to the left or right, or inwards/outwards with dedicated buttons. Reset global render range with `Reset Globals` button. 

_Copyright:_ Alexey Bogomolov (mail@abogomolov.com)

_License:_ [MIT](https://mit-license.org/)
