(lang dune 3.14)

(name zfs)

(generate_opam_files true)

(source
 (github ryan-moeller/ocaml-zfs))

(authors "Ryan Moeller")

(maintainers "Ryan Moeller")

(license LICENSE)

(documentation https://url/to/documentation)

(package
 (name zfs)
 (synopsis "Bindings for OpenZFS libzfs(3) ZFS library")
 (description "Functions for managing ZFS")
 (depends ocaml dune str nvpair unix)
 (tags
  (topics OpenZFS ZFS libzfs)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
