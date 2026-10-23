#!/bin/bash
set -euo pipefail

REPOSITORY="testdogbot/ssh-toolbox"
BRANCH="main"

if [ -n "${SUDO_USER:-}" ] && [ "$EUID" -eq 0 ]; then
    INSTALL_DIR="/opt/ssh-toolbox"
else
    INSTALL_DIR="${HOME}/.local/share/ssh-toolbox"
fi

for dependency in curl tar; do
    if ! command -v "$dependency" >/dev/null 2>&1; then
        printf 'Missing required command: %s\n' "$dependency" >&2
        exit 1
    fi
done

install_parent=$(dirname "$INSTALL_DIR")
mkdir -p "$install_parent"
work_dir=$(mktemp -d "${install_parent}/.ssh-toolbox-install.XXXXXX")
backup_dir=""

cleanup() {
    rm -rf -- "$work_dir"
}
trap cleanup EXIT

archive="${work_dir}/source.tar.gz"
source_dir="${work_dir}/source"
archive_url="https://codeload.github.com/${REPOSITORY}/tar.gz/refs/heads/${BRANCH}"

printf 'Downloading SSH Toolbox from %s...\n' "$REPOSITORY"
curl --fail --location --silent --show-error "$archive_url" -o "$archive"
mkdir -p "$source_dir"
tar -xzf "$archive" --strip-components=1 -C "$source_dir"

if [ ! -f "${source_dir}/toolbox.sh" ] || [ ! -d "${source_dir}/modules" ]; then
    echo "Downloaded archive does not contain a valid SSH Toolbox." >&2
    exit 1
fi

touch "${source_dir}/.ssh-toolbox-managed"

if [ -e "$INSTALL_DIR" ]; then
    if [ ! -f "${INSTALL_DIR}/.ssh-toolbox-managed" ]; then
        printf 'Refusing to replace unmanaged directory: %s\n' "$INSTALL_DIR" >&2
        exit 1
    fi
    backup_dir="${INSTALL_DIR}.backup.$(date +%Y%m%d%H%M%S).$$"
    if [ -e "$backup_dir" ]; then
        printf 'Backup path already exists: %s\n' "$backup_dir" >&2
        exit 1
    fi
    mv -- "$INSTALL_DIR" "$backup_dir"
fi

if ! mv -- "$source_dir" "$INSTALL_DIR"; then
    if [ -n "$backup_dir" ] && [ -e "$backup_dir" ]; then
        mv -- "$backup_dir" "$INSTALL_DIR"
    fi
    echo "Could not install SSH Toolbox." >&2
    exit 1
fi

printf 'Installed SSH Toolbox at %s\n' "$INSTALL_DIR"
if [ -n "$backup_dir" ]; then
    printf 'Previous installation preserved at %s\n' "$backup_dir"
fi

trap - EXIT
cleanup
exec bash "${INSTALL_DIR}/toolbox.sh" "$@"
