# Proton Kernel for WSL 2

Proton Kernel is a custom modified Linux kernel for the [Windows Subsystem for Linux 2](https://devblogs.microsoft.com/commandline/announcing-wsl-2/), using a [clean import of Microsoft's kernel changes](https://github.com/kdrag0n/msft-wsl2-kernel) as a base. The goal is to improve performance, memory utilization, and power efficiency while reducing boot times and making other improvements to the overall user experience.

## Motivation

Microsoft did a relatively good job on their minimal set of changes to the Linux kernel in WSL 2, but there is always room for improvement. For example, one can compile the kernel with a newer version of GCC (Microsoft used a custom build of GCC 7.3.0) or even Clang. This can offer small performance improvements and help debug certain parts of both the kernel and the compiler.

Proton Kernel aims to improve upon Microsoft's kernel in every aspect and thus improve the overall WSL 2 user experience.

## Compilation

1. Install a recent Linux distribution
	- Any install will work — WSL 1, WSL 2, VirtualBox, bare-metal, etc.

2. Install GCC or Clang, essential development packages, `flex`, `bison`, OpenSSL + headers, `libelf` + headers
	- Example command for Ubuntu: `apt install build-essential flex bison libssl-dev libelf-dev`

3. Load the Proton Kernel helpers (optional)
	- Note that this requires a Bourne-compatible shell, such as `bash` or `zsh`
	- Command: `source setup.sh` for GCC or `source setup_clang.sh` for Clang
	- These helpers are solely to simplify the building and testing process and are not mandatory by any means
	- Parallel Kbuild job count can be adjusted in the `setup` scripts
		- The optimal value for build times is usually the number of logical CPU cores present on your system
		- Sometimes increasing or decreasing this number helps reduce build time further

4. Select the WSL 2 kernel configuration
	- Using the Proton helpers: `mc`
	- Using plain Kbuild: `make wsl2_defconfig`

5. Start the kernel build
	- Using the Proton helpers: `kmake`
	- Using plain Kbuild: `make`
		- If you have multiple CPU cores, you can pass a `-jX` argument (where `X` is the number of logical CPU cores present on your system) to speed up the build by parallelizing the process
		- Sometimes increasing or decreasing this number helps reduce build time further

Assuming there were no errors and everything worked as intended, you will find the new kernel at the following location:
  - Using Proton helpers: `out/arch/x86/boot/compressed/vmlinux.bin`
  - Using plain Kbuild: `arch/x86/boot/compressed/vmlinux.bin`

If not, double-check each command to make sure you did everything correctly. You can [open an issue](https://github.com/kdrag0n/proton_wsl2/issues/new) if you need help resolving a build error.

## Installation

**BE SURE TO MAKE A BACKUP OF THE OFFICIAL KERNEL PRIOR TO REPLACEMENT!** Otherwise, you will be unable to revert if your custom kernel fails to boot or malfunctions.

**Warning:** Having **any** unofficial kernel installed currently breaks distribution installation and conversion for unknown reasons and causes the process to lock up. A temporary workaround is to use the official kernel for the aforementioned tasks, then revert back to your custom kernel afterwards.

The kernel is located at `C:\Windows\System32\lxss\tools\kernel` in Windows.

### Preparation

When you first replace the WSL 2 kernel on your system, you will need to grant yourself the permissions necessary to replace the file. This requires administrator access.

1. Assign ownership of the `kernel` file to the **Administrators** group
	- This is easy to do in Windows Explorer:
		- Right-click the file and click **Properties**
		- Switch to the **Security** tab
		- Click the **Advanced** button
		- Click the blue **Change** button next to **Owner**
		- Enter **Administrators** for the object name
		- Click **OK** to close the advanced security window and reload permissions

2. Grant **Full Control** of the file to **Administrators** and yourself
	- Again, this is trivial in Windows Explorer:
		- Return to the advanced security management window
		- Click the **Change permissions** button
		- Double-click **Administrators** in the list of permission entries and check the **Full Control** box
		- Dismiss the entry control dialog
		- Click the **Add** button to add a new permission entry
		- Click the blue **Select principal** button at the top and enter your username at the object name prompt
		- Check the **Full Control** box
		- Dismiss the entry control dialog

After taking ownership and acquiring critical permissions, you may proceed to the kernel replacement steps listed below. These preparatory steps may need to be repeated after each Windows update.

### Kernel replacement

#### Automatic (for users of the Proton Kernel helpers)

- Run the desired command(s) from the list below:
	- Copy the product to `kernel.bin`: `cpimg`
	- Build and copy: `incbuild`
	- Build, copy, and test: `inc`
	- Test: `ktest`

Note that `ktest` looks for `kernel.bin` for ease of management, **not** the build product (`out/arch/x86/boot/compressed/vmlinux.bin`). This means that you will need to either use `incbuild` to build or run `cpimg` after each build to copy the new kernel to `kernel.bin`.

#### Manual

1. Shut down the WSL 2 distros and utility VM from Windows
	- Command: `wsl --shutdown`

2. Rename the new kernel (`vmlinux.bin`) to `kernel`

3. Copy the new `kernel` to `C:\Windows\System32\lxss\tools` and choose to overwrite the existing file named `kernel`

Be sure to **copy** and **overwrite** the kernel. Doing otherwise (moving, deleting and recreating, etc.) will invalidate the hard link in `WinSxS`, which may cause issues when updating or repairing the system in the future. **You have been warned.**

## Helpers

The Proton Kernel helper scripts provide a handy set of helpers that enhance the overall kernel development and deployment experience. You can use them in a Bourne-compatible shell by `source`ing one of the compiler-specific setup scripts — `source setup.sh` for GCC and `source setup_clang.sh` for Clang. If you don't want to use one of those scripts, you can also directly run `source helpers.sh`. However, this setup is not supported nor encouraged and **may break at any time**.

Keep in mind that you must **`source`** the scripts instead of executing them. Nothing will happen if you execute them because they simply define variables and functions for interactive use. They are **not** build scripts. The execute bit is missing on them for this very reason.

### Functions

- `croot`: `cd` to the root of the kernel tree, where the helper scripts are
- `cpimg`: Copy the product to the specified path, defaulting to `kernel.bin`
  - `dimg`: Copy the product to `builds` with a file name tailored for development/test releases
    - `timg`: Run `dimg`, then upload the resulting file to [transfer.sh](https://transfer.sh/)
- `kmake`: A wrapper for `make` that passes the defined kernel-oriented arguments
  - `cleanbuild`: Perform a clean build and run `cpimg`
  - `incbuild`: Perform an incremental build and run `cpimg`
  - `dbuild`: Perform an incremental build and run `dimg`
    - `tbuild`: Perform an incremental build and run `timg`
- `rel`: Build and copy the product to `builds` with a file name and version tailored for stable releases
  - `crel`: Clean the built object files and run `rel`
- `ktest`: Install `kernel.bin` using an auto-selected method (`wktest` for WSL 1 and WSL 2, `vktest` for other environments)
  - `wktest`: Install `kernel.bin` locally from either WSL 1 or WSL 2
  - `vktest`: Install `kernel.bin` into WSL 2 in the Windows VM running on a bare-metal Linux host (using the `winvm` SSH host)
- `inc`: Perform an incremental build and install the product using an auto-selected method (`wktest` for WSL 1 and WSL 2, `vktest` for other environments)
  - `winc`: Perform an incremental build and install the product locally from either WSL 1 or WSL 2
  - `vinc`: Perform an incremental build and install the product into WSL 2 in the Windows VM running on a bare-metal Linux host (using the `winvm` SSH host)
- `dc`: `diff` the current config with `wsl2_defconfig`
- `cpc`: Update `wsl2_defconfig` with the current config
- `mc`: Reset the current config to `wsl2_defconfig`
- `cf`: Start an interactive config editor with a TUI (`nconfig`)
- `ec`: Open the raw current config in a text editor
- `buildnum`: Get the current build number
- `zerover`: Reset the build number to `0`
- `zver`: Get the version string from an uncompressed kernel image
- `osize`: Get a sorted list of the sizes of various objects compiled and linked into the final kernel image
- `glink`: Get a link to the provided commit hash in this repository on GitHub

All building helpers will propagate the arguments passed to them to `make`.
