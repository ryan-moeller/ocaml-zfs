module Const = Const
module Error = Error
module Ioctls = Ioctls
module Types = Types
module Userquota_prop = Userquota_prop
module Util = Util
module Vdev_prop = Vdev_prop
module Zfs_prop = Zfs_prop
module Zpool_prop = Zpool_prop
module Zfeature = Zfeature
open Error
open Nvpair

let open_handle = Ioctls.open_handle

module Zpool = struct
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
      match
        Ioctls.pool_create handle poolname packed_config packed_props_opt
      with
      | Ok () -> Ok ()
      | Error Unix.EBUSY ->
          Error
            ( EzfsBadDev,
              "one or more vdevs refer to the same device, or one of the \
               devices is part of an active md or lvm device" )
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
      (* TODO: Zfs.get_props, Zpool.get_props *)
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
      | Error Unix.EROFS ->
          Error (EzfsBadDev, "one or more devices is read only")
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
        let what =
          Printf.sprintf "cannot discard checkpoint in '%s'" poolname
        in
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
              let version =
                Option.get @@ Nvlist.lookup_uint64 config "version"
              in
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
                                  Printf.sprintf "\t%s (%s)\t" name desc
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
                  | None ->
                      Error (EzfsBadVersion, Error.(to_string EzfsBadVersion)))
              | None -> Error (EzfsBadVersion, Error.(to_string EzfsBadVersion))
              )
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
              | None -> Error (EzfsActivePool, Error.(to_string EzfsActivePool))
              )
          | Unix.EINVAL ->
              Error (EzfsInvalConfig, Error.(to_string EzfsInvalConfig))
          | Unix.EROFS -> Error (EzfsBadDev, "one or more devices is read only")
          | Unix.ENXIO -> (
              match Nvlist.lookup_nvlist errors "load_info" with
              | Some info -> (
                  match Nvlist.lookup_nvlist info "missing_vdevs" with
                  | Some missing_nvl ->
                      let missing =
                        Util.format_vdev_tree missing_nvl "" None 2
                      in
                      let why =
                        "The devices below are missing or corrupted:\n"
                        ^ missing
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
end
