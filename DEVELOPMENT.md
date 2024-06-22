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

This will update the Mupdate submodule and copy it to `resources/Mupdate.lua` to be included in your package before you run muddler.