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
|Task|Set 1| Set 2|
|:-|:-|:-
|Start/Pause/Continue Stopwatch|Ctrl + Space |Ctrl + Enter|
|Reset Stopwatch|Ctrl + R||
|Copy Current Time to Clipboard|Ctrl + C||
|Undo deleted Entry|Ctrl + Z||
|Redo deleted Entry|Ctrl + Y|Ctrl + Shift + Z|
|Fold/Unfold Entry Tray|Ctrl + F|Ctrl + T|
|Pin Window|Ctrl + P||
|Minimise Window|Ctrl + M||
|Close Window|Ctrl + W|Ctrl + F4|

#### Title bar
Mouse clicks events on the title bar
|Task|Set|
|:-|:-|
|Pin Window|Ctrl + LMB|
|Minimise Window|Ctrl + MMB|
|Max size/Min Size window|Double LMB|
|Open popup menu|RMB|
