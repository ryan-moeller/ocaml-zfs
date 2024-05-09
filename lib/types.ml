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

type useracct = { domain : string; rid : int; space : int64 }
type stat = { gen : int64; mode : int64; links : int64; ctime : int64 * int64 }

type zfs_error =
  | EzfsInvalidName
  | EzfsBadProp
  | EzfsPropReadonly
  | EzfsBadVersion
  | EzfsBadPath
