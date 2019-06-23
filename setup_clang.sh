#
# Clang-specific environment setup script for WSL2 kernel compilation
# Copyright (C) 2019 Danny Lin <danny@kdrag0n.dev>
#
# This script must be *sourced* from zsh (bash is NOT supported) in order to
# function. Nothing will happen if you execute it.
#

# Clang executable name
clang_name="clang"

# Number of parallel jobs to run
# Do not remove; set to 1 for no parallelism.
jobs=$(nproc)

# Do not edit below this point
# ----------------------------

# Load the shared helpers
source helpers.sh

MAKEFLAGS+=(
	CC="$clang_name"
	KBUILD_COMPILER_STRING="$(get_clang_version "$clang_name")"
)
