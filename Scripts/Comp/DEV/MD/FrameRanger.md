# FrameRanger tools

This is a script for managing ranges based on given frames offset.
I wrote this tiny script to simplify workflow with the assets rendered with frame handles. Usually it is not necessary to render those handles. In case you have to render the assets with, say, 24 frames handles at the start and the end of the main asset, you can set this offset with a single shortcut.

_Usage:_

* Set desired frames offset with a RrameRanger UI. The default offset will be saved to the comp data.
* Set/Reset frame handles with `ALT+F` shortcut.
* Set Globals In and Out based on selected Loader with `ALT+SHIFT+F` shortcut (this is amy favotire, actually. I use it all the time)
* Use `MoveLoader` tool script to move selected Loader(s) in a timeline to a given offsets amount forward. It comes handy in case you need to put a lot of assets to a comp with frame handles. If no Frame Offset data is found in the comp, the Loader will be moved to the render In point.
* Move frame handles to the offset amount to the left or right, or inwards/outwards with dedicated buttons. Reset global render range with `Reset Globals` button. These buttons seems completely unnecessary, but, you know, I like buttons.

_Copyright:_ Alexey Bogomolov (mail@abogomolov.com)

_License:_ [MIT](https://mit-license.org/)

_Version:_ v.1.0 - [2020/12/07]

_Donations:_ [PayPal.me](https://paypal.me/aabogomolov/5usd)