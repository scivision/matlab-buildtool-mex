#!/usr/bin/env bash

# this wrapper is needed to workaround the censoring of DYLD_LIBRARY_PATH in SIP on macOS

if [[ -z "$dummy_LIBRARY_PATH" ]]; then
  echo "Error: dummy_LIBRARY_PATH is not set. This wrapper should only be used on macOS." >&2
  exit 1
fi

set -x

DYLD_LIBRARY_PATH="$dummy_LIBRARY_PATH:$DYLD_LIBRARY_PATH" exec "$@"
