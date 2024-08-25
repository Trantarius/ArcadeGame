# Starshot

### Features
- A 0G movement system
- 3 different weapons to choose from
- 5 different active abilities
- Various upgrades
- 4 types of enemies + 1 boss
- An online and offline leaderboard

### Controls
- W to thrust forward, A to turn left, D to turn right. You can also use the arrow keys.
- Space to activate an attack ability (you need to find one first).
- Left shift to activate a movement ability (also needs to be found first).
- Super secret button for god powers.

### Running
The game can be run with the regular binary releases. If this doesn't work, you can also run it by running ```godot``` from the project folder (the project will need to be opened in the editor first to import resources). You need only the game client to play; the server provides the online leaderboard. The ```--net_verbose=<0|1|2>``` argument controls how much network info is printed to stdout, where n is 0, 1, or 2. The ```--host=<ip:port>``` argument directs the game client where to look for the server. When running the server (either with the binary or ```godot server.tscn```), the ```--port=<port>``` argument chooses the port the server is hosted on (this has no effect when running the client).

### Exporting
The game is made with Godot 4.2. Export profiles for Windows, Linux, and the server (on Linux) are included. These profiles should be able to be exported with [the standard export process](https://docs.godotengine.org/en/4.2/tutorials/export/exporting_projects.html).