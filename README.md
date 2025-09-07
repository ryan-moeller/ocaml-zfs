OCaml OpenZFS Library
=====================

[![15.0-PRERELEASE Build Status](https://api.cirrus-ci.com/github/ryan-moeller/ocaml-zfs.svg?branch=main&task=releases/amd64/15.0-PRERELEASE)](https://cirrus-ci.com/github/ryan-moeller/ocaml-zfs)

This OCaml library exposes low-level OpenZFS ioctls as well as higher level
abstractions for ease of use.  Neither libzfs nor libzfs_core C libraries are
used, only libnvpair.  The goal is to explore alternative implementations of
zfs userland functionality.

This project is a work in progress.  Not all functionality is complete.  Only
FreeBSD 15.0-PRERELEASE (roughly tracking OpenZFS master) is tested.
