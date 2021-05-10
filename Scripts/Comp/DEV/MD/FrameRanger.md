# Frame Ranger tools for Fusion

This is a script for managing ranges based on given frames offset.
Set amout of frame hangles to offset render range.  If you need 24 frames handles at the start and the end of the main asset, you can set this offset with a shortcut.

_Usage:_

* Use `>>`, `<<`, `<>`, `><` buttons to move In/OUT range to desired direction to set amount of frames.
* Set amount of frames handles to offset with a FrameRanger. The offset amount will be saved in comp data.
* Set/Reset frame handles with `ALT + F` shortcut or with `< >` or `> <` buttons.
* Save multiple IN/OUT ranges in comp data and set them with doubleclick on a list.
* Set Global Comp range based on selected Loader with `Set from Loader` button or with `CTRL + SHIFT + F`.
* Use `FR_MoveLoader` tool script (installed in `Scripts:Tool` folder) to move selected Loader(s) in a timeline to a given offsets amount forward. If no Frame Offset data is found in the comp, the Loader will be moved to the render In point.
* Move frame handles to the offset amount to the left or right, or inwards/outwards with dedicated buttons. Reset global render range with `Reset Globals` button. 

_Copyright:_ Alexey Bogomolov (mail@abogomolov.com)

_License:_ [MIT](https://mit-license.org/)

_Version History:_ v.1.0 - [2020/12/07]
                   v.1.5 - [2021/10/05]

_Donations:_ [PayPal.me](https://paypal.me/aabogomolov/5usd)
