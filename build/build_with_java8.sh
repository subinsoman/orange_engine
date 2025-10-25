#!/usr/bin/env bash
# Helper to build Seahorse images using Java 8 for sbt-based modules.
# Usage:
#   - Build all images:      ./build/build_with_java8.sh --all
#   - Build selected images: ./build/build_with_java8.sh seahorse-spark seahorse-sessionmanager
# Notes:
#   - Defaults JAVA_HOME to /home/subinsoman/binaries/jdk1.8.0_202
#   - For selected images, arguments are passed to manage-docker.py -i ...

set -euo pipefail

cd "$(dirname "$0")/.."

export JAVA_HOME="/home/subinsoman/binaries/jdk1.8.0_202"
export PATH="$JAVA_HOME/bin:$PATH"

echo "Using JAVA_HOME=$JAVA_HOME"

if [[ ${1:-} == "--all" ]]; then
  ./build/build_docker_compose_internal.sh "$(git rev-parse HEAD)"
  ./build/manage-docker.py -b --all
  exit $?
fi

if [[ $# -gt 0 ]]; then
  echo "Building selected images: $*"
  ./build/manage-docker.py -b -i "$@"
  exit $?
fi

echo "Usage:"
echo "  $0 --all"
echo "  $0 <image1> [image2 ...]"
echo "Example:"
echo "  $0 seahorse-spark seahorse-sessionmanager"
exit 2
