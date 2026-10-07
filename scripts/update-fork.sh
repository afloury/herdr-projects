#!/bin/sh
# Updates an install of this fork in place of `herdr-projects update`, which
# follows the upstream releases: fetch the fork's main, build it, swap the
# binary, then restart the ticker the way `update` does.
#
#   sh scripts/update-fork.sh [plugin-dir]
#
# plugin-dir defaults to the checkout this script lives in. Environment:
#   FORK_REMOTE  remote of the fork (default: fork, else origin)
#   FORK_BRANCH  branch to install (default: main)
#   BUILD        cargo | docker (default: cargo when it is on PATH, else docker)
#   LOCK         a flock(1) lock file to take for the build (optional)
set -eu

dir=$(cd "${1:-$(dirname "$0")/..}" && pwd)
cd "$dir"
remote=${FORK_REMOTE:-}
if [ -z "$remote" ]; then
  if git remote get-url fork >/dev/null 2>&1; then remote=fork; else remote=origin; fi
fi
branch=${FORK_BRANCH:-main}
bin=target/release/herdr-projects
build_dir=target/fork-update

if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
  echo "update-fork: $dir has uncommitted changes; commit or stash them first" >&2
  exit 1
fi

echo "fetching $remote/$branch…"
git fetch --quiet "$remote" "$branch"
new=$(git rev-parse --short FETCH_HEAD)
# Detached, so a branch checked out in a worktree never blocks the update.
git checkout --quiet --detach FETCH_HEAD

lock() { if [ -n "${LOCK:-}" ]; then flock "$LOCK" "$@"; else "$@"; fi; }
build=${BUILD:-}
[ -n "$build" ] || { command -v cargo >/dev/null 2>&1 && build=cargo || build=docker; }
echo "building $new with $build…"
# Created here so the docker build (as root) leaves `target/` owned by the user.
mkdir -p "$build_dir" "$(dirname "$bin")"
case $build in
  cargo)
    CARGO_TARGET_DIR="$build_dir" lock nice -n 10 cargo build --release --locked
    ;;
  docker)
    # The git directory is mounted too: a worktree's .git file points into it.
    common=$(cd "$(git rev-parse --git-common-dir)" && pwd)
    lock nice -n 10 docker run --rm --cpus=2 --memory=1500m \
      -v "$dir:$dir" -v "$common:$common:ro" -w "$dir" \
      -e CARGO_TARGET_DIR="$build_dir" rust:1-alpine \
      sh -c "apk add -q git >/dev/null && git config --global --add safe.directory '*' && cargo build --release --locked && chown -R $(id -u):$(id -g) $build_dir"
    ;;
  *) echo "update-fork: BUILD must be cargo or docker" >&2; exit 1 ;;
esac

built="$build_dir/release/herdr-projects"
"$built" --version >/dev/null
# An old ticker misreads files a newer `doctor --fix` writes: stop it with the
# old binary first, as `herdr-projects update` does.
if [ -x "$bin" ]; then "$bin" ticker stop || true; fi
install -m 755 "$built" "$bin.new"
mv -f "$bin.new" "$bin"
"$bin" doctor --fix || echo "update-fork: doctor --fix reported problems (above)" >&2
"$bin" ticker start
echo "installed $("$bin" --version) ($new)"
