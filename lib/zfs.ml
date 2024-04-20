type import_flags =
  | ImportNormal
  | ImportVerbatim
  | ImportAnyHost
  | ImportMissingLog
  | ImportOnly
  | ImportTempName
  | ImportSkipMmp
  | ImportLoadKeys
  | ImportCheckpoint

type pool_scan_func = ScanNone | ScanScrub | ScanResilver | ScanErrorScrub
type pool_scrub_cmd = ScrubNormal | ScrubPause

type vdev_state =
  | VdevStateUnknown
  | VdevStateClosed
  | VdevStateOffline
  | VdevStateRemoved
  | VdevStateCantOpen
  | VdevStateFaulted
  | VdevStateDegraded
  | VdevStateHealthy

type objset_type =
  | ObjsetTypeNone
  | ObjsetTypeMeta
  | ObjsetTypeZfs
  | ObjsetTypeZvol
  | ObjsetTypeOther
  | ObjsetTypeAny

type objset_stats = {
  num_clones : int64;
  creation_txg : int64;
  guid : int64;
  objset_type : objset_type;
  is_snapshot : bool;
  inconsistent : bool;
  redacted : bool;
  origin : string;
}

type rename_flag = RenameRecursive | RenameNounmount
type zprop_errflag = ZpropErrNoclear | ZpropErrNorestore

type lzc_send_flag =
  | LzcSendFlagEmbedData
  | LzcSendFlagLargeBlock
  | LzcSendFlagCompress
  | LzcSendFlagRaw
  | LzcSendFlagSaved

type zinject_record = {
  objset : int64;
  obj : int64;
  range_start : int64;
  range_end : int64;
  guid : int64;
  level : int32;
  error : int32;
  inject_type : int64;
  freq : int32;
  failfast : int32;
  func : string;
  iotype : int32;
  duration : int32;
  timer : int64;
  nlanes : int64;
  cmd : int32;
  dvas : int32;
}

type zbookmark_phys = {
  objset : int64;
  obj : int64;
  level : int64;
  blkid : int64;
}

type userquota_prop =
  | UserquotaPropUserused
  | UserquotaPropUserquota
  | UserquotaPropGroupused
  | UserquotaPropGroupquota
  | UserquotaPropUserobjused
  | UserquotaPropUserobjquota
  | UserquotaPropGroupobjused
  | UserquotaPropGroupobjquota
  | UserquotaPropProjectused
  | UserquotaPropProjectquota
  | UserquotaPropProjectobjused
  | UserquotaPropProjectobjquota

type useracct = { domain : string; rid : int; space : int64 }
type stat = { gen : int64; mode : int64; links : int64; ctime : int64 * int64 }

module Zfs_ioctls = struct
  type handle

  external open_handle : unit -> handle = "caml_devzfs_open"

  (* pool_create handle name packed_config packed_props *)
  external pool_create :
    handle -> string -> bytes -> bytes option -> (unit, Unix.error) Either.t
    = "caml_zfs_ioc_pool_create"

  (* pool_destroy handle name log_msg *)
  external pool_destroy :
    handle -> string -> string -> (unit, Unix.error) Either.t
    = "caml_zfs_ioc_pool_destroy"

  (* pool_import handle name guid packed_config packed_props flags *)
  external pool_import :
    handle ->
    string ->
    int64 ->
    bytes ->
    bytes option ->
    import_flags array ->
    (bytes, Unix.error) Either.t
    = "caml_zfs_ioc_pool_import_bytecode" "caml_zfs_ioc_pool_import_native"

  (* pool_export handle name force hardforce log_str *)
  external pool_export :
    handle ->
    string ->
    bool ->
    bool ->
    string option ->
    (unit, Unix.error) Either.t = "caml_zfs_ioc_pool_export"

  (* pool_configs handle ns_gen *)
  external pool_configs :
    handle -> int64 -> ((int64 * bytes) option, Unix.error) Either.t
    = "caml_zfs_ioc_pool_configs"

  (* pool_stats handle name *)
  external pool_stats :
    handle -> string -> (bytes, bytes option * Unix.error) Either.t
    = "caml_zfs_ioc_pool_stats"

  (* pool_tryimport handle packed_config *)
  external pool_tryimport : handle -> bytes -> (bytes, Unix.error) Either.t
    = "caml_zfs_ioc_pool_tryimport"

  (* pool_scan handle name func cmd *)
  external pool_scan :
    handle ->
    string ->
    pool_scan_func ->
    pool_scrub_cmd ->
    (unit, Unix.error) Either.t = "caml_zfs_ioc_pool_scan"

  (* pool_freeze handle name *)
  external pool_freeze : handle -> string -> (unit, Unix.error) Either.t
    = "caml_zfs_ioc_pool_freeze"

  (* pool_upgrade handle name version *)
  external pool_upgrade :
    handle -> string -> int64 -> (unit, Unix.error) Either.t
    = "caml_zfs_ioc_pool_upgrade"

  (* pool_get_history handle name offset *)
  external pool_get_history :
    handle -> string -> int64 -> (bytes option, Unix.error) Either.t
    = "caml_zfs_ioc_pool_get_history"

  (* vdev_add handle name packed_config check_ashift *)
  external vdev_add :
    handle -> string -> bytes -> bool -> (unit, Unix.error) Either.t
    = "caml_zfs_ioc_vdev_add"

  (* vdev_remove handle name guid *)
  external vdev_remove :
    handle -> string -> int64 -> (unit, Unix.error) Either.t
    = "caml_zfs_ioc_vdev_remove"

  (* vdev_remove_cancel handle name *)
  external vdev_remove_cancel : handle -> string -> (unit, Unix.error) Either.t
    = "caml_zfs_ioc_vdev_remove_cancel"

  (* vdev_set_state handle name guid state flags *)
  external vdev_set_state :
    handle ->
    string ->
    int64 ->
    vdev_state ->
    int64 ->
    (vdev_state, Unix.error) Either.t = "caml_zfs_ioc_vdev_set_state"

  (* vdev_attach handle name guid packed_config replacing rebuild *)
  external vdev_attach :
    handle ->
    string ->
    int64 ->
    bytes ->
    bool ->
    bool ->
    (unit, Unix.error) Either.t
    = "caml_zfs_ioc_vdev_attach_bytecode" "caml_zfs_ioc_vdev_attach_native"

  (* vdev_detach handle name guid *)
  external vdev_detach :
    handle -> string -> int64 -> (unit, Unix.error) Either.t
    = "caml_zfs_ioc_vdev_detach"

  (* vdev_setpath handle name guid path *)
  external vdev_setpath :
    handle -> string -> int64 -> string -> (unit, Unix.error) Either.t
    = "caml_zfs_ioc_vdev_setpath"

  (* vdev_setfru handle name guid fru *)
  external vdev_setfru :
    handle -> string -> int64 -> string -> (unit, Unix.error) Either.t
    = "caml_zfs_ioc_vdev_setfru"

  (* objset_stats handle name simple *)
  external objset_stats :
    handle ->
    string ->
    bool ->
    (objset_stats * bytes option, Unix.error) Either.t
    = "caml_zfs_ioc_objset_stats"

  (* objset_zplprops handle name *)
  external objset_zplprops : handle -> string -> (bytes, Unix.error) Either.t
    = "caml_zfs_ioc_objset_zplprops"

  (* dataset_list_next handle name simple cookie *)
  external dataset_list_next :
    handle ->
    string ->
    bool ->
    int64 ->
    ((string * objset_stats * bytes option * int64) option, Unix.error) Either.t
    = "caml_zfs_ioc_dataset_list_next"

  (* snapshot_list_next handle name simple cookie *)
  external snapshot_list_next :
    handle ->
    string ->
    bool ->
    int64 ->
    ((string * objset_stats * bytes option * int64) option, Unix.error) Either.t
    = "caml_zfs_ioc_snapshot_list_next"

  (* set_prop handle name packed_props *)
  external set_prop :
    handle -> string -> bytes -> (unit, bytes option * Unix.error) Either.t
    = "caml_zfs_ioc_set_prop"

  (* create handle name packed_args *)
  external create : handle -> string -> bytes -> (unit, Unix.error) Either.t
    = "caml_zfs_ioc_create"

  (* destroy handle name defer *)
  external destroy : handle -> string -> bool -> (unit, Unix.error) Either.t
    = "caml_zfs_ioc_destroy"

  (* rollback handle name packed_args *)
  external rollback :
    handle -> string -> bytes option -> (bytes, Unix.error) Either.t
    = "caml_zfs_ioc_rollback"

  (* rename handle oldname newname flags *)
  external rename :
    handle ->
    string ->
    string ->
    rename_flag array ->
    (unit, string option * Unix.error) Either.t = "caml_zfs_ioc_rename"

  (* recv handle name packed_props packed_override snapname origin fd begin_rec force *)
  external recv :
    handle ->
    string ->
    bytes option ->
    bytes option ->
    string ->
    string option ->
    Unix.file_descr ->
    bytes ->
    bool ->
    (int64 * zprop_errflag array * bytes, Unix.error) Either.t
    = "caml_zfs_ioc_recv_bytecode" "caml_zfs_ioc_recv_native"

  (* send handle name fd fromorigin sendobj fromobj estimate flags *)
  external send :
    handle ->
    string ->
    Unix.file_descr option ->
    bool ->
    int64 ->
    int64 option ->
    bool ->
    lzc_send_flag array ->
    (int64 option, Unix.error) Either.t
    = "caml_zfs_ioc_send_bytecode" "caml_zfs_ioc_send_native"

  (* inject_fault handle name record flags *)
  external inject_fault :
    handle -> string -> zinject_record -> int -> (int64, Unix.error) Either.t
    = "caml_zfs_ioc_inject_fault"

  (* clear_fault handle guid *)
  external clear_fault : handle -> int64 -> (unit, Unix.error) Either.t
    = "caml_zfs_ioc_clear_fault"

  (* inject_list_next handle guid *)
  external inject_list_next :
    handle ->
    int64 ->
    ((int64 * string * zinject_record) option, Unix.error) Either.t
    = "caml_zfs_ioc_inject_list_next"

  (* error_log handle string *)
  external error_log :
    handle -> string -> (zbookmark_phys array, Unix.error) Either.t
    = "caml_zfs_ioc_error_log"

  (* clear handle name guid rewind *)
  external clear :
    handle ->
    string ->
    int64 option ->
    bytes option ->
    (bytes option, Unix.error) Either.t = "caml_zfs_ioc_clear"

  (* promote handle name *)
  external promote :
    handle -> string -> (unit, string option * Unix.error) Either.t
    = "caml_zfs_ioc_promote"

  (* snapshot handle name packed_args *)
  external snapshot :
    handle -> string -> bytes -> (unit, bytes option * Unix.error) Either.t
    = "caml_zfs_ioc_snapshot"

  (* dsobj_to_dsname handle name dsobj *)
  external dsobj_to_dsname :
    handle -> string -> int64 -> (string, Unix.error) Either.t
    = "caml_zfs_ioc_dsobj_to_dsname"

  (* obj_to_path handle name obj *)
  external obj_to_path :
    handle -> string -> int64 -> (string, Unix.error) Either.t
    = "caml_zfs_ioc_obj_to_path"

  (* pool_set_props handle name packed_props *)
  external pool_set_props :
    handle -> string -> bytes -> (unit, Unix.error) Either.t
    = "caml_zfs_ioc_pool_set_props"

  (* pool_get_props handle name *)
  external pool_get_props : handle -> string -> (bytes, Unix.error) Either.t
    = "caml_zfs_ioc_pool_get_props"

  (* set_fsacl handle name un packed_acl *)
  external set_fsacl :
    handle -> string -> bool -> bytes -> (unit, Unix.error) Either.t
    = "caml_zfs_ioc_set_fsacl"

  (* get_fsacl handle name *)
  external get_fsacl : handle -> string -> (bytes, Unix.error) Either.t
    = "caml_zfs_ioc_get_fsacl"

  (* share not implemented in openzfs *)

  (* inherit_prop handle name prop received *)
  external inherit_prop :
    handle -> string -> string -> bool -> (unit, Unix.error) Either.t
    = "caml_zfs_ioc_inherit_prop"

  (* smb_acl not implemented in openzfs *)

  (* userspace_one handle name prop domain id *)
  external userspace_one :
    handle ->
    string ->
    userquota_prop ->
    string ->
    int64 ->
    (int64, Unix.error) Either.t = "caml_zfs_ioc_userspace_one"

  (* userspace_many handle name prop count cursor *)
  external userspace_many :
    handle ->
    string ->
    userquota_prop ->
    int ->
    int64 ->
    (int64 * useracct array, Unix.error) Either.t
    = "caml_zfs_ioc_userspace_many"

  (* userspace_upgrade handle name *)
  external userspace_upgrade : handle -> string -> (unit, Unix.error) Either.t
    = "caml_zfs_ioc_userspace_upgrade"

  (* hold handle name packed_args *)
  external hold :
    handle -> string -> bytes -> (unit, bytes option * Unix.error) Either.t
    = "caml_zfs_ioc_hold"

  (* release handle name packed_args *)
  external release :
    handle -> string -> bytes -> (unit, bytes option * Unix.error) Either.t
    = "caml_zfs_ioc_release"

  (* get_holds handle name *)
  external get_holds : handle -> string -> (bytes, Unix.error) Either.t
    = "caml_zfs_ioc_get_holds"

  (* objset_recvd_props handle name *)
  external objset_recvd_props : handle -> string -> (bytes, Unix.error) Either.t
    = "caml_zfs_ioc_objset_recvd_props"

  (* vdev_split handle name newname packed_conf packed_props export *)
  external vdev_split :
    handle ->
    string ->
    string ->
    bytes ->
    bytes option ->
    bool ->
    (unit, Unix.error) Either.t
    = "caml_zfs_ioc_vdev_split_bytecode" "caml_zfs_ioc_vdev_split_native"

  (* next_obj handle name obj *)
  external next_obj :
    handle -> string -> int64 -> (int64 option, Unix.error) Either.t
    = "caml_zfs_ioc_next_obj"

  (* diff handle to from fd *)
  external diff :
    handle -> string -> string -> Unix.file_descr -> (unit, Unix.error) Either.t
    = "caml_zfs_ioc_diff"

  (* tmp_snapshot handle name prefix cleanup_fd *)
  external tmp_snapshot :
    handle ->
    string ->
    string ->
    Unix.file_descr ->
    (string, Unix.error) Either.t = "caml_zfs_ioc_tmp_snapshot"

  (* obj_to_stats handle name obj *)
  external obj_to_stats :
    handle -> string -> int64 -> (string * stat, Unix.error) Either.t
    = "caml_zfs_ioc_obj_to_stats"

  (* space_written handle name snap *)
  external space_written :
    handle -> string -> string -> (int64 * int64 * int64, Unix.error) Either.t
    = "caml_zfs_ioc_space_written"

  (* space_snaps handle lastsnap packed_args *)
  external space_snaps :
    handle -> string -> bytes -> (bytes, Unix.error) Either.t
    = "caml_zfs_ioc_space_snaps"

  (* destroy_snaps handle name packed_args *)
  external destroy_snaps :
    handle -> string -> bytes -> (unit, bytes option * Unix.error) Either.t
    = "caml_zfs_ioc_destroy_snaps"

  (* pool_reguid handle name *)
  external pool_reguid : handle -> string -> (unit, Unix.error) Either.t
    = "caml_zfs_ioc_pool_reguid"

  (* pool_reopen handle name packed_args *)
  external pool_reopen :
    handle -> string -> bytes option -> (unit, Unix.error) Either.t
    = "caml_zfs_ioc_pool_reopen"

  (* send_progress handle name fd *)
  external send_progress :
    handle -> string -> Unix.file_descr -> (int64 * int64, Unix.error) Either.t
    = "caml_zfs_ioc_send_progress"

  (* log_history handle packed_args *)
  external log_history : handle -> bytes -> (unit, Unix.error) Either.t
    = "caml_zfs_ioc_log_history"

  (* send_new handle tosnap packed_args *)
  external send_new : handle -> string -> bytes -> (unit, Unix.error) Either.t
    = "caml_zfs_ioc_send_new"

  (* send_space handle tosnap packed_args *)
  external send_space :
    handle -> string -> bytes -> (bytes, Unix.error) Either.t
    = "caml_zfs_ioc_send_space"

  (* clone handle name packed_args *)
  external clone :
    handle -> string -> bytes -> (unit, bytes option * Unix.error) Either.t
    = "caml_zfs_ioc_clone"

  (* bookmark handle name packed_args *)
  external bookmark :
    handle -> string -> bytes -> (unit, bytes option * Unix.error) Either.t
    = "caml_zfs_ioc_bookmark"

  (* get_bookmarks handle name packed_props *)
  external get_bookmarks :
    handle -> string -> bytes option -> (bytes, Unix.error) Either.t
    = "caml_zfs_ioc_get_bookmarks"

  (* destroy_bookmarks handle name packed_list *)
  external destroy_bookmarks :
    handle -> string -> bytes -> (unit, bytes option * Unix.error) Either.t
    = "caml_zfs_ioc_destroy_bookmarks"

  (* recv_new handle name packed_args *)
  external recv_new : handle -> string -> bytes -> (bytes, Unix.error) Either.t
    = "caml_zfs_ioc_recv_new"

  (* pool_sync handle name packed_args *)
  external pool_sync : handle -> string -> bytes -> (unit, Unix.error) Either.t
    = "caml_zfs_ioc_pool_sync"

  (* channel_program handle name packed_args memlimit *)
  external channel_program :
    handle ->
    string ->
    bytes ->
    int ->
    (bytes, bytes option * Unix.error) Either.t = "caml_zfs_ioc_channel_program"

  (* load_key handle name packed_args *)
  external load_key : handle -> string -> bytes -> (unit, Unix.error) Either.t
    = "caml_zfs_ioc_load_key"

  (* unload_key handle name *)
  external unload_key : handle -> string -> (unit, Unix.error) Either.t
    = "caml_zfs_ioc_unload_key"

  (* change_key handle name packed_args *)
  external change_key : handle -> string -> bytes -> (unit, Unix.error) Either.t
    = "caml_zfs_ioc_change_key"

  (* remap not implemented on openzfs *)

  (* pool_checkpoint handle name *)
  external pool_checkpoint : handle -> string -> (unit, Unix.error) Either.t
    = "caml_zfs_ioc_pool_checkpoint"

  (* pool_discard_checkpoint handle name *)
  external pool_discard_checkpoint :
    handle -> string -> (unit, Unix.error) Either.t
    = "caml_zfs_ioc_pool_discard_checkpoint"

  (* pool_initialize handle name packed_args *)
  external pool_initialize :
    handle -> string -> bytes -> (unit, bytes option * Unix.error) Either.t
    = "caml_zfs_ioc_pool_initialize"

  (* pool_trim handle name packed_args *)
  external pool_trim :
    handle -> string -> bytes -> (unit, bytes option * Unix.error) Either.t
    = "caml_zfs_ioc_pool_trim"

  (* redact handle name packed_args *)
  external redact : handle -> string -> bytes -> (unit, Unix.error) Either.t
    = "caml_zfs_ioc_redact"

  (* get_bookmark_props handle name *)
  external get_bookmark_props : handle -> string -> (bytes, Unix.error) Either.t
    = "caml_zfs_ioc_get_bookmark_props"

  (* wait handle name packed_args *)
  external wait : handle -> string -> (bytes, Unix.error) Either.t
    = "caml_zfs_ioc_wait"

  (* wait_fs handle name packed_args *)
  external wait_fs : handle -> string -> bytes -> (bytes, Unix.error) Either.t
    = "caml_zfs_ioc_wait_fs"

  (* vdev_get_props handle name packed_args *)
  external vdev_get_props :
    handle -> string -> bytes -> (bytes, Unix.error) Either.t
    = "caml_zfs_ioc_vdev_get_props"

  (* vdev_set_props handle name packed_args *)
  external vdev_set_props :
    handle -> string -> bytes -> (unit, bytes option * Unix.error) Either.t
    = "caml_zfs_ioc_vdev_set_props"

  (* pool_scrub handle name packed_args *)
  external pool_scrub : handle -> string -> bytes -> (unit, Unix.error) Either.t
    = "caml_zfs_ioc_pool_scrub"

  (* nextboot handle packed_args *)
  external nextboot : handle -> bytes -> (unit, Unix.error) Either.t
    = "caml_zfs_ioc_nextboot"

  (* jail handle name jid *)
  external jail : handle -> string -> int -> (unit, Unix.error) Either.t
    = "caml_zfs_ioc_jail"

  (* unjail handle name jid *)
  external unjail : handle -> string -> int -> (unit, Unix.error) Either.t
    = "caml_zfs_ioc_unjail"

  (* set_bootenv handle name packed_args *)
  external set_bootenv :
    handle -> string -> bytes -> (unit, Unix.error) Either.t
    = "caml_zfs_ioc_set_bootenv"

  (* get_bootenv handle name *)
  external get_bootenv : handle -> string -> (bytes, Unix.error) Either.t
    = "caml_zfs_ioc_get_bootenv"
end
