# CREATOR hardware integration

**version 1.0**

ESP-IDF ver 5.3 + Python 3.9

What's new:

* **New library added:** CREATino library
  * Make your own ARDUINO proyect using RISC-V assembly . Using the same syntaxis!!
    * **Libraries added:** Arduino. h (https://docs.arduino.cc/language-reference/#functions) and Serial.h (https://docs.arduino.cc/language-reference/en/functions/communication/serial/) functions.
    * ⚠️ I**MPORTANT**: check up the Arduino Support checkbox + follow pre-requisites shown in "Local Device > Prerrequisites > Native " in Target Flash page
    * HINT: A simple way to createrograms is first try it in C++/arduino and then, transform it to assembly code .
* **New buttons:**
  * Clean: Cleans up previous builds from the mode wanted (CREATOR or CREATino mode)
  * Erase-Flash: Cleans up previous programs flashed in the board. In order to make sure everything is well-cleaned, unplug and plug the board.
  * Debug: Opens up GDBGUI page to debug your program step-to-step + starts monitor session to follow up whatever is running at the step debugged.
    * ⚠️ **IMPORTANT:** Please follow up prerrequisites in the target-flash menu and have a JTAG devices plugged
    * Sometimes it shows up 'gdb_exception_error'. Most of the times is a hardware issue, you can unplug-plug and run again, or just refresh the page. If it shows another type of issue, please send it to the official page. Feedback makes us grow :)
  * Stop button: Stops motitor or debugging sessions (similar to ctrl + ] or ctrl + T + X shortcuts in terminal)
* **New interface:**
  * **New info sections:**
    * Creatino info: Informs about the use of the different functions added in the library.
    * Board info: Shows up Board GPIO ports for an easy setup
  * **New Library section:**
    * Load arduino library: Shortcut in order to add the new CREATino library
  * Added feedback to Target-Flash actions.
