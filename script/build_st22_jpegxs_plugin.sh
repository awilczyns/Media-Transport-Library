#!/usr/bin/env bash
# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2026 Intel Corporation

set -euo pipefail

script_name=$(basename "${BASH_SOURCE[0]}")
script_path=$(readlink -qe "${BASH_SOURCE[0]}")
script_folder=${script_path/%$script_name/}
root_folder=$(readlink -qe "${script_folder}/..")

# SvtJpegXS repo path or download location
JPEGXS_REPO="/tmp/SVT-JPEG-XS"

lib_so="libst_plugin_st22_svt_jpeg_xs.so"
need_build=0

# Check plugin .so
if ! ldconfig -p 2>/dev/null | grep -q "${lib_so}" &&
	! test -f /usr/local/lib/x86_64-linux-gnu/${lib_so} &&
	! test -f /usr/local/lib64/${lib_so}; then
	echo "MTL JPEG-XS plugin not found."
	need_build=1
fi

# Check core SvtJpegxs version
lib_path=$(ldconfig -p 2>/dev/null | grep -oE '/[^[:space:]]*libSvtJpegxs\.so\.0' | head -n1)
if [ -n "${lib_path}" ]; then
	real_lib=$(readlink -f "${lib_path}")
	if echo "${real_lib}" | grep -q '0.9.0'; then
		echo "Outdated core SvtJpegxs (${real_lib}) detected on host."
		need_build=1
	fi
else
	echo "Core SvtJpegxs library not found."
	need_build=1
fi

if [ "${need_build}" -eq 0 ]; then
	echo "=== SVT-JPEG-XS and MTL bridge plugin are already up-to-date. Alignment skipped ==="
	exit 0
fi

# Determine build destination prefix (system default vs Custom local_install)
meson_prefix_args=()
if [ -n "${MTL_PLUGIN_PREFIX:-}" ] && [ -d "${MTL_PLUGIN_PREFIX}" ]; then
	meson_prefix_args+=(--prefix "${MTL_PLUGIN_PREFIX}")
fi

echo "=== Processing SVT-JPEG-XS Installation / Upgrade ==="
sudo rm -rf "${JPEGXS_REPO}"
git clone --depth 1 https://github.com/OpenVisualCloud/SVT-JPEG-XS.git "${JPEGXS_REPO}"

echo "=== Building SvtJpegXS Core Library ==="
pushd "${JPEGXS_REPO}/Build/linux" >/dev/null || exit 1
./build.sh release
sudo ./build.sh install
popd >/dev/null

echo "=== Deploying SvtJpegXS headers ==="
sudo mkdir -p /usr/local/include/svt-jpegxs
sudo cp -f "${JPEGXS_REPO}/Source/API/"*.h /usr/local/include/svt-jpegxs/

echo "=== Rebuilding and Installing imtl-plugin bridge ==="
pushd "${JPEGXS_REPO}/imtl-plugin" >/dev/null || exit 1
rm -rf build

# Support custom pkgconfig lookup from the .local_install tree
if [ -n "${GITHUB_WORKSPACE:-}" ] && [ -d "${GITHUB_WORKSPACE}/.local_install/mtl" ]; then
	export PKG_CONFIG_PATH="${GITHUB_WORKSPACE}/.local_install/mtl/lib/x86_64-linux-gnu/pkgconfig:${PKG_CONFIG_PATH:-}"
fi

meson setup build "${meson_prefix_args[@]}"
meson compile -C build

if [ -n "${MTL_PLUGIN_PREFIX:-}" ]; then
	meson install -C build
else
	sudo meson install -C build
fi
popd >/dev/null

sudo ldconfig
echo "=== SVT-JPEG-XS and MTL bridge plugin successfully installed/aligned ==="
