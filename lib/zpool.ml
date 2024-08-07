open Error
open Nvpair

let get_props handle poolname =
  match
    Ioctls.pool_get_props handle poolname
    |> Result.map Nvlist.unpack
    |> Result.map_error zpool_standard_error
  with
  | Ok props -> Ok props
  | Error (e, why) ->
      let what = Printf.sprintf "cannot get props for pool '%s'" poolname in
      Error (e, what, why)

let set_props_version handle poolname props version =
  let ( let* ) = Result.bind in
  match
    let create = false in
    let import = false in
    let* props = Zpool_prop.validate props poolname version create import in
    let packed_props = Nvlist.(pack props Native) in
    Ioctls.pool_set_props handle poolname packed_props
    |> Result.map_error zpool_standard_error
  with
  | Ok () -> Ok ()
  | Error (e, why) ->
      let what = Printf.sprintf "cannot set props for pool '%s'" poolname in
      Error (e, what, why)

let set_props handle poolname props =
  let ( let* ) = Result.bind in
  let* oldprops = get_props handle poolname in
  Option.get @@ Nvlist.lookup_uint64 oldprops Zpool_prop.(to_string Version)
  |> set_props_version handle poolname props

let create handle poolname config propsopt fspropsopt =
  let ( let* ) = Result.bind in
  match
    let* () =
      Zpool_prop.validate_name poolname false
      |> Result.map_error (fun why -> (EzfsInvalidName, why))
    in
    let packed_config = Nvlist.(pack config Native) in
    let* packed_props_opt =
      let* props_opt =
        match propsopt with
        | Some props ->
            let version = 1L in
            let create = true in
            let import = false in
            Zpool_prop.validate props poolname version create import
            |> Result.map Option.some
        | None ->
            if Option.is_some fspropsopt then Ok (Some (Nvlist.alloc ()))
            else Ok None
      in
      let* () =
        if Option.is_some fspropsopt then
          let fsprops = Option.get fspropsopt in
          let zoned =
            let propname = Zfs_prop.(to_string Zoned) in
            match Nvlist.lookup_string fsprops propname with
            | Some "on" -> true
            | _ -> false
          in
          let dataset_type = Zfs_prop.Filesystem in
          let create = true in
          let keyok = true in
          match Zfs_prop.validate fsprops dataset_type zoned create keyok with
          | Ok fsprops ->
              let propname = Zfs_prop.(to_string Special_small_blocks) in
              if
                Nvlist.exists fsprops propname
                && not (Zpool_prop.has_special_vdev config)
              then
                Error
                  ( EzfsBadProp,
                    Printf.sprintf "%s property requires a special vdev"
                      propname )
              else
                let props = Option.get props_opt in
                (* TODO: crypto create *)
                if Zfs_prop.has_encryption_props props then
                  Error (EzfsBadProp, "encryption is TODO")
                else (
                  Nvlist.add_nvlist props "root-props-nvl" fsprops;
                  Ok ())
          | Error e -> Error e
        else Ok ()
      in
      Ok (Option.map (fun props -> Nvlist.(pack props Native)) props_opt)
    in
    match Ioctls.pool_create handle poolname packed_config packed_props_opt with
    | Ok () -> Ok ()
    | Error Unix.EBUSY ->
        Error
          ( EzfsBadDev,
            "one or more vdevs refer to the same device, or one of the devices \
             is part of an active md or lvm device" )
    | Error Unix.ERANGE -> Error (EzfsBadProp, "record size invalid")
    | Error Unix.EOVERFLOW ->
        Error
          ( EzfsBadDev,
            Printf.sprintf
              "one or more devices is less than the minimum size (%s)"
              (Util.nicebytes Const.spa_mindevsize) )
    | Error Unix.ENOSPC ->
        Error (EzfsBadDev, "one or more devices is out of space")
    | Error errno -> Error (zpool_standard_error errno)
  with
  | Ok () -> Ok ()
  | Error (e, why) ->
      let what = Printf.sprintf "cannot create '%s'" poolname in
      Error (e, what, why)

let destroy handle poolname logmsg =
  let mountpoint =
    (* TODO: Zfs.get_props *)
    None
  in
  match
    match Ioctls.pool_destroy handle poolname logmsg with
    | Ok () -> (
        match mountpoint with
        | Some path ->
            ignore (Unix.rmdir path);
            Ok ()
        | None -> Ok ())
    | Error Unix.EROFS -> Error (EzfsBadDev, "one or more devices is read only")
    | Error errno -> Error (zpool_standard_error errno)
  with
  | Ok () -> Ok ()
  | Error (e, why) ->
      let what = Printf.sprintf "cannot destroy '%s'" poolname in
      Error (e, what, why)

let checkpoint handle poolname =
  match
    Ioctls.pool_checkpoint handle poolname
    |> Result.map_error zpool_standard_error
  with
  | Ok () -> Ok ()
  | Error (e, why) ->
      let what = Printf.sprintf "cannot checkpoint '%s'" poolname in
      Error (e, what, why)

let discard_checkpoint handle poolname =
  match
    Ioctls.pool_discard_checkpoint handle poolname
    |> Result.map_error zpool_standard_error
  with
  | Ok () -> Ok ()
  | Error (e, why) ->
      let what = Printf.sprintf "cannot discard checkpoint in '%s'" poolname in
      Error (e, what, why)

let export handle poolname force hardforce logmsg =
  match
    match Ioctls.pool_export handle poolname force hardforce logmsg with
    | Ok () -> Ok ()
    | Error Unix.EXDEV ->
        let why =
          Printf.sprintf
            "'%s' has an active shared spare which could be used by other \
             pools once '%s' is exported"
            poolname poolname
        in
        Error (EzfsActiveSpare, why)
    | Error errno -> Error (zpool_standard_error errno)
  with
  | Ok () -> Ok ()
  | Error (e, why) ->
      let what = Printf.sprintf "cannot export '%s'" poolname in
      Error (e, what, why)

let tryimport handle config =
  match
    let packed_config = Nvlist.(pack config Native) in
    Ioctls.pool_tryimport handle packed_config
    |> Result.map_error zpool_standard_error
  with
  | Ok packed_config -> Ok (Nvlist.unpack packed_config)
  | Error (e, why) ->
      let what = "cannot refresh config" in
      Error (e, what, why)

let import handle config newnameopt propsopt flags =
  let ( let* ) = Result.bind in
  let origname = Option.get @@ Nvlist.lookup_string config "name" in
  match
    let* poolname =
      match newnameopt with
      | Some newname ->
          Zpool_prop.validate_name newname false
          |> Result.map (fun () -> newname)
          |> Result.map_error (fun why -> (EzfsInvalidName, why))
      | None -> Ok origname
    in
    let* packed_props_opt =
      let* props_opt =
        match propsopt with
        | Some props ->
            let version = Option.get @@ Nvlist.lookup_uint64 config "version" in
            let create = false in
            let import = true in
            Zpool_prop.validate props origname version create import
            |> Result.map Option.some
        | None -> Ok None
      in
      Ok (Option.map (fun props -> Nvlist.(pack props Native)) props_opt)
    in
    let guid = Option.get @@ Nvlist.lookup_uint64 config "pool_guid" in
    let packed_config = Nvlist.(pack config Native) in
    match
      Ioctls.pool_import handle poolname guid packed_config packed_props_opt
        flags
    with
    | Ok packed_config -> Ok (Nvlist.unpack packed_config)
    | Error (packed_errors, errno) -> (
        let errors = Nvlist.unpack packed_errors in
        match errno with
        | Unix.EOPNOTSUPP -> (
            match Nvlist.lookup_nvlist errors "load_info" with
            | Some info -> (
                match Nvlist.lookup_nvlist info "unsup_feat" with
                | Some features_nvl ->
                    let features =
                      let rec format_feature_list prev list =
                        match Nvlist.next_nvpair features_nvl prev with
                        | Some pair ->
                            let name = Nvpair.name pair in
                            let desc = Nvpair.value_string pair in
                            let s =
                              if String.length desc > 0 then
                                Printf.sprintf "\t%s (%s)\n" name desc
                              else Printf.sprintf "\t%s\n" name
                            in
                            format_feature_list (Some pair) (s :: list)
                        | None -> String.concat "" (List.rev list)
                      in
                      format_feature_list None []
                    in
                    let why =
                      "This pool uses the following feature(s) not supported \
                       by this system:\n" ^ features
                    in
                    if Nvlist.exists info "can_rdonly" then
                      Error
                        ( EzfsBadVersion,
                          why
                          ^ "All unsupported features are only required for \
                             writing to the pool.\n\
                             The pool can be imported read only." )
                    else Error (EzfsBadVersion, why)
                | None -> Error (EzfsBadVersion, to_string EzfsBadVersion))
            | None -> Error (EzfsBadVersion, to_string EzfsBadVersion))
        | Unix.EUNKNOWNERR 71 (* EREMOTE (EREMOTEIO) *) -> (
            match Nvlist.lookup_nvlist errors "load_info" with
            | Some info ->
                let mmp_state =
                  Option.get @@ Nvlist.lookup_uint64 info "mmp_state"
                in
                let hostname =
                  match Nvlist.lookup_string info "mmp_hostname" with
                  | Some mmp_hostname -> mmp_hostname
                  | None -> "<unknown>"
                in
                let hostid =
                  match Nvlist.lookup_uint64 info "mmp_hostid" with
                  | Some mmp_hostid -> mmp_hostid
                  | None -> 0L
                in
                let why =
                  match mmp_state with
                  | 0L (* MMP_STATE_ACTIVE *) ->
                      Printf.sprintf
                        "pool is imported on host '%s' (hostid=%Lx).\n\
                         Export the pool on the other system, then import."
                        hostname hostid
                  | 2L (* MMP_STATE_NO_HOSTID *) ->
                      "pool has the multihost property on and the system's \
                       hostid is not set.\n\
                       Set a unique system hostid."
                  | _ -> "unknown mmp_state"
                in
                Error (EzfsActivePool, why)
            | None -> Error (EzfsActivePool, to_string EzfsActivePool))
        | Unix.EINVAL -> Error (EzfsInvalConfig, to_string EzfsInvalConfig)
        | Unix.EROFS -> Error (EzfsBadDev, "one or more devices is read only")
        | Unix.ENXIO -> (
            match Nvlist.lookup_nvlist errors "load_info" with
            | Some info -> (
                match Nvlist.lookup_nvlist info "missing_vdevs" with
                | Some missing_nvl ->
                    let missing = Util.format_vdev_tree missing_nvl "" None 2 in
                    let why =
                      "The devices below are missing or corrupted:\n" ^ missing
                    in
                    Error (EzfsBadDev, why)
                | None -> Error (zpool_standard_error errno))
            | None -> Error (zpool_standard_error errno))
        | Unix.EEXIST -> Error (zpool_standard_error errno)
        | Unix.EBUSY ->
            Error (EzfsBadDev, "one or more devices are already in use")
        | Unix.ENAMETOOLONG ->
            Error
              ( EzfsNameTooLong,
                "new name of at least one dataset is longer than the maximum \
                 allowable length" )
        | _ -> Error (zpool_standard_error errno)
        (* TODO: zpool_explain_recover? *))
  with
  | Ok config -> Ok config
  | Error (e, why) ->
      let what =
        match newnameopt with
        | Some newname ->
            Printf.sprintf "cannot import '%s' as '%s'" origname newname
        | None -> Printf.sprintf "cannot import '%s'" origname
      in
      Error (e, what, why)

let configs handle nsgen =
  match
    (* XXX: libzfs uses zfs_standard_error here *)
    Ioctls.pool_configs handle nsgen |> Result.map_error zpool_standard_error
  with
  | Ok None -> Ok None
  | Ok (Some (nsgen, packed_configs)) ->
      Ok (Some (nsgen, Nvlist.unpack packed_configs))
  | Error (e, why) ->
      let what = "failed to read pool configuration" in
      Error (e, what, why)

let stats handle poolname =
  match Ioctls.pool_stats handle poolname with
  | Ok packed_config ->
      (* (config, available) *)
      Ok (Nvlist.unpack packed_config, true)
  | Error (Some packed_config, _errno) -> Ok (Nvlist.unpack packed_config, false)
  | Error (None, errno) ->
      let e, why = zpool_standard_error errno in
      let what = "failed to read pool stats" in
      Error (e, what, why)

let scan handle poolname scan_func scrub_cmd =
  let open Types in
  match
    match
      match
        let args = Nvlist.alloc () in
        let func = Util.int_of_pool_scan_func scan_func in
        Nvlist.add_uint64 args "scan_type" (Int64.of_int func);
        let cmd = Util.int_of_pool_scrub_cmd scrub_cmd in
        Nvlist.add_uint64 args "scan_command" (Int64.of_int cmd);
        let packed_args = Nvlist.(pack args Native) in
        Ioctls.pool_scrub handle poolname packed_args
      with
      | Ok () -> Ok ()
      | Error (Unix.EUNKNOWNERR errno)
        when errno = zfs_errno_to_int ZfsErrIocCmdUnavail ->
          Ioctls.pool_scan handle poolname scan_func scrub_cmd
      | Error errno -> Error errno
    with
    | Ok () -> Ok ()
    | Error (Unix.EUNKNOWNERR 85 (* ECANCELED *))
      when (scan_func = ScanScrub || scan_func = ScanErrorScrub)
           && scrub_cmd = ScrubNormal ->
        Ok ()
    | Error Unix.ENOENT when scan_func != ScanNone && scrub_cmd = ScrubPause ->
        Ok ()
    | Error Unix.EBUSY -> (
        match stats handle poolname with
        | Ok (config, _available) -> (
            let nvroot =
              Option.get @@ Nvlist.lookup_nvlist config "vdev_tree"
            in
            match Nvlist.lookup_uint64_array nvroot "scan_stats" with
            | Some array ->
                let pss = Util.pool_scan_stat_of_array array in
                if
                  pss.func = Int64.of_int (Util.int_of_pool_scan_func ScanScrub)
                  && pss.state
                     = Int64.of_int (Util.int_of_dsl_scan_state Scanning)
                then
                  if pss.pass_scrub_pause = 0L then (
                    assert (scrub_cmd = ScrubNormal);
                    Error (EzfsScrubbing, to_string EzfsScrubbing))
                  else if scan_func = ScanErrorScrub then (
                    assert (scrub_cmd = ScrubNormal);
                    Error
                      ( EzfsScrubPausedToCancel,
                        to_string EzfsScrubPausedToCancel ))
                  else (
                    assert (scan_func = ScanScrub);
                    assert (scrub_cmd = ScrubPause);
                    Error (EzfsScrubPaused, to_string EzfsScrubPaused))
                else if
                  pss.error_scrub_func
                  = Int64.of_int (Util.int_of_pool_scan_func ScanErrorScrub)
                  && pss.error_scrub_state
                     = Int64.of_int (Util.int_of_dsl_scan_state ErrorScrubbing)
                then
                  if pss.pass_error_scrub_pause = 0L then (
                    assert (scrub_cmd = ScrubNormal);
                    Error (EzfsErrorScrubbing, to_string EzfsErrorScrubbing))
                  else (
                    assert (scan_func = ScanErrorScrub);
                    assert (scrub_cmd = ScrubPause);
                    Error (EzfsErrorScrubPaused, to_string EzfsErrorScrubPaused))
                else Error (EzfsResilvering, to_string EzfsResilvering)
            | None -> Error (EzfsResilvering, to_string EzfsResilvering))
        | Error _ -> Error (EzfsResilvering, to_string EzfsResilvering))
    | Error Unix.ENOENT -> Error (EzfsNoScrub, to_string EzfsNoScrub)
    | Error Unix.EOPNOTSUPP when scan_func = ScanResilver ->
        Error (EzfsNoResilverDefer, to_string EzfsNoResilverDefer)
    | Error errno -> Error (zpool_standard_error errno)
  with
  | Ok () -> Ok ()
  | Error (e, why) ->
      let what =
        match scan_func with
        | ScanScrub | ScanErrorScrub ->
            if scrub_cmd = ScrubPause then
              Printf.sprintf "cannot pause scrubbing %s" poolname
            else (
              assert (scrub_cmd = ScrubNormal);
              Printf.sprintf "cannot scrub %s" poolname)
        | ScanResilver ->
            assert (scrub_cmd = ScrubNormal);
            Printf.sprintf "cannot restart resilver on %s" poolname
        | ScanNone -> Printf.sprintf "cannot cancel scrubbing %s" poolname
      in
      Error (e, what, why)

let freeze handle poolname =
  match
    Ioctls.pool_freeze handle poolname |> Result.map_error zpool_standard_error
  with
  | Ok () -> Ok ()
  | Error (e, why) ->
      let what = Printf.sprintf "failed to freeze pool '%s'" poolname in
      Error (e, what, why)

let upgrade handle poolname version =
  match
    Ioctls.pool_upgrade handle poolname version
    |> Result.map_error zpool_standard_error
  with
  | Ok () -> Ok ()
  | Error (e, why) ->
      let what = Printf.sprintf "cannot upgrade '%s'" poolname in
      Error (e, what, why)

let get_history handle poolname cookie =
  match
    Ioctls.pool_get_history handle poolname cookie
    |> Result.map_error zpool_standard_error
  with
  | Ok None -> Ok None
  | Ok (Some buf) ->
      let buflen = Bytes.length buf in
      let rec unpack_record offset records =
        let recstart = offset + 8 in
        if recstart >= buflen then (List.rev records, offset)
        else
          let reclen = Bytes.get_int64_le buf offset |> Int64.to_int in
          if recstart + reclen > buflen then (List.rev records, offset)
          else
            let packed_record = Bytes.sub buf recstart reclen in
            let record = Nvlist.unpack packed_record in
            let next_offset = recstart + reclen in
            unpack_record next_offset (record :: records)
      in
      let records, cookie = unpack_record 0 [] in
      Ok (Some (records, cookie))
  | Error (e, why) ->
      let what = Printf.sprintf "cannot get history for '%s'" poolname in
      Error (e, what, why)

let reguid handle poolname =
  match
    Ioctls.pool_reguid handle poolname |> Result.map_error zpool_standard_error
  with
  | Ok () -> Ok ()
  | Error (e, why) ->
      let what = Printf.sprintf "cannot reguid '%s'" poolname in
      Error (e, what, why)

let reopen handle poolname scrub_restart =
  match
    let args = Nvlist.alloc () in
    Nvlist.add_boolean_value args "scrub_restart" scrub_restart;
    let packed_args = Nvlist.(pack args Native) in
    Ioctls.pool_reopen handle poolname (Some packed_args)
    |> Result.map_error zpool_standard_error
  with
  | Ok () -> Ok ()
  | Error (e, why) ->
      let what = Printf.sprintf "cannot reopen '%s'" poolname in
      Error (e, what, why)

let sync handle poolname force =
  match
    let args = Nvlist.alloc () in
    Nvlist.add_boolean_value args "force" force;
    let packed_args = Nvlist.(pack args Native) in
    Ioctls.pool_sync handle poolname packed_args
    |> Result.map_error zpool_standard_error
  with
  | Ok () -> Ok ()
  | Error (e, why) ->
      let what = Printf.sprintf "sync '%s' failed" poolname in
      Error (e, what, why)

let inject_fault handle poolname record flags =
  match
    match
      let iflags =
        Array.fold_right
          (fun flag -> Types.int_of_zinject_flag flag |> Int.logor)
          flags 0
      in
      Ioctls.inject_fault handle poolname record iflags
    with
    | Ok id -> Ok id
    | Error Unix.EDOM ->
        Error (EzfsPoolInvalArg, "block level exceeds max level of object")
    | Error Unix.EEXIST ->
        let why =
          match Util.zinject_type_of_int (Int32.to_int record.cmd) with
          | ZinjectDelayImport -> "pool already imported"
          | ZinjectDelayExport -> "a handler already exists"
          | _ -> Unix.error_message Unix.EEXIST
        in
        Error (EzfsExists, why)
    | Error Unix.ENOENT -> (
        match Util.zinject_type_of_int (Int32.to_int record.cmd) with
        | ZinjectDelayImport ->
            Error (EzfsIocNotSupported, "import delay injector not supported")
        | _ ->
            let why = Unix.error_message Unix.ENOENT in
            Error (EzfsNoEnt, why))
    | Error errno ->
        let why = Unix.error_message errno in
        Error (EzfsUnknown, why)
  with
  | Ok id -> Ok id
  | Error (e, why) ->
      let what = "failed to add handler" in
      Error (e, what, why)

let clear_fault handle id =
  match Ioctls.clear_fault handle id with
  | Ok () -> Ok ()
  | Error errno ->
      let what = Printf.sprintf "failed to remove handler %Lu" id in
      let why = Unix.error_message errno in
      Error (EzfsUnknown, what, why)

let inject_list_next handle id =
  match Ioctls.inject_list_next handle id with
  | Ok next -> Ok next
  | Error errno ->
      let what = "unable to list handlers" in
      let why = Unix.error_message errno in
      Error (EzfsUnknown, what, why)

let error_log handle poolname =
  match
    Ioctls.error_log handle poolname |> Result.map_error zpool_standard_error
  with
  | Ok errors -> Ok errors
  | Error (e, why) ->
      let what =
        Printf.sprintf "list of errors unavailable for pool '%s'" poolname
      in
      Error (e, what, why)

let clear handle poolname =
  match
    Ioctls.clear handle poolname None None
    |> Result.map_error zpool_standard_error
  with
  | Ok (Some _) -> failwith "unexpected nvlist from ioctl"
  | Ok None -> Ok ()
  | Error (e, why) ->
      let what = Printf.sprintf "cannot clear errors for '%s'" poolname in
      Error (e, what, why)

let clear_rewind handle poolname rewind =
  match
    let packed_rewind = Nvlist.(pack rewind Native) in
    Ioctls.clear handle poolname None (Some packed_rewind)
    |> Result.map_error zpool_standard_error
  with
  | Ok None -> failwith "expected nvlist from ioctl"
  | Ok (Some packed_config) ->
      let config = Nvlist.unpack packed_config in
      Ok config
  | Error (e, why) ->
      let what = Printf.sprintf "cannot clear errors for '%s'" poolname in
      Error (e, what, why)

let clear_vdev handle poolname guid =
  match
    Ioctls.clear handle poolname (Some guid) None
    |> Result.map_error zpool_standard_error
  with
  | Ok (Some _) -> failwith "unexpected nvlist from ioctl"
  | Ok None -> Ok ()
  | Error (e, why) ->
      let what = Printf.sprintf "cannot clear errors for %Lx" guid in
      Error (e, what, why)

let initialize handle poolname func vdevs =
  match
    match
      let args = Nvlist.alloc () in
      let ifunc = Util.int_of_pool_initialize_func func in
      Nvlist.add_uint64 args "initialize_command" (Int64.of_int ifunc);
      Nvlist.add_nvlist args "initialize_vdevs" vdevs;
      let packed_args = Nvlist.(pack args Native) in
      Ioctls.pool_initialize handle poolname packed_args
    with
    | Ok () -> Ok ()
    | Error (Some packed_errors, errno) ->
        let errors = Nvlist.unpack packed_errors in
        let vdev_errors =
          let vdev_errors_nvl =
            Option.get @@ Nvlist.lookup_nvlist errors "initialize_vdevs"
          in
          let rec iter_pairs prev list =
            match Nvlist.next_nvpair vdev_errors_nvl prev with
            | None -> List.rev list
            | Some pair ->
                let guid = Int64.of_string @@ Nvpair.name pair in
                let error = Nvpair.value_uint64 pair in
                let new_list = (guid, error) :: list in
                iter_pairs (Some pair) new_list
          in
          iter_pairs None []
        in
        let e, why = zpool_standard_error errno in
        Error (e, vdev_errors, why)
    | Error (None, Unix.EINVAL) when func = PoolInitializeUninit ->
        (* XXX: libzfs quirk for compat with older modules *)
        let why = "uninitialize is not supported by kernel" in
        Error (EzfsIocNotSupported, [], why)
    | Error (None, errno) ->
        let e, why = zpool_standard_error errno in
        Error (e, [], why)
  with
  | Ok () -> Ok ()
  | Error (e, vdev_errors, why) ->
      let what = "operation failed" in
      Error (e, vdev_errors, what, why)

let trim handle poolname func vdevs rate secure =
  match
    match
      let args = Nvlist.alloc () in
      let ifunc = Util.int_of_pool_trim_func func in
      Nvlist.add_uint64 args "trim_command" (Int64.of_int ifunc);
      Nvlist.add_nvlist args "trim_vdevs" vdevs;
      Nvlist.add_uint64 args "trim_rate" rate;
      Nvlist.add_boolean_value args "trim_secure" secure;
      let packed_args = Nvlist.(pack args Native) in
      Ioctls.pool_trim handle poolname packed_args
    with
    | Ok () -> Ok ()
    | Error (Some packed_errors, errno) ->
        let errors = Nvlist.unpack packed_errors in
        let vdev_errors =
          let vdev_errors_nvl =
            Option.get @@ Nvlist.lookup_nvlist errors "trim_vdevs"
          in
          let rec iter_pairs prev list =
            match Nvlist.next_nvpair vdev_errors_nvl prev with
            | None -> List.rev list
            | Some pair ->
                let guid = Int64.of_string @@ Nvpair.name pair in
                let error = Nvpair.value_int64 pair in
                let new_list = (guid, error) :: list in
                iter_pairs (Some pair) new_list
          in
          iter_pairs None []
        in
        let e, why = zpool_standard_error errno in
        Error (e, vdev_errors, why)
    | Error (None, errno) ->
        let e, why = zpool_standard_error errno in
        Error (e, [], why)
  with
  | Ok () -> Ok ()
  | Error (e, vdev_errors, why) ->
      let what = "operation failed" in
      Error (e, vdev_errors, what, why)

let add handle poolname config check_ashift =
  match
    match
      let packed_config = Nvlist.(pack config Native) in
      Ioctls.vdev_add handle poolname packed_config check_ashift
    with
    | Ok () -> Ok ()
    | Error Unix.EBUSY ->
        Error (EzfsBadDev, "one or more vdevs refer to the same device")
    | Error Unix.EINVAL ->
        (* XXX: libzfs has a different error message for draid *)
        Error
          ( EzfsBadDev,
            "invalid config; a pool with removing/removed vdevs does not \
             support adding raidz or dRAID vdevs" )
    | Error Unix.EOVERFLOW ->
        Error
          ( EzfsBadDev,
            Printf.sprintf "device is less than the minimum size (%s)"
              (Util.nicebytes Const.spa_mindevsize) )
    | Error Unix.EOPNOTSUPP ->
        Error (EzfsBadVersion, "pool must be upgraded to add these vdevs")
    | Error errno -> Error (zpool_standard_error errno)
  with
  | Ok () -> Ok ()
  | Error (e, why) ->
      let what = Printf.sprintf "cannot add to '%s'" poolname in
      Error (e, what, why)

let remove handle poolname guid =
  match
    (* TODO: check if draid spare or log device *)
    match Ioctls.vdev_remove handle poolname guid with
    | Ok () -> Ok ()
    | Error Unix.EALREADY ->
        Error (EzfsBusy, "removal for this vdev is already in progress")
    | Error Unix.EINVAL ->
        Error
          ( EzfsInvalConfig,
            "invalid config; all top-level vdevs must have the same sector \
             size and not be raidz" )
    | Error Unix.EBUSY ->
        (* TODO: check if log device *)
        Error (EzfsBusy, "pool busy; removal may already be in progress")
    | Error Unix.EACCES ->
        (* TODO: check if log device *)
        Error (zpool_standard_error Unix.EACCES)
    | Error errno -> Error (zpool_standard_error errno)
  with
  | Ok () -> Ok ()
  | Error (e, why) ->
      let what = Printf.sprintf "cannot remove %Lu" guid in
      Error (e, what, why)

let remove_cancel handle poolname =
  match
    Ioctls.vdev_remove_cancel handle poolname
    |> Result.map_error zpool_standard_error
  with
  | Ok () -> Ok ()
  | Error (e, why) ->
      let what = "cannot cancel removal" in
      Error (e, what, why)

let attach handle poolname guid config replacing rebuild =
  match
    (* TODO: check if log/cache/etc *)
    match
      let packed_config = Nvlist.(pack config Native) in
      Ioctls.vdev_attach handle poolname guid packed_config replacing rebuild
    with
    | Ok () -> Ok ()
    | Error Unix.EOPNOTSUPP ->
        (* TODO: check version, draid spare, type *)
        let why =
          if replacing then "cannot replace this type of vdev"
          else "can only attach to mirrors and top-level disks"
        in
        Error (EzfsBadTarget, why)
    | Error Unix.EINVAL ->
        Error (EzfsInvalConfig, "new device must be a single disk")
    | Error Unix.EBUSY -> Error (EzfsBadDev, "new device is busy")
    | Error Unix.EOVERFLOW -> Error (EzfsBadDev, "device is too small")
    | Error Unix.EDOM ->
        Error (EzfsBadDev, "new device has a different optimal sector size")
    | Error Unix.ENAMETOOLONG ->
        Error
          ( EzfsDevOverflow,
            "resulting top-level vdev spec won't fit in the label" )
    | Error Unix.ENXIO ->
        (* TODO: type check *)
        Error (zpool_standard_error Unix.ENXIO)
    | Error Unix.EADDRINUSE ->
        (* TODO: type check *)
        Error (zpool_standard_error Unix.EADDRINUSE)
    | Error errno -> Error (zpool_standard_error errno)
  with
  | Ok () -> Ok ()
  | Error (e, why) ->
      let what = if replacing then "cannot replace" else "cannot attach" in
      Error (e, what, why)

let detach handle poolname guid =
  match
    match Ioctls.vdev_detach handle poolname guid with
    | Ok () -> Ok ()
    | Error Unix.EOPNOTSUPP ->
        Error (EzfsBadTarget, "only applicable to mirror and replacing vdevs")
    | Error Unix.EBUSY ->
        Error (EzfsNoReplicas, "there are no other replicas of this device")
    | Error errno -> Error (zpool_standard_error errno)
  with
  | Ok () -> Ok ()
  | Error (e, why) ->
      let what = "cannot detach" in
      Error (e, what, why)

let setpath handle poolname guid path =
  match
    Ioctls.vdev_setpath handle poolname guid path
    |> Result.map_error zpool_standard_error
  with
  | Ok () -> Ok ()
  | Error (e, why) ->
      let what = "cannot set path" in
      Error (e, what, why)

let setfru handle poolname guid fru =
  match
    Ioctls.vdev_setfru handle poolname guid fru
    |> Result.map_error zpool_standard_error
  with
  | Ok () -> Ok ()
  | Error (e, why) ->
      let what = "cannot set fru" in
      Error (e, what, why)
