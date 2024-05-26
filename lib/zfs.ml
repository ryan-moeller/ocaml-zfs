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
      let* props = Zpool_prop.validate props poolname version false false in
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
      | Error e -> Error (zpool_standard_error e)
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
      | Error e -> Error (zpool_standard_error e)
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
end
