#!/bin/bash

# Runs a turbo verb (build by default) over the frontend packages that apps/
# consumes, plus their dependencies. Run from apps/.

set -x

# Every frontend package apps/ links through a portal: entry.
APPS_DEPENDENCIES=($(node --print '
  Object.entries(require("./package.json").dependencies)
    .filter(([, version]) => version.startsWith("portal:../frontend"))
    .map(([name]) => `--filter=${name}`)
    .join(" ")
'))

cd ../frontend || exit 1

case "$1" in
  --watch)
    # watch mode skips `yarn` install: the plain invocation below always runs
    # first, as part of grunt's prebuild task.
    exec yarn turbo watch build "${APPS_DEPENDENCIES[@]}" --output-logs errors-only
    ;;
  "" | build)
    # Empty dist once here, before webpack starts watching it. Package builds no
    # longer empty it themselves (emptyOutDir: false) because webpack never
    # recovers on macOS when watched files vanish mid-build (INF-2257). This
    # clean is what keeps removed or renamed outputs from piling up over time.
    yarn && \
    yarn run clean "${APPS_DEPENDENCIES[@]}" --output-logs errors-only && \
    yarn run build "${APPS_DEPENDENCIES[@]}" --output-logs errors-only
    ;;
  *)
    yarn run "$1" "${APPS_DEPENDENCIES[@]}" --output-logs errors-only
    ;;
esac
