#
# Interactive helpers for WSL2 kernel compilation
# Copyright (C) 2019 Danny Lin <danny@kdrag0n.dev>
#
# This script must be *sourced* from zsh (bash is NOT supported) in order to
# function. Nothing will happen if you execute it.
#
# Sourcing a compiler-specific setup script instead of directly sourcing this
# file is highly recommended because it provides additional configuration
# options and has withstood more thorough testing.
#


#### CONSTANTS ####

# Root of the kernel repository for use in helpers
kroot="$(pwd)/$(dirname "$0")"

# Defconfig name
defconfig="wsl2_defconfig"

# Base kernel compile flags (extended by compiler setup script)
kmake_flags=(
	"-j${jobs:-6}"
	"ARCH=x86"
	"O=out"
)


#### BASE ####

# Show an informational message
function msg() {
    echo -e "\e[1;32m$1\e[0m"
}

# Show an error message
function err() {
    echo -e "\e[1;31m$1\e[0m"
}

# Go to the root of the kernel repository
function croot() {
	cd "$kroot" || return
}

# Get the version of Clang in an user-friendly form
function get_clang_version() {
	"$1" --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//'
}

# Get the version of GCC in an user-friendly form
function get_gcc_version() {
	"$1" --version|head -n1|cut -d'(' -f2|tr -d ')'|sed -e 's/[[:space:]]*$//'
}


#### VERSIONING ####

# Get the current build number
function buildnum() {
	cat "$kroot/out/.version"
}

# Reset the kernel version number
function zerover() {
	rm "$kroot/out/.version"
}

# Retrieve the kernel version from an uncompressed image
function zver() {
	strings "$1" | grep "Linux version [[:digit:]]"
}


#### COMPILATION ####

# Make wrapper for kernel compilation
function kmake() {
	make "${kmake_flags[@]}" "$@"
}


#### IMAGE COPIES ####

# Copy the current kernel image to the specified path
function cpimg() {
	local fn="${1:-kernel.bin}"
	mkdir -p "$(dirname "$fn")"

	echo "  CP      $fn"
	cp -f "$kroot/out/arch/x86/boot/compressed/vmlinux.bin" "$fn"
}

# Create a test copy of the current kernel image
function dimg() {
	cpimg "builds/ProtonKernel-wsl2-test$(buildnum).bin"
}

# Create a test copy of the current kernel image and upload it to transfer.sh
function timg() {
	dimg && transfer "builds/ProtonKernel-wsl2-test$(buildnum).bin"
}

# Build an incremental release copy of the kernel
function rel() {
	# Swap versions
	[ ! -f "$kroot/out/.relversion" ] && touch "$kroot/out/.relversion"
	mv "$kroot/out/.version" "$kroot/out/.devversion" && \
	mv "$kroot/out/.relversion" "$kroot/out/.version"

	# Compile kernel
	kmake "$@"

	# Create release copy
	cpimg "builds/ProtonKernel-wsl2-v$(buildnum).bin"

	# Revert versions
	mv "$kroot/out/.version" "$kroot/out/.relversion" && \
	mv "$kroot/out/.devversion" "$kroot/out/.version"
}

# Build a clean release copy of the kernel
function crel() {
	kmake clean && rel "$@"
}


#### BUILD & COPY HELPERS ####

# Build a clean working copy of the kernel
function cleanbuild() {
	kmake clean && kmake "$@" && cpimg
}

# Build an incremental working copy of the kernel
function incbuild() {
	kmake "$@" && cpimg
}

# Build an incremental test copy of the kernel
function dbuild() {
	kmake "$@" && dimg
}

# Build an incremental test copy of the kernel and upload it to transfer.sh
function tbuild() {
	kmake "$@" && timg
}


#### INSTALLATION ####

# Install the given kernel image with environment-based method selection
function ktest() {
	if [[ -d /mnt/c/Windows/System32/lxss ]]; then
		# WSL (both 1 and 2)
		wktest "$@"
	else
		# Native Linux or other unsupported environment
		vktest "$@"
	fi
}

# Install the given kernel image locally from WSL
function wktest() {
	local fn="${1:-kernel.bin}"

	msg "Creating temporary file in Windows..."
	local tmp_path="$(cd /mnt/c && powershell.exe '(New-TemporaryFile).Fullname' | tr -d '\r')"
	if [[ -z "$tmp_path" ]]; then
		err "Unable to create temporary file in Windows"
		return
	fi

	msg "Pushing new kernel..."
	cp -f "$fn" "$(wslpath "$tmp_path")"

	msg "Finishing installation in Windows..."
	pushd /mnt/c > /dev/null

	cat <<-END | sed 's/$/\r/' | powershell.exe -noprofile -noninteractive -command 'iex $input'
	Unregister-ScheduledJob -Name WslKernelInstall > \$null 2>&1;
	Register-ScheduledJob -Name WslKernelInstall -RunNow -ScriptBlock {
		wsl --shutdown;
		Copy-Item '$tmp_path' 'C:/Windows/System32/lxss/tools/kernel';
		Remove-Item '$tmp_path';
	} > \$null;
	END

	popd > /dev/null
}

# Install the given kernel image from native Linux (Windows VM host)
function vktest() {
	[[ -z "$1" ]] && fn="kernel.bin" || fn="$1"

	msg "Stopping WSL utility VM..."
	ssh winvm wsl --shutdown

	msg "Pushing new kernel..."
	scp "$fn" winvm:C:/Windows/System32/lxss/tools/kernel
}


#### BUILD & INSTALL HELPERS ####

# Build & install an incremental test kernel with environment-based method selection
function inc() {
	incbuild "$@" && ktest
}

# Build & install an incremental test kernel locally from WSL
function winc() {
	incbuild "$@" && wktest
}

# Build & install an incremental test kernel from native Linux (Windows VM host)
function vinc() {
	incbuild "$@" && vktest
}


#### KERNEL CONFIGURATION ####

# Show differences between the committed defconfig and current config
function dc() {
	diff "arch/x86/configs/$defconfig" "$kroot/out/.config"
}

# Update the defconfig with the current config
function cpc() {
	cp -f "$kroot/out/.config" "arch/x86/configs/$defconfig"
}

# Reset the current config to the committed defconfig
function mc() {
	kmake "$defconfig"
}

# Open an interactive config editor
function cf() {
	kmake nconfig
}

# Edit the raw text config
function ec() {
	${EDITOR:-vim} "$kroot/out/.config"
}


#### MISCELLANEOUS ####

# Get a sorted list of the side of various objects in the kernel
function osize() {
	find "$kroot/out" -type f -name '*.o' ! -name 'built-in.o' ! -name 'vmlinux.o' \
	-exec du -h --apparent-size {} + | sort -r -h | head -n "${1:-75}" | \
	perl -pe 's/([\d.]+[A-Z]?).+\/out\/(.+)\.o/$1\t$2.c/g'
}

# Create a link to a commit on GitHub
function glink() {
	echo "https://github.com/kdrag0n/proton_wsl2/commit/$1"
}
