#!/usr/bin/env bash
# Builds one Turnip driver (Mesa's Vulkan driver for Adreno) for arm64 Android and packages it for adrenotools.
# Usage: scripts/build.sh <id> <name> <mesa ref (tag or commit)> <out dir>. Needs ANDROID_NDK_HOME, meson, ninja, mako.
set -euo pipefail
id=$1 name=$2 ref=$3 out=$(realpath -m "$4")
api=29   # the oldest Android the drivers support (Android 10)
work=$(mktemp -d)
mkdir -p "$out"

curl -sfL "https://gitlab.freedesktop.org/mesa/mesa/-/archive/$ref/mesa-$ref.tar.gz" | tar -xz -C "$work"
src=$(echo "$work"/mesa-*)
version=$(cat "$src/VERSION")

bin="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin"
cat > "$work/android-aarch64.ini" <<INI
[binaries]
ar = '$bin/llvm-ar'
c = ['$bin/aarch64-linux-android$api-clang']
cpp = ['$bin/aarch64-linux-android$api-clang++']
c_ld = 'lld'
cpp_ld = 'lld'
strip = '$bin/llvm-strip'
# no host libraries: everything comes from the NDK or Mesa's Android stubs
pkg-config = ['env', 'PKG_CONFIG_LIBDIR=/nonexistent', '/usr/bin/pkg-config']

[built-in options]
# libc++ linked in: apps that load the driver needn't carry libc++_shared.so
c_link_args = ['-static-libstdc++']
cpp_link_args = ['-static-libstdc++']

[host_machine]
system = 'android'
cpu_family = 'aarch64'
cpu = 'armv8'
endian = 'little'
INI

meson setup "$work/build" "$src" --cross-file "$work/android-aarch64.ini" \
  -Dbuildtype=release -Dstrip=true \
  -Dplatforms=android -Dplatform-sdk-version=$api -Dandroid-stub=true -Dandroid-libbacktrace=disabled \
  -Dgallium-drivers= -Dvulkan-drivers=freedreno -Dfreedreno-kmds=kgsl -Dvulkan-beta=true \
  -Dllvm=disabled -Dzstd=disabled -Dgles1=disabled -Dgles2=disabled -Dopengl=false -Degl=disabled -Dglx=disabled -Dgbm=disabled
ninja -C "$work/build" src/freedreno/vulkan/libvulkan_freedreno.so

pkg="$work/pkg"
mkdir -p "$pkg"
lib=vulkan.turnip.so
cp "$work/build/src/freedreno/vulkan/libvulkan_freedreno.so" "$pkg/$lib"
patchelf --set-soname "$lib" "$pkg/$lib"
echo "Needs:"; readelf -d "$pkg/$lib" | grep NEEDED
commit=$ref
[[ $ref =~ ^[0-9a-f]{40}$ ]] || commit=$(git ls-remote https://gitlab.freedesktop.org/mesa/mesa.git "refs/tags/$ref^{}" | cut -f1)
cp "$src/docs/license.rst" "$pkg/LICENSE-mesa.rst"
python3 - "$pkg/meta.json" "$name" "$version" "$ref" "$commit" "$lib" "$api" <<'PY'
import json, sys
path, name, version, ref, commit, lib, api = sys.argv[1:]
json.dump({"schemaVersion": 1, "name": name,
           "description": f"Mesa's open-source Vulkan driver for Adreno GPUs, unmodified, built from {ref} ({commit[:12]})",
           "author": "Mesa", "packageVersion": "1", "vendor": "Mesa", "driverVersion": f"Mesa {version}",
           "minApi": int(api), "libraryName": lib}, open(path, "w"), indent=2)
PY
(cd "$pkg" && zip -q -X "$out/$id.zip" meta.json "$lib" LICENSE-mesa.rst)
python3 - "$out/$id.json" "$id" "$name" "$version" "$ref" "$commit" <<'PY'
import json, sys
path, id, name, version, ref, commit = sys.argv[1:]
json.dump({"id": id, "name": name, "mesaVersion": version, "ref": ref, "commit": commit}, open(path, "w"))
PY
echo "Built $out/$id.zip (Mesa $version, $commit)"
