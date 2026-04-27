# PowerPC (Linux)

Julia supports 64-bit little-endian PowerPC (ppc64le) processors running Linux.
This file provides general guidelines for compilation, in addition to instructions
for specific devices.

A list of [known issues](https://github.com/JuliaLang/julia/labels/system:powerpc)
for PowerPC is available. If you encounter difficulties, please create an issue
including the output from `cat /proc/cpuinfo`.

Big-endian PowerPC (`ppc64`/`powerpc64`) is **not** supported.

## Compiling Julia

The build system normalizes `ARCH=ppc64le` to `ARCH=powerpc64le` automatically
(see `Make.inc`). On ppc64le, GCC does not accept `-march=`, so the `MARCH`
variable should be left unset. `OPENBLAS_TARGET_ARCH` defaults to `POWER8`, which
is forward-compatible with POWER9 and POWER10.

A typical `Make.user` for a native build is empty; the defaults in `Make.inc`
are correct for POWER8/9/10. Avoid setting `JULIA_CPU_TARGET` unless you have
verified the target name is recognised by Julia's processor parser — invalid
names cause `target_parsing: unknown CPU` failures during the system-image
step.

Page size on ppc64le is assumed to be 64KiB (matching AArch64 conventions in
`Make.inc`). If your kernel uses a different page size you may need to adjust
linker flags; see the `aarch64`/`powerpc64le` block in `Make.inc`.

## Container build

A reference Podman/Docker build environment is provided under
`contrib/ppc64le/`. From a Power9 host with Podman installed:

```sh
cd contrib/ppc64le
podman build -t julia-ppc64le-build .
podman run --rm -v $PWD/../..:/src:Z -w /src julia-ppc64le-build make -j$(nproc)
```

This image mirrors the toolchain expected by the upstream build instructions.

## Continuous integration

The `.github/workflows/ppc64le.yml` workflow runs against an `IBM/actionspz`
hosted runner with the `ubuntu-24.04-ppc64le` label (POWER9). It builds Julia
and runs a sanity test on every push and pull request. This produces public
green-build evidence for use in tier-promotion discussions.

## Known issues

* SuiteSparse has historically been unstable on ppc64le; see
  [#20123](https://github.com/JuliaLang/julia/issues/20123). If you encounter
  segfaults in `LinearAlgebra` tests under `SuiteSparse`, attach the backtrace
  and any reproducer to a new issue with the `system:powerpc` label.
* The LLVM PowerPC backend has occasionally diverged between Julia's bundled
  LLVM version and upstream. Required workarounds are carried as patches in
  `deps/patches/llvm-*-ppc-*.patch`.
