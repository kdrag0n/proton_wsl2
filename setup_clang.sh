#
# Clang-specific environment setup script for WSL2 kernel compilation
# Copyright (C) 2019 Danny Lin <danny@kdrag0n.dev>
#
# This script must be *sourced* from zsh (bash is NOT supported) in order to
# function. Nothing will happen if you execute it.
#

# Path to executables in Clang toolchain
clang_bin="$HOME/toolchains/proton-clang-10.0.0-20190723/bin"

# Number of parallel jobs to run
# Do not remove; set to 1 for no parallelism.
jobs=$(nproc)

# Do not edit below this point
# ----------------------------

# Load the shared helpers
source helpers.sh

export LD_LIBRARY_PATH="$clang_bin/../lib:$PATH"
export PATH="$clang_bin:$PATH"

kmake_flags+=(
	CC="clang"
	KBUILD_COMPILER_STRING="$(get_clang_version clang)"
)
