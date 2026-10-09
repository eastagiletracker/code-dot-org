#!/bin/bash

# This script runs a turbo task (`build` by default) over the dependencies of the `apps` (CodeAI Studio)
# directory which reside in the `frontend` directory, plus their own dependencies. Run it from `apps`.

set -x

# The dependencies are the `portal:` entries in `apps/package.json`.
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
