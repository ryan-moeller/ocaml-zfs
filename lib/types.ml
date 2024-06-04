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

type pool_scan_stat = {
  func : int64;
  state : int64;
  start_time : int64;
  end_time : int64;
  to_examine : int64;
  examined : int64;
  skipped : int64;
  processed : int64;
  errors : int64;
  pass_exam : int64;
  pass_start : int64;
  pass_scrub_pause : int64;
  pass_scrub_spent_paused : int64;
  pass_issued : int64;
  issued : int64;
  error_scrub_func : int64;
  error_scrub_state : int64;
  error_scrub_start : int64;
  error_scrub_end : int64;
  error_scrub_examined : int64;
  error_scrub_to_be_examined : int64;
  pass_error_scrub_pause : int64;
}

type dsl_scan_state = None | Scanning | Finished | Canceled | ErrorScrubbing

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

type zpool_load_policy = {
  rewind : int32;
  maxmeta : int64;
  maxdata : int64;
  txg : int64;
}
