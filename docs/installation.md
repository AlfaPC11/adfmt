<!-- SPDX-License-Identifier: BSL-1.0 -->

# Installing adfmt

The recommended installation method is a versioned package from
[GitHub Releases](https://github.com/AlfaPC11/adfmt/releases). Prebuilt
packages currently target x86-64 (`x86_64` or `amd64`). Other architectures
must build adfmt from source.

## Choose a package

| System | Release asset |
|---|---|
| Arch Linux | `adfmt-<version>-1-x86_64.pkg.tar.zst` |
| Debian or Ubuntu | `adfmt_<version>_amd64.deb` |
| Fedora or another RPM-based distribution | `adfmt-<version>-1.x86_64.rpm` |
| Windows x86-64 | `adfmt-<version>-windows-x86_64-setup.exe` |
| Windows portable | `adfmt-<version>-windows-x86_64.exe` |
| Source build | `adfmt-<version>-source.tar.gz` or the Git repository |

Download `SHA256SUMS` from the same Release when installing a downloaded
binary. On Linux, place it beside the package and verify the files that are
present:

```sh
sha256sum --check --ignore-missing SHA256SUMS
```

Do not install a package if its checksum fails.

## Arch Linux

From the directory containing the downloaded package:

```sh
sudo pacman -U ./adfmt-*-x86_64.pkg.tar.zst
```

The package installs `adfmt` into `/usr/bin`, documentation into
`/usr/share/doc/adfmt`, and Bash completion into the system completion
directory.

## Debian and Ubuntu

Use APT so package dependencies are resolved:

```sh
sudo apt install ./adfmt_*_amd64.deb
```

## Fedora and RPM-based distributions

On Fedora, install the local RPM with DNF:

```sh
sudo dnf install ./adfmt-*.x86_64.rpm
```

Other RPM-based distributions may use their native package manager. The
package requires compatible `glibc` and GCC runtime libraries.

## Windows

The setup package is the recommended Windows installation:

1. Download `adfmt-<version>-windows-x86_64-setup.exe` and `SHA256SUMS` from
   the same GitHub Release.
2. Compare the installer's SHA-256 hash with the corresponding entry in
   `SHA256SUMS`:

   ```powershell
   Get-FileHash .\adfmt-0.4.0-windows-x86_64-setup.exe -Algorithm SHA256
   ```

3. Run the installer and leave the `Add the adfmt installation directory to
   the user PATH` task selected.
4. Open a new terminal and verify the installation:

   ```powershell
   adfmt --version
   ```

The installer uses `%LOCALAPPDATA%\Programs\adfmt` by default and does not
require administrator privileges. It is not currently code-signed, so Windows
may show an unknown-publisher warning; verify the checksum before continuing.
See [windows.md](windows.md) for portable use, PATH behavior, and uninstall
details.

## Build from source

Install a D compiler, DUB, and Git. LDC is the recommended compiler for
release builds. Clone all submodules and build:

```sh
git clone --recurse-submodules https://github.com/AlfaPC11/adfmt.git
cd adfmt
dub build --build=release --compiler=ldc2
```

On Linux, install the resulting executable for the current user:

```sh
install -Dm755 bin/adfmt "$HOME/.local/bin/adfmt"
```

Ensure `$HOME/.local/bin` is in `PATH`. A system-wide installation can instead
place the executable in `/usr/local/bin` with the appropriate privileges.

On Windows, after installing DUB and LDC, run:

```cmd
build.cmd
```

Use `build.cmd debug` for a debug build. The resulting executable is placed in
`bin`.

## Install the VS Code extension

The formatter executable and the editor extension are separate. Install adfmt
using one of the methods above, then install the extension from Marketplace:

```sh
code --install-extension alfa.adfmt
```

An offline `.vsix` is also available from the
[adfmt-vscode Releases](https://github.com/AlfaPC11/adfmt-vscode/releases):

```sh
code --install-extension ./adfmt-0.3.0.vsix
```

Enable formatting when a D file is saved:

```json
{
  "[d]": {
    "editor.defaultFormatter": "alfa.adfmt",
    "editor.formatOnSave": true
  }
}
```

If `adfmt --version` works in a terminal but VS Code cannot find it, restart
VS Code so it receives the updated `PATH`, or set `adfmt.executablePath` to the
absolute executable path.

## Verify and start using adfmt

```sh
adfmt --version
adfmt --help
```

Create an extensionless `.adfmt` YAML file in the project root, then see
[configuration.md](configuration.md) and [examples.md](examples.md) for the
available styles and options.
