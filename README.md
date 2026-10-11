OCaml OpenZFS Library
=====================

[![FreeBSD 15.1](https://github.com/ryan-moeller/ocaml-zfs/workflows/FreeBSD%2015.1/badge.svg)](https://github.com/ryan-moeller/ocaml-zfs/actions/workflows/test.yml)

This OCaml library exposes low-level OpenZFS ioctls as well as higher level
abstractions for ease of use.  Neither libzfs nor libzfs_core C libraries are
used, only libnvpair.  The goal is to explore alternative implementations of
zfs userland functionality.

This project is a work in progress.  Not all functionality is complete.  Only
FreeBSD 15.1 and newer is tested for the time being.
