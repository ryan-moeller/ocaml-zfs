type property_source =
  | None
  | Default
  | Temporary
  | Local
  | Inherited
  | Received

module Libzfs = struct
  type handle
  type zpool_handle
  type zfs_handle

  external open_handle : unit -> handle = "caml_libzfs_init"
end

module Zpool = struct
  type handle = Libzfs.zpool_handle

  type property =
    | Name
    | Size
    | Capacity
    | Altroot
    | Health
    | Guid
    | Version
    | Bootfs
    | Delegation
    | Autoreplace
    | Cachefile
    | Failuremode
    | Listsnaps
    | Autoexpand
    | Dedupditto
    | Dedupratio
    | Free
    | Allocated
    | Readonly
    | Ashift
    | Comment
    | Expandsz
    | Freeing
    | Fragmentation
    | Leaked
    | Maxblocksize
    | Tname
    | Maxdnodesize
    | Multihost
    | Checkpoint
    | Load_guid
    | Autotrim
    | Compatibility
    | Bcloneused
    | Bclonesaved
    | Bcloneratio

  external open_handle : Libzfs.handle -> string -> handle option
    = "caml_zpool_open"

  external name : handle -> string = "caml_zpool_get_name"

  external get_property :
    handle -> property -> (string * property_source array) option
    = "caml_zpool_get_prop"

  external get_user_property :
    handle -> string -> (string * property_source array) option
    = "caml_zpool_get_userprop"
end

module Zfs = struct
  type handle = Libzfs.zfs_handle

  type zfs_type =
    | Invalid
    | Filesystem
    | Snapshot
    | Volume
    | Pool
    | Bookmark
    | Vdev

  type property =
    | Type
    | Creation
    | Used
    | Available
    | Referenced
    | Compressratio
    | Mounted
    | Origin
    | Quota
    | Reservation
    | Volsize
    | Volblocksize
    | Recordsize
    | Mountpoint
    | Sharenfs
    | Checksum
    | Compression
    | Atime
    | Devices
    | Exec
    | Setuid
    | Readonly
    | Zoned
    | Snapdir
    | Aclmode
    | Aclinherit
    | Createtxg
    | Name
    | Canmount
    | Iscsioptions
    | Xattr
    | Numclones
    | Copies
    | Version
    | Utf8only
    | Normalize
    | Case
    | Vscan
    | Nbmand
    | Sharesmb
    | Refquota
    | Refreservation
    | Guid
    | Primarycache
    | Secondarycache
    | Usedsnap
    | Usedds
    | Usedchild
    | Usedrefreserv
    | Useraccounting
    | Stmf_shareinfo
    | Defer_destroy
    | Userrefs
    | Logbias
    | Unique
    | Objsetid
    | Dedup
    | Mlslabel
    | Sync
    | Dnodesize
    | Refratio
    | Written
    | Clones
    | Logicalused
    | Logicalreferenced
    | Inconsistent
    | Volmode
    | Filesystem_limit
    | Snapshot_limit
    | Filesystem_count
    | Snapshot_count
    | Snapdev
    | Acltype
    | Selinux_context
    | Selinux_fscontext
    | Selinux_defcontext
    | Selinux_rootcontext
    | Relatime
    | Redundant_metadata
    | Overlay
    | Prev_snap
    | Receive_resume_token
    | Encryption
    | Keylocation
    | Keyformat
    | Pkdf2_salt
    | Pkdf2_iters
    | Encryption_root
    | Key_guid
    | Keystatus
    | Remaptxg
    | Special_small_blocks
    | Ivset_guid
    | Redacted
    | Redact_snaps
    | Snapshots_changed
    | Prefetch
    | Volthreading

  external open_handle :
    Libzfs.handle -> string -> zfs_type array -> handle option = "caml_zfs_open"

  external name : handle -> string = "caml_zfs_get_name"
  external pool_name : handle -> string = "caml_zfs_get_pool_name"
  external zfs_type : handle -> zfs_type = "caml_zfs_get_type"

  external underlying_zfs_type : handle -> zfs_type
    = "caml_zfs_get_underlying_type"

  external bookmark_exists : string -> bool = "caml_zfs_bookmark_exists"

  external get_property :
    handle ->
    property ->
    (string * string option * property_source array) option
    = "caml_zfs_get_prop"
end
