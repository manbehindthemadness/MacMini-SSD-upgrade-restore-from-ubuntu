#!/bin/bash
# Source this file from the kit's scripts; do not add these paths globally.
KIT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
export LD_LIBRARY_PATH="$KIT_ROOT/tools/lib:$KIT_ROOT/build-deps/usr/lib/x86_64-linux-gnu"
export PATH="$KIT_ROOT/tools/bin:$KIT_ROOT/tools/sbin:$PATH"
