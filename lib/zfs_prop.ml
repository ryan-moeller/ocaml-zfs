type t =
  | Aclinherit
  | Aclmode
  | Acltype
  | Atime
  | Available
  | Canmount
  | Case
  | Checksum
  | Clones
  | Compression
  | Compressratio
  | Copies
  | Createtxg
  | Creation
  | Dedup
  | Defer_destroy
  | Devices
  | Dnodesize
  | Encryption
  | Encryption_root
  | Exec
  | Filesystem_count
  | Filesystem_limit
  | Guid
  | Inconsistent
  | Inval
  | Iscsioptions
  | Ivset_guid
  | Key_guid
  | Keyformat
  | Keylocation
  | Keystatus
  | Logbias
  | Logicalreferenced
  | Logicalused
  | Mlslabel
  | Mounted
  | Mountpoint
  | Name
  | Nbmand
  | Normalize
  | Numclones
  | Objsetid
  | Origin
  | Overlay
  | Pbkdf2_iters
  | Pbkdf2_salt
  | Prefetch
  | Prev_snap
  | Primarycache
  | Quota
  | Readonly
  | Receive_resume_token
  | Recordsize
  | Redact_snaps
  | Redacted
  | Redundant_metadata
  | Referenced
  | Refquota
  | Refratio
  | Refreservation
  | Relatime
  | Remaptxg
  | Reservation
  | Secondarycache
  | Selinux_context
  | Selinux_defcontext
  | Selinux_fscontext
  | Selinux_rootcontext
  | Setuid
  | Sharenfs
  | Sharesmb
  | Snapdev
  | Snapdir
  | Snapshot_count
  | Snapshot_limit
  | Snapshots_changed
  | Special_small_blocks
  | Stmf_shareinfo
  | Sync
  | Type
  | Unique
  | Used
  | Usedchild
  | Usedds
  | Usedrefreserv
  | Usedsnap
  | Useraccounting
  | Userprop
  | Userrefs
  | Utf8only
  | Version
  | Volblocksize
  | Volmode
  | Volsize
  | Volthreading
  | Vscan
  | Written
  | Xattr
  | Zoned

let of_string = function
  | "aclinherit" -> Aclinherit
  | "aclmode" -> Aclmode
  | "acltype" -> Acltype
  | "atime" -> Atime
  | "available" -> Available
  | "canmount" -> Canmount
  | "casesensitivity" -> Case
  | "checksum" -> Checksum
  | "clones" -> Clones
  | "compression" -> Compression
  | "compressratio" -> Compressratio
  | "context" -> Selinux_context
  | "copies" -> Copies
  | "createtxg" -> Createtxg
  | "creation" -> Creation
  | "dedup" -> Dedup
  | "defcontext" -> Selinux_defcontext
  | "defer_destroy" -> Defer_destroy
  | "devices" -> Devices
  | "dnodesize" -> Dnodesize
  | "encryption" -> Encryption
  | "encryptionroot" -> Encryption_root
  | "exec" -> Exec
  | "filesystem_count" -> Filesystem_count
  | "filesystem_limit" -> Filesystem_limit
  | "fscontext" -> Selinux_fscontext
  | "guid" -> Guid
  | "inconsistent" -> Inconsistent
  | "iscsioptions" -> Iscsioptions
  | "ivsetguid" -> Ivset_guid
  | "jailed" -> Zoned
  | "keyformat" -> Keyformat
  | "keyguid" -> Key_guid
  | "keylocation" -> Keylocation
  | "keystatus" -> Keystatus
  | "logbias" -> Logbias
  | "logicalreferenced" -> Logicalreferenced
  | "logicalused" -> Logicalused
  | "mlslabel" -> Mlslabel
  | "mounted" -> Mounted
  | "mountpoint" -> Mountpoint
  | "name" -> Name
  | "nbmand" -> Nbmand
  | "normalization" -> Normalize
  | "numclones" -> Numclones
  | "objsetid" -> Objsetid
  | "origin" -> Origin
  | "overlay" -> Overlay
  | "pbkdf2iters" -> Pbkdf2_iters
  | "pbkdf2salt" -> Pbkdf2_salt
  | "prefetch" -> Prefetch
  | "prevsnap" -> Prev_snap
  | "primarycache" -> Primarycache
  | "quota" -> Quota
  | "readonly" -> Readonly
  | "receive_resume_token" -> Receive_resume_token
  | "recordsize" -> Recordsize
  | "redact_snaps" -> Redact_snaps
  | "redacted" -> Redacted
  | "redundant_metadata" -> Redundant_metadata
  | "refcompressratio" -> Refratio
  | "referenced" -> Referenced
  | "refquota" -> Refquota
  | "refreservation" -> Refreservation
  | "relatime" -> Relatime
  | "remaptxg" -> Remaptxg
  | "reservation" -> Reservation
  | "rootcontext" -> Selinux_rootcontext
  | "secondarycache" -> Secondarycache
  | "setuid" -> Setuid
  | "sharenfs" -> Sharenfs
  | "sharesmb" -> Sharesmb
  | "snapdev" -> Snapdev
  | "snapdir" -> Snapdir
  | "snapshot_count" -> Snapshot_count
  | "snapshot_limit" -> Snapshot_limit
  | "snapshots_changed" -> Snapshots_changed
  | "special_small_blocks" -> Special_small_blocks
  | "stmf_sbd_lu" -> Stmf_shareinfo
  | "sync" -> Sync
  | "type" -> Type
  | "unique" -> Unique
  | "used" -> Used
  | "usedbychildren" -> Usedchild
  | "usedbydataset" -> Usedds
  | "usedbyrefreservation" -> Usedrefreserv
  | "usedbysnapshots" -> Usedsnap
  | "useraccounting" -> Useraccounting
  | "userrefs" -> Userrefs
  | "utf8only" -> Utf8only
  | "version" -> Version
  | "volblocksize" -> Volblocksize
  | "volmode" -> Volmode
  | "volsize" -> Volsize
  | "volthreading" -> Volthreading
  | "vscan" -> Vscan
  | "written" -> Written
  | "xattr" -> Xattr
  | _ -> Inval

type prop_type = Number | String | Index
type dataset_type = Filesystem | Snapshot | Volume | Bookmark

type attributes = {
  name : string;
  prop_type : prop_type;
  numdefault : int64;
  strdefault : string option;
  readonly : bool;
  inherits : bool;
  onetime : bool;
  onetime_default : bool;
  dataset_types : dataset_type array;
  values : string option;
  colname : string;
  rightalign : bool;
  visible : bool;
  flex : bool;
  index_table : (string * int64) array;
}

let attributes = function
  | Inval -> failwith "not a valid property"
  | Aclinherit ->
      {
        name = "aclinherit";
        prop_type = Index;
        numdefault = 4L (* ZFS_ACL_RESTRICTED *);
        strdefault = None;
        readonly = false;
        inherits = true;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem |];
        values =
          Some "discard | noallow | restricted | passthrough | passthrough-x";
        colname = "ACLINHERIT";
        rightalign = false;
        visible = true;
        flex = true;
        index_table =
          [|
            ("discard", 0L);
            ("noallow", 1L);
            ("restricted", 4L);
            ("passthrough", 3L);
            ("secure", 4L);
            ("passthrough-x", 5L);
          |];
      }
  | Aclmode ->
      {
        name = "aclmode";
        prop_type = Index;
        numdefault = 0L (* ZFS_ACL_DISCARD *);
        strdefault = None;
        readonly = false;
        inherits = true;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem |];
        values = Some "discard | groupmask | passthrough | restricted";
        colname = "ACLMODE";
        rightalign = false;
        visible = true;
        flex = true;
        index_table =
          [|
            ("discard", 0L);
            ("groupmask", 2L);
            ("passthrough", 3L);
            ("restricted", 4L);
          |];
      }
  | Acltype ->
      {
        name = "acltype";
        prop_type = Index;
        numdefault = 2L (* ZFS_ACLTYPE_NFSV4 *);
        strdefault = None;
        readonly = false;
        inherits = true;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Snapshot |];
        values = Some "off | nfsv4 | posix";
        colname = "ACLTYPE";
        rightalign = false;
        visible = true;
        flex = true;
        index_table =
          [|
            ("off", 0L);
            ("posix", 1L);
            ("nfsv4", 2L);
            ("disabled", 0L);
            ("noacl", 0L);
            ("posixacl", 1L);
          |];
      }
  | Atime ->
      {
        name = "atime";
        prop_type = Index;
        numdefault = 1L;
        strdefault = None;
        readonly = false;
        inherits = true;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem |];
        values = Some "on | off";
        colname = "ATIME";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [| ("off", 0L); ("on", 1L) |];
      }
  | Available ->
      {
        name = "available";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume; Snapshot |];
        values = Some "<size>";
        colname = "AVAIL";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Canmount ->
      {
        name = "canmount";
        prop_type = Index;
        numdefault = 1L (* ZFS_CANMOUNT_ON *);
        strdefault = None;
        readonly = false;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem |];
        values = Some "on | off | noauto";
        colname = "CANMOUNT";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [| ("off", 0L); ("on", 1L); ("noauto", 2L) |];
      }
  | Case ->
      {
        name = "casesensitivity";
        prop_type = Index;
        numdefault = 0L (* ZFS_CASE_SENSITIVE *);
        strdefault = None;
        readonly = false;
        inherits = false;
        onetime = true;
        onetime_default = false;
        dataset_types = [| Filesystem; Snapshot |];
        values = Some "sensitive | insensitive | mixed";
        colname = "CASE";
        rightalign = false;
        visible = true;
        flex = true;
        index_table =
          [| ("sensitive", 0L); ("insensitive", 1L); ("mixed", 2L) |];
      }
  | Checksum ->
      {
        name = "checksum";
        prop_type = Index;
        numdefault = 1L (* ZIO_CHECKSUM_ON *);
        strdefault = None;
        readonly = false;
        inherits = true;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume |];
        values =
          Some
            "on | off | fletcher2 | fletcher4 | sha256 | sha512 | skein | \
             edonr | blake3";
        colname = "CHECKSUM";
        rightalign = false;
        visible = true;
        flex = true;
        index_table =
          [|
            ("on", 1L);
            ("off", 2L);
            ("fletcher2", 6L);
            ("fletcher4", 7L);
            ("sha256", 8L);
            ("noparity", 10L);
            ("sha512", 11L);
            ("skein", 12L);
            ("edonr", 13L);
            ("blake3", 14L);
          |];
      }
  | Clones ->
      {
        name = "clones";
        prop_type = String;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Snapshot |];
        values = Some "<dataset>[,...]";
        colname = "CLONES";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [||];
      }
  | Compression ->
      {
        name = "compression";
        prop_type = Index;
        numdefault = 1L (* ZIO_COMPRESS_ON *);
        strdefault = None;
        readonly = false;
        inherits = true;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume |];
        values =
          Some
            "on | off | lzjb | gzip | gzip-[1-9] | zle | lz4 | zstd | \
             zstd-[1-19] | zstd-fast | \
             zstd-fast-[1-10,20,30,40,50,60,70,80,90,100,500,1000]";
        colname = "COMPRESS";
        rightalign = false;
        visible = true;
        flex = true;
        index_table =
          (let zstd i = Int64.logor 16L (Int64.shift_left i 7) in
           [|
             ("on", 1L);
             ("off", 2L);
             ("lzjb", 3L);
             ("gzip", 10L);
             ("gzip-1", 5L);
             ("gzip-2", 6L);
             ("gzip-3", 7L);
             ("gzip-4", 8L);
             ("gzip-5", 9L);
             ("gzip-6", 10L);
             ("gzip-7", 11L);
             ("gzip-8", 12L);
             ("gzip-9", 13L);
             ("zle", 14L);
             ("lz4", 15L);
             ("zstd", zstd 0L);
             ("zstd-fast", zstd 103L);
             ("zstd-1", zstd 1L);
             ("zstd-2", zstd 2L);
             ("zstd-3", zstd 3L);
             ("zstd-4", zstd 4L);
             ("zstd-5", zstd 5L);
             ("zstd-6", zstd 6L);
             ("zstd-7", zstd 7L);
             ("zstd-8", zstd 8L);
             ("zstd-9", zstd 9L);
             ("zstd-10", zstd 10L);
             ("zstd-11", zstd 11L);
             ("zstd-12", zstd 12L);
             ("zstd-13", zstd 13L);
             ("zstd-14", zstd 14L);
             ("zstd-15", zstd 15L);
             ("zstd-16", zstd 16L);
             ("zstd-17", zstd 17L);
             ("zstd-18", zstd 18L);
             ("zstd-19", zstd 19L);
             ("zstd-fast-1", zstd 103L);
             ("zstd-fast-2", zstd 104L);
             ("zstd-fast-3", zstd 105L);
             ("zstd-fast-4", zstd 106L);
             ("zstd-fast-5", zstd 107L);
             ("zstd-fast-6", zstd 108L);
             ("zstd-fast-7", zstd 109L);
             ("zstd-fast-8", zstd 110L);
             ("zstd-fast-9", zstd 111L);
             ("zstd-fast-10", zstd 112L);
             ("zstd-fast-20", zstd 113L);
             ("zstd-fast-30", zstd 114L);
             ("zstd-fast-40", zstd 115L);
             ("zstd-fast-50", zstd 116L);
             ("zstd-fast-60", zstd 117L);
             ("zstd-fast-70", zstd 118L);
             ("zstd-fast-80", zstd 119L);
             ("zstd-fast-90", zstd 120L);
             ("zstd-fast-100", zstd 121L);
             ("zstd-fast-500", zstd 122L);
             ("zstd-fast-1000", zstd 123L);
           |]);
      }
  | Compressratio ->
      {
        name = "compressratio";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume; Snapshot |];
        values = Some "<1.00x or higher if compressed>";
        colname = "RATIO";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Copies ->
      {
        name = "copies";
        prop_type = Index;
        numdefault = 1L;
        strdefault = None;
        readonly = false;
        inherits = true;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume |];
        values = Some "1 | 2 | 3";
        colname = "COPIES";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [| ("1", 1L); ("2", 2L); ("3", 3L) |];
      }
  | Createtxg ->
      {
        name = "createtxg";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume; Snapshot; Bookmark |];
        values = Some "<uint64>";
        colname = "CREATETXG";
        rightalign = true;
        visible = true;
        flex = true;
        index_table = [||];
      }
  | Creation ->
      {
        name = "creation";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume; Snapshot; Bookmark |];
        values = Some "<date>";
        colname = "CREATION";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [||];
      }
  | Dedup ->
      {
        name = "dedup";
        prop_type = Index;
        numdefault = 2L (* ZIO_CHECKSUM_OFF *);
        strdefault = None;
        readonly = false;
        inherits = true;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume |];
        values =
          Some
            "on | off | verify | sha256[,verify] | sha512[,verify] | \
             skein[,verify] | edonr,verify | blake3[,verify]";
        colname = "DEDUP";
        rightalign = false;
        visible = true;
        flex = true;
        index_table =
          (let verify x = Int64.logor x (Int64.shift_left 1L 8) in
           [|
             ("on", 1L);
             ("off", 2L);
             ("verify", verify 1L);
             ("sha256", 8L);
             ("sha256,verify", verify 8L);
             ("sha512", 11L);
             ("sha512,verify", verify 11L);
             ("skein", 12L);
             ("skein,verify", verify 12L);
             ("edonr,verify", verify 13L);
             ("blake3", 14L);
             ("blake3,verify", verify 13L);
           |]);
      }
  | Defer_destroy ->
      {
        name = "defer_destroy";
        prop_type = Index;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Snapshot |];
        values = Some "on | off";
        colname = "DEFER_DESTROY";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [| ("off", 0L); ("on", 1L) |];
      }
  | Devices ->
      {
        name = "devices";
        prop_type = Index;
        numdefault = 1L;
        strdefault = None;
        readonly = false;
        inherits = true;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Snapshot |];
        values = Some "on | off";
        colname = "DEVICES";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [| ("off", 0L); ("on", 1L) |];
      }
  | Dnodesize ->
      {
        name = "dnodesize";
        prop_type = Index;
        numdefault = 0L (* ZFS_DNSIZE_LEGACY *);
        strdefault = None;
        readonly = false;
        inherits = true;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem |];
        values = Some "legacy | auto | 1k | 2k | 4k | 8k | 16k";
        colname = "DNSIZE";
        rightalign = false;
        visible = true;
        flex = true;
        index_table =
          [|
            ("legacy", 0L);
            ("auto", 1L);
            ("1k", 1024L);
            ("2k", 2048L);
            ("4k", 4096L);
            ("8k", 8192L);
            ("16k", 16384L);
          |];
      }
  | Encryption ->
      {
        name = "encryption";
        prop_type = Index;
        numdefault = 2L (* ZIO_CRYPT_OFF *);
        strdefault = None;
        readonly = false;
        inherits = false;
        onetime = true;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume; Snapshot |];
        values =
          Some
            "on | off | aes-128-ccm | aes-192-ccm | aes-256-ccm | aes-128-gcm \
             | aes-192-gcm | aes-256-gcm";
        colname = "ENCRYPTION";
        rightalign = false;
        visible = true;
        flex = true;
        index_table =
          [|
            ("on", 1L);
            ("off", 2L);
            ("aes-128-ccm", 3L);
            ("aes-192-ccm", 4L);
            ("aes-256-ccm", 5L);
            ("aes-128-gcm", 6L);
            ("aes-192-gcm", 7L);
            ("aes-256-gcm", 8L);
          |];
      }
  | Encryption_root ->
      {
        name = "encryptionroot";
        prop_type = String;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume; Snapshot |];
        values = Some "<filesystem | volume>";
        colname = "ENCROOT";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [||];
      }
  | Exec ->
      {
        name = "exec";
        prop_type = Index;
        numdefault = 1L;
        strdefault = None;
        readonly = false;
        inherits = true;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Snapshot |];
        values = Some "on | off";
        colname = "EXEC";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [| ("off", 0L); ("on", 1L) |];
      }
  | Filesystem_count ->
      {
        name = "filesystem_count";
        prop_type = Number;
        numdefault = -1L;
        strdefault = None;
        readonly = true;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem |];
        values = Some "<count>";
        colname = "FSCOUNT";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Filesystem_limit ->
      {
        name = "filesystem_limit";
        prop_type = Number;
        numdefault = -1L;
        strdefault = None;
        readonly = false;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem |];
        values = Some "<count> | none";
        colname = "FSLIMIT";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Guid ->
      {
        name = "guid";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume; Snapshot; Bookmark |];
        values = Some "<uint64>";
        colname = "GUID";
        rightalign = true;
        visible = true;
        flex = true;
        index_table = [||];
      }
  | Inconsistent ->
      {
        name = "inconsistent";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume; Snapshot |];
        values = None;
        colname = "INCONSISTENT";
        rightalign = true;
        visible = false;
        flex = false;
        index_table = [||];
      }
  | Iscsioptions ->
      {
        name = "iscsioptions";
        prop_type = String;
        numdefault = 0L;
        strdefault = None;
        readonly = false;
        inherits = true;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Volume |];
        values = None;
        colname = "ISCSIOPTIONS";
        rightalign = false;
        visible = false;
        flex = true;
        index_table = [||];
      }
  | Ivset_guid ->
      {
        name = "ivsetguid";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume; Snapshot; Bookmark |];
        values = None;
        colname = "IVSETGUID";
        rightalign = true;
        visible = false;
        flex = true;
        index_table = [||];
      }
  | Key_guid ->
      {
        name = "keyguid";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume; Snapshot |];
        values = None;
        colname = "KEYGUID";
        rightalign = true;
        visible = false;
        flex = true;
        index_table = [||];
      }
  | Keyformat ->
      {
        name = "keyformat";
        prop_type = Index;
        numdefault = 0L (* ZFS_KEYFORMAT_NONE *);
        strdefault = None;
        readonly = false;
        inherits = false;
        onetime = false;
        onetime_default = true;
        dataset_types = [| Filesystem; Volume |];
        values = Some "none | raw | hex | passphrase";
        colname = "KEYFORMAT";
        rightalign = false;
        visible = true;
        flex = true;
        index_table =
          [| ("none", 0L); ("raw", 1L); ("hex", 2L); ("passphrase", 3L) |];
      }
  | Keylocation ->
      {
        name = "keylocation";
        prop_type = String;
        numdefault = 0L;
        strdefault = Some "none";
        readonly = false;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume |];
        values = Some "prompt | <file URI> | <https URL> | <http URL>";
        colname = "KEYLOCATION";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [||];
      }
  | Keystatus ->
      {
        name = "keystatus";
        prop_type = Index;
        numdefault = 0L (* ZFS_KEYSTATUS_NONE *);
        strdefault = None;
        readonly = true;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume; Snapshot |];
        values = Some "none | unavailable | available";
        colname = "KEYSTATUS";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [| ("none", 0L); ("unavailable", 1L); ("available", 2L) |];
      }
  | Logbias ->
      {
        name = "logbias";
        prop_type = Index;
        numdefault = 0L (* ZFS_LOGBIAS_LATENCY *);
        strdefault = None;
        readonly = false;
        inherits = true;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume |];
        values = Some "latency | throughput";
        colname = "LOGBIAS";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [| ("latency", 0L); ("throughput", 1L) |];
      }
  | Logicalreferenced ->
      {
        name = "logicalreferenced";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume; Snapshot; Bookmark |];
        values = Some "<size>";
        colname = "LREFER";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Logicalused ->
      {
        name = "logicalused";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume |];
        values = Some "<size>";
        colname = "LUSED";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Mlslabel ->
      {
        name = "mlslabel";
        prop_type = String;
        numdefault = 0L;
        strdefault = Some "none";
        readonly = false;
        inherits = true;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume; Snapshot |];
        values = Some "<sensitivity label>";
        colname = "MLSLABEL";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [||];
      }
  | Mounted ->
      {
        name = "mounted";
        prop_type = Index;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem |];
        values = Some "yes | no";
        colname = "MOUNTED";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [| ("no", 0L); ("yes", 1L) |];
      }
  | Mountpoint ->
      {
        name = "mountpoint";
        prop_type = String;
        numdefault = 0L;
        strdefault = Some "/";
        readonly = false;
        inherits = true;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem |];
        values = Some "<path> | legacy | none";
        colname = "MOUNTPOINT";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [||];
      }
  | Name ->
      {
        name = "name";
        prop_type = String;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume; Snapshot; Bookmark |];
        values = None;
        colname = "NAME";
        rightalign = false;
        visible = false;
        flex = true;
        index_table = [||];
      }
  | Nbmand ->
      {
        name = "nbmand";
        prop_type = Index;
        numdefault = 0L;
        strdefault = None;
        readonly = false;
        inherits = true;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Snapshot |];
        values = Some "on | off";
        colname = "NBMAND";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [| ("off", 0L); ("on", 1L) |];
      }
  | Normalize ->
      {
        name = "normalization";
        prop_type = Index;
        numdefault = 0L;
        strdefault = None;
        readonly = false;
        inherits = false;
        onetime = true;
        onetime_default = false;
        dataset_types = [| Filesystem; Snapshot |];
        values = Some "none | formC | formD | formKC | formKD";
        colname = "NORMALIZATION";
        rightalign = false;
        visible = true;
        flex = true;
        index_table =
          [|
            ("none", 0L);
            ("formD", 0x10L);
            ("formKC", Int64.logor 0x20L 0x40L);
            ("formC", Int64.logor 0x10L 0x40L);
            ("formKD", 0x20L);
          |];
      }
  | Numclones ->
      {
        name = "numclones";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Snapshot |];
        values = None;
        colname = "NUMCLONES";
        rightalign = true;
        visible = false;
        flex = false;
        index_table = [||];
      }
  | Objsetid ->
      {
        name = "objsetid";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume; Snapshot |];
        values = Some "<uint64>";
        colname = "OBJSETID";
        rightalign = true;
        visible = true;
        flex = true;
        index_table = [||];
      }
  | Origin ->
      {
        name = "origin";
        prop_type = String;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume |];
        values = Some "<snapshot>";
        colname = "ORIGIN";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [||];
      }
  | Overlay ->
      {
        name = "overlay";
        prop_type = Index;
        numdefault = 1L;
        strdefault = None;
        readonly = false;
        inherits = true;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem |];
        values = Some "on | off";
        colname = "OVERLAY";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [| ("off", 0L); ("on", 1L) |];
      }
  | Pbkdf2_iters ->
      {
        name = "pbkdf2iters";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = false;
        inherits = false;
        onetime = false;
        onetime_default = true;
        dataset_types = [| Filesystem; Volume |];
        values = Some "<iters>";
        colname = "PBKDF2ITERS";
        rightalign = true;
        visible = true;
        flex = true;
        index_table = [||];
      }
  | Pbkdf2_salt ->
      {
        name = "pbkdf2salt";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = false;
        inherits = false;
        onetime = false;
        onetime_default = true;
        dataset_types = [| Filesystem; Volume |];
        values = None;
        colname = "PBKDF2SALT";
        rightalign = true;
        visible = false;
        flex = false;
        index_table = [||];
      }
  | Prefetch ->
      {
        name = "prefetch";
        prop_type = Index;
        numdefault = 2L (* ZFS_PREFETCH_ALL *);
        strdefault = None;
        readonly = false;
        inherits = true;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume; Snapshot |];
        values = Some "none | metadata | all";
        colname = "PREFETCH";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [| ("none", 0L); ("metadata", 1L); ("all", 2L) |];
      }
  | Prev_snap ->
      {
        name = "prevsnap";
        prop_type = String;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume |];
        values = None;
        colname = "PREVSNAP";
        rightalign = false;
        visible = false;
        flex = true;
        index_table = [||];
      }
  | Primarycache ->
      {
        name = "primarycache";
        prop_type = Index;
        numdefault = 2L (* ZFS_CACHE_ALL *);
        strdefault = None;
        readonly = false;
        inherits = true;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume; Snapshot |];
        values = Some "all | none | metadata";
        colname = "PRIMARYCACHE";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [| ("none", 0L); ("metadata", 1L); ("all", 2L) |];
      }
  | Quota ->
      {
        name = "quota";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = false;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem |];
        values = Some "<size> | none";
        colname = "QUOTA";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Readonly ->
      {
        name = "readonly";
        prop_type = Index;
        numdefault = 0L;
        strdefault = None;
        readonly = false;
        inherits = true;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume |];
        values = Some "on | off";
        colname = "RDONLY";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [| ("off", 0L); ("on", 1L) |];
      }
  | Receive_resume_token ->
      {
        name = "receive_resume_token";
        prop_type = String;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume |];
        values = Some "<string token>";
        colname = "RESUMETOK";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [||];
      }
  | Recordsize ->
      {
        name = "recordsize";
        prop_type = Number;
        numdefault = Int64.shift_left 1L 17 (* SPA_OLD_MAXBLOCKSIZE *);
        strdefault = None;
        readonly = false;
        inherits = true;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem |];
        values = Some "512 to 1M, power of 2";
        colname = "RECSIZE";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Redact_snaps ->
      {
        name = "redact_snaps";
        prop_type = String;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume; Snapshot; Bookmark |];
        values = Some "<snapshot>[,...]";
        colname = "RSNAPS";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [||];
      }
  | Redacted ->
      {
        name = "redacted";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume; Snapshot |];
        values = None;
        colname = "REDACTED";
        rightalign = true;
        visible = false;
        flex = false;
        index_table = [||];
      }
  | Redundant_metadata ->
      {
        name = "redundant_metadata";
        prop_type = Index;
        numdefault = 0L (* ZFS_REDUNDANT_METADATA_ALL *);
        strdefault = None;
        readonly = false;
        inherits = true;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume |];
        values = Some "all | most | some | none";
        colname = "REDUND_MD";
        rightalign = false;
        visible = true;
        flex = true;
        index_table =
          [| ("all", 0L); ("most", 1L); ("some", 2L); ("none", 3L) |];
      }
  | Referenced ->
      {
        name = "referenced";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume; Snapshot; Bookmark |];
        values = Some "<size>";
        colname = "REFER";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Refquota ->
      {
        name = "refquota";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = false;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem |];
        values = Some "<size> | none";
        colname = "REFQUOTA";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Refratio ->
      {
        name = "refcompressratio";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume; Snapshot |];
        values = Some "<1.00x or higher if compressed>";
        colname = "REFRATIO";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Refreservation ->
      {
        name = "refreservation";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = false;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume |];
        values = Some "<size> | none";
        colname = "REFRESERV";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Relatime ->
      {
        name = "relatime";
        prop_type = Index;
        numdefault = 1L;
        strdefault = None;
        readonly = false;
        inherits = true;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem |];
        values = Some "on | off";
        colname = "RELATIME";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [| ("off", 0L); ("on", 1L) |];
      }
  | Remaptxg ->
      {
        name = "remaptxg";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume; Snapshot |];
        values = None;
        colname = "REMAPTXG";
        rightalign = true;
        visible = false;
        flex = false;
        index_table = [||];
      }
  | Reservation ->
      {
        name = "reservation";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = false;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume |];
        values = Some "<size> | none";
        colname = "RESERV";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Secondarycache ->
      {
        name = "secondarycache";
        prop_type = Index;
        numdefault = 2L (* ZFS_CACHE_ALL *);
        strdefault = None;
        readonly = false;
        inherits = true;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume; Snapshot |];
        values = Some "all | none | metadata";
        colname = "SECONDARYCACHE";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [| ("none", 0L); ("metadata", 1L); ("all", 2L) |];
      }
  | Selinux_context ->
      {
        name = "context";
        prop_type = String;
        numdefault = 0L;
        strdefault = Some "none";
        readonly = false;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume; Snapshot |];
        values = Some "<selinux context>";
        colname = "CONTEXT";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [||];
      }
  | Selinux_defcontext ->
      {
        name = "defcontext";
        prop_type = String;
        numdefault = 0L;
        strdefault = Some "none";
        readonly = false;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume; Snapshot |];
        values = Some "<selinux defcontext>";
        colname = "DEFCONTEXT";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [||];
      }
  | Selinux_fscontext ->
      {
        name = "fscontext";
        prop_type = String;
        numdefault = 0L;
        strdefault = Some "none";
        readonly = false;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume; Snapshot |];
        values = Some "<selinux fscontext>";
        colname = "FSCONTEXT";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [||];
      }
  | Selinux_rootcontext ->
      {
        name = "rootcontext";
        prop_type = String;
        numdefault = 0L;
        strdefault = Some "none";
        readonly = false;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume; Snapshot |];
        values = Some "<selinux rootcontext>";
        colname = "ROOTCONTEXT";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [||];
      }
  | Setuid ->
      {
        name = "setuid";
        prop_type = Index;
        numdefault = 1L;
        strdefault = None;
        readonly = false;
        inherits = true;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Snapshot |];
        values = Some "on | off";
        colname = "SETUID";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [| ("off", 0L); ("on", 1L) |];
      }
  | Sharenfs ->
      {
        name = "sharenfs";
        prop_type = String;
        numdefault = 0L;
        strdefault = Some "off";
        readonly = false;
        inherits = true;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem |];
        values = Some "on | off | <NFS share options>";
        colname = "SHARENFS";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [||];
      }
  | Sharesmb ->
      {
        name = "sharesmb";
        prop_type = String;
        numdefault = 0L;
        strdefault = Some "off";
        readonly = false;
        inherits = true;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem |];
        values = Some "on | off | <SMB share options>";
        colname = "SHARESMB";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [||];
      }
  | Snapdev ->
      {
        name = "snapdev";
        prop_type = Index;
        numdefault = 0L (* ZFS_SNAPDEV_HIDDEN *);
        strdefault = None;
        readonly = false;
        inherits = true;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume |];
        values = Some "hidden | visible";
        colname = "SNAPDEV";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [| ("hidden", 0L); ("visible", 1L) |];
      }
  | Snapdir ->
      {
        name = "snapdir";
        prop_type = Index;
        numdefault = 0L (* ZFS_SNAPDIR_HIDDEN *);
        strdefault = None;
        readonly = false;
        inherits = true;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem |];
        values = Some "hidden | visible";
        colname = "SNAPDIR";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [| ("hidden", 0L); ("visible", 1L) |];
      }
  | Snapshot_count ->
      {
        name = "snapshot_count";
        prop_type = Number;
        numdefault = -1L;
        strdefault = None;
        readonly = true;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume |];
        values = Some "<count>";
        colname = "SSCOUNT";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Snapshot_limit ->
      {
        name = "snapshot_limit";
        prop_type = Number;
        numdefault = -1L;
        strdefault = None;
        readonly = false;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume |];
        values = Some "<count> | none";
        colname = "SSLIMIT";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Snapshots_changed ->
      {
        name = "snapshots_changed";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume |];
        values = Some "<date>";
        colname = "SNAPSHOTS_CHANGED";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [||];
      }
  | Special_small_blocks ->
      {
        name = "special_small_blocks";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = false;
        inherits = true;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem |];
        values = Some "zero or 512 to 1M, power of 2";
        colname = "SPECIAL_SMALL_BLOCKS";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Stmf_shareinfo ->
      {
        name = "stmf_sbd_lu";
        prop_type = String;
        numdefault = 0L;
        strdefault = None;
        readonly = false;
        inherits = true;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Volume |];
        values = None;
        colname = "STMF_SBD_LU";
        rightalign = false;
        visible = false;
        flex = true;
        index_table = [||];
      }
  | Sync ->
      {
        name = "sync";
        prop_type = Index;
        numdefault = 0L (* ZFS_SYNC_STANDARD *);
        strdefault = None;
        readonly = false;
        inherits = true;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume |];
        values = Some "standard | always | disabled";
        colname = "SYNC";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [| ("standard", 0L); ("always", 1L); ("disabled", 2L) |];
      }
  | Type ->
      {
        name = "type";
        prop_type = String;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume; Snapshot; Bookmark |];
        values = Some "filesystem | volume | snapshot | bookmark";
        colname = "TYPE";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [||];
      }
  | Unique ->
      {
        name = "unique";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume; Snapshot |];
        values = None;
        colname = "UNIQUE";
        rightalign = true;
        visible = false;
        flex = true;
        index_table = [||];
      }
  | Used ->
      {
        name = "used";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume; Snapshot |];
        values = Some "<size>";
        colname = "USED";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Usedchild ->
      {
        name = "usedbychildren";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume |];
        values = Some "<size>";
        colname = "USEDCHILD";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Usedds ->
      {
        name = "usedbydataset";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume |];
        values = Some "<size>";
        colname = "USEDDS";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Usedrefreserv ->
      {
        name = "usedbyrefreservation";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume |];
        values = Some "<size>";
        colname = "USEDREFRESERV";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Usedsnap ->
      {
        name = "usedbysnapshots";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume |];
        values = Some "<size>";
        colname = "USEDSNAP";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Useraccounting ->
      {
        name = "useraccounting";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume; Snapshot |];
        values = None;
        colname = "USERACCOUNTING";
        rightalign = true;
        visible = false;
        flex = false;
        index_table = [||];
      }
  | Userrefs ->
      {
        name = "userrefs";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Snapshot |];
        values = Some "<count>";
        colname = "USERREFS";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Utf8only ->
      {
        name = "utf8only";
        prop_type = Index;
        numdefault = 0L;
        strdefault = None;
        readonly = false;
        inherits = false;
        onetime = true;
        onetime_default = false;
        dataset_types = [| Filesystem; Snapshot |];
        values = Some "on | off";
        colname = "UTF8ONLY";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [| ("off", 0L); ("on", 1L) |];
      }
  | Version ->
      {
        name = "version";
        prop_type = Index;
        numdefault = 0L;
        strdefault = None;
        readonly = false;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Snapshot |];
        values = Some "1 | 2 | 3 | 4 | 5 | current";
        colname = "VERSION";
        rightalign = false;
        visible = true;
        flex = true;
        index_table =
          [|
            ("1", 1L);
            ("2", 2L);
            ("3", 3L);
            ("4", 4L);
            ("5", 5L);
            ("current", 5L);
          |];
      }
  | Volblocksize ->
      {
        name = "volblocksize";
        prop_type = Number;
        numdefault = 16384L (* ZVOL_DEFAULT_BLOCKSIZE *);
        strdefault = None;
        readonly = false;
        inherits = false;
        onetime = true;
        onetime_default = false;
        dataset_types = [| Volume |];
        values = Some "512 to 128k, power of 2";
        colname = "VOLBLOCK";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Volmode ->
      {
        name = "volmode";
        prop_type = Index;
        numdefault = 0L (* ZFS_VOLMODE_DEFAULT *);
        strdefault = None;
        readonly = false;
        inherits = true;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume |];
        values = Some "default | full | geom | dev | none";
        colname = "VOLMODE";
        rightalign = false;
        visible = true;
        flex = true;
        index_table =
          [|
            ("default", 0L);
            ("full", 1L);
            ("geom", 1L);
            ("dev", 2L);
            ("none", 3L);
          |];
      }
  | Volsize ->
      {
        name = "volsize";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = false;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Snapshot; Volume |];
        values = Some "<size>";
        colname = "VOLSIZE";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Volthreading ->
      {
        name = "volthreading";
        prop_type = Index;
        numdefault = 1L;
        strdefault = None;
        readonly = false;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Volume |];
        values = Some "on | off";
        colname = "VOLTHREADING";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [| ("off", 0L); ("on", 1L) |];
      }
  | Vscan ->
      {
        name = "vscan";
        prop_type = Index;
        numdefault = 0L;
        strdefault = None;
        readonly = false;
        inherits = true;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem |];
        values = Some "on | off";
        colname = "VSCAN";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [| ("off", 0L); ("on", 1L) |];
      }
  | Written ->
      {
        name = "written";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        inherits = false;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Volume; Snapshot |];
        values = Some "<size>";
        colname = "WRITTEN";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Xattr ->
      {
        name = "xattr";
        prop_type = Index;
        numdefault = 1L (* ZFS_XATTR_DIR *);
        strdefault = None;
        readonly = false;
        inherits = true;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem; Snapshot |];
        values = Some "on | off | dir | sa";
        colname = "XATTR";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [| ("off", 0L); ("on", 1L); ("sa", 2L); ("dir", 1L) |];
      }
  | Zoned ->
      {
        name = "jailed";
        prop_type = Index;
        numdefault = 0L;
        strdefault = None;
        readonly = false;
        inherits = true;
        onetime = false;
        onetime_default = false;
        dataset_types = [| Filesystem |];
        values = Some "on | off";
        colname = "JAILED";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [| ("off", 0L); ("on", 1L) |];
      }

let to_string prop = (attributes prop).name

let string_to_index prop str =
  (attributes prop).index_table
  |> Array.find_map (fun (s, i) -> if s = str then Some i else None)

let index_to_string prop idx =
  (attributes prop).index_table
  |> Array.find_map (fun (s, i) -> if i = idx then Some s else None)
