<img align="left" width="64" height="64" src="https://github.com/LiteFeather1/ltf-stopwatch/blob/main/assets/icons/icon_white.svg" alt="LTF Stopwatch icon">

# LTF Stopwatch

A simple stopwatch using the Godot Engine

<p align="center">
    <img src="https://github.com/LiteFeather1/ltf-stopwatch/assets/102820899/74bf5566-c7af-4241-809d-4b3d80bb3fb6" alt="LTF  Stopwatch Image" width="384"/>
</p>

## Features
### Stopwatch
All the good o' stopwatch features: Track your time, Start/Pause, Restart

### Copy Time
Press the Copy Button or Ctrl + C to copy to clipboard the elapsed time. Formatted as HH:MM:SS

### Paste-In Time
Press Ctrl + V to paste-in a time to modify the Stopwatch elapsed time. Formatted as HH:MM:SS Modifiers examples:
 - "=" - Resets the stopwatch to the specified time, e.g. "=1.25" resets the Stopwatch to 00:00:01.25.
 - "+" - Adds to the elapsed time, e.g. "+1:10" adds 1 minute and 10 seconds to the elapsed time.
 - "-" - Substracts the elapsed time, e.g. "-1:3:5" subtracts 1 hour, 3 minutes and 5 seconds of elapsed the time.

Note: the elapsed time cannot be a negative number.

### Restore Previous Stopwatch
Resetted the stopwatch by accident? No worries just press Alt + Z to restore the previous stopwatch

### Stopwatch Pause Entry Tray
   <img src="https://github.com/LiteFeather1/ltf-stopwatch/assets/102820899/96ed1ad2-8418-4780-8502-4a5e7ba51a1f" alt="LTF Stopwatch with pause entry tray " Width="256"/>

- Track your pauses.
- Hover a entry to check elapsed time of that entry.
- Left click a entry to delete an entry.
- Use Ctrl + Z to undo deleted entries. Use Ctrl + Y to redo deleting entries.
    #### Stopwatch Copy Entry Tray
  <img src="https://github.com/LiteFeather1/ltf-stopwatch/assets/102820899/9a498166-9a65-43f0-b7ad-7cb438ad6423" alt="LTF Stopwatch with copy entry tray menu" Width="256"/>
  
  Copy to clipboard your pause record, in for neat formats. Simple, Long, CSV or Markdown Table.
  With options to include:
  - Elapsed Time
  - Pause Span
  - Longest/Shortest entries.
 
       ##### Formatting Table
    |Pauses|Elapsed Time|Pause Time|Resume Time<br>(Optional)|Pause Span<br>(Optional)|Longest/Shortest<br>(Optional)|
    |:-|:-:|:-:|:-:|:-:|:-|
    |#1|00:30:43|14:53:12|15:30:37|00:37:25|Longest|
    |#2|01:20:12|16:20:06|16:30:07|00:10:01|Shortest|
    |#3|02:53:56|18:03:51| -- : -- : -- | -- : -- : -- |--|
    <br>

### Miscellaneous

__Pin__ - Press the Pin Button to keep the stopwatch on top of everything. By default it will move to the top left of the screen and be on the minimum size.

__Drag & Resize__ - Drag and resize the stopwatch like a regular window.

### Hotkeys
|Task|Set 1|Set 2|
|:-|:-|:-|
|Start/Pause/Continue Stopwatch|Ctrl + Space |Ctrl + Enter|
|Reset Stopwatch|Ctrl + R||
|Restore Last Stopwatch|Alt + Z||
|||
|Copy Current Time to Clipboard|Ctrl + C|Ctrl + Insert|
|Paste-In Time|Ctrl + V|Shift + Insert|
|Increase Time by One|Ctrl + Up Arrow|Ctrl + "+"|
|Decrease Time by One|Ctrl + Down Arrow|Ctrl + "-"|
|Increase Time by Five|Alt + Up Arrow|Alt + "-"|
|Decrease Time by Five|Alt + Down Arrow|Alt + "-"|
|||
|Undo deleted Entry|Ctrl + Z||
|Redo deleted Entry|Ctrl + Y|Ctrl + Shift + Z|
|Delete Entry|Delete Key + NUM Key|
|Fold/Unfold Entry Tray|Ctrl + F|Ctrl + T|
|||
|Pin Window|Ctrl + P||
|Minimise Window|Ctrl + M||
|Close Window|Ctrl + W|Ctrl + F4|
|||
|Move Window Left|Ctrl + Left Arrow||
|Move Window Right|Ctrl + Right Arrow||
|Move Window Up|Ctrl + Up Arrow||
|Move Window Down|Ctrl + Down Arrow||
|||
|Place Window Bottom Left|Ctrl + Keypad 1|Alt + 1|
|Place Window Bottom Center|Ctrl + Keypad 2|Alt + 2|
|Place Window Bottom Right|Ctrl + Keypad 3|Alt + 3|
|Place Window Center Left|Ctrl + Keypad 4|Alt + 4|
|Place Window Center|Ctrl + Keypad 5|Alt + 5|
|Place Window Center Right|Ctrl + Keypad 6|Alt + 6|
|Place Window Top Left|Ctrl + Keypad 7|Alt + 7|
|Place Window Top Center|Ctrl + Keypad 8|Alt + 8|
|Place Window Top Right|Ctrl + Keypad 9|Alt + 9|

#### Title bar
Mouse clicks events on the title bar
|Task|Set|
|:-|:-|
|Pin Window|Ctrl + LMB|
|Minimise Window|Ctrl + MMB|
|Max size/Min Size window|Double LMB|
|Open popup menu|RMB|
