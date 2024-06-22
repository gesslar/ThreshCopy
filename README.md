# ThreshCopy
Convenient copy functions for ThresholdRPG

Use this feature to copy text from the game that can be useful for pasting in other situations. Functions are accessed after selecting text and then right-clicking them.

## Copy collapsed
Select text that is in a say, a tell, or a channel, to copy it in a collapsed manner. This is useful for removing all line feeds and indents from text and is ready to paste.

Example:
```
   Marble pillars about five feet high each stand at mid-intervals between the
dangling cords. On each of the pillars, a crystal vase bearing a single, fresh
red rose sits. The air is slightly warmer in this room, while light seems to
shimmer iridescently from the silks on the wall.
```
Results in the following in your clipboard

Marble pillars about five feet high each stand at mid-intervals between the dangling cords. On each of the pillars, a crystal vase bearing a single, fresh red rose sits. The air is slightly warmer in this room, while light seems to shimmer iridescently from the silks on the wall.

## Cloning this repository

To clone the repository with its submodules, use the following command:

```sh
git clone --recurse-submodules https://github.com/gesslar/ThreshCopy.git
```
If you have already cloned the repository, you can initialize the submodules with:
```sh
git submodule update --init --recursive
```

## Initialising or Updating Mupdate

1. **Open the Command Palette**:
   - Press `Ctrl+Shift+P` (Windows/Linux) or `Cmd+Shift+P` (Mac).
2. **Run the Task**:
   - Type `Run Task` and select `Run Task`.
3. **Choose the Task**:
   - Select `Update Mupdate Submodule` from the list.

This will update the Mupdate submodule and copy it to `resources/Mupdate.lua`