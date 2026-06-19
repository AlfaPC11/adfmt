<!-- SPDX-License-Identifier: BSL-1.0 -->

# Windows installation

The `adfmt-<version>-windows-x86_64-setup.exe` package is built with Inno Setup
on a native Windows GitHub Actions runner. It installs for the current user and
does not require administrator privileges.

## Installed paths

The default installation directory is:

```text
%LOCALAPPDATA%\Programs\adfmt
```

The formatter executable is:

```text
%LOCALAPPDATA%\Programs\adfmt\adfmt.exe
```

The installer also places `LICENSE.txt`, `PATENTS`, `NOTICE`, and `README.md`
in that directory. A different destination can be selected in the setup
wizard.

## PATH integration

The `Add the adfmt installation directory to the user PATH` task is selected
by default. It modifies only the current user's `PATH`; the system-wide
environment and other users are not changed.

Open a new terminal after installation, then verify:

```powershell
adfmt --version
```

The installer records both whether it added the directory and the exact entry
it added. The uninstaller removes only that normalized entry while preserving
unrelated and empty entries. A matching PATH entry that existed before
installation is left untouched. If the PATH task was not selected, adfmt can
still be run using its full executable path.

## Portable executable

The non-setup `adfmt-<version>-windows-x86_64.exe` asset is portable. It does
not modify `PATH`, create shortcuts, or install documentation. Rename or place
it as desired and invoke it directly.
