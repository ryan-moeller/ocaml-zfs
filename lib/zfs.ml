open Error
open Nvpair

let stats_simple handle name =
  match
    let simple = true in
    Ioctls.objset_stats handle name simple
    |> Result.map_error zfs_standard_error
  with
  | Ok (stats, None) -> Ok stats
  | Ok (_, Some _) -> failwith "objset_stats returned unexpected bytes"
  | Error (e, why) ->
      let what = Printf.sprintf "failed to get stats for objset '%s'" name in
      Error (e, what, why)

let stats handle name =
  match
    let simple = false in
    Ioctls.objset_stats handle name simple
    |> Result.map_error zfs_standard_error
  with
  | Ok (stats, Some packed_props) ->
      let props = Nvlist.unpack packed_props in
      Ok (stats, props)
  | Ok (_, None) -> failwith "objset_stats failed to return props"
  | Error (e, why) ->
      let what = Printf.sprintf "failed to get stats for objset '%s'" name in
      Error (e, what, why)

let zplprops handle name =
  match
    Ioctls.objset_zplprops handle name |> Result.map_error zfs_standard_error
  with
  | Ok packed_props ->
      let props = Nvlist.unpack packed_props in
      Ok props
  | Error (e, why) ->
      let what =
        Printf.sprintf "failed to get zpl props for objset '%s'" name
      in
      Error (e, what, why)

let dataset_list_next_simple handle name cookie =
  match
    let simple = true in
    Ioctls.dataset_list_next handle name simple cookie
    |> Result.map_error zfs_standard_error
  with
  | Ok None -> Ok None
  | Ok (Some (next_name, stats, None, next_cookie)) ->
      Ok (Some (next_name, stats, next_cookie))
  | Ok (Some (_, _, Some _, _)) ->
      failwith "dataset_list_next returned unexpected bytes"
  | Error (e, why) ->
      let what = "failed to list next dataset" in
      Error (e, what, why)

let dataset_list_next handle name cookie =
  match
    let simple = false in
    Ioctls.dataset_list_next handle name simple cookie
    |> Result.map_error zfs_standard_error
  with
  | Ok None -> Ok None
  | Ok (Some (next_name, stats, Some packed_props, next_cookie)) ->
      let props = Nvlist.unpack packed_props in
      Ok (Some (next_name, stats, props, next_cookie))
  | Ok (Some (_, _, None, _)) ->
      failwith "dataset_list_next failed to return props"
  | Error (e, why) ->
      let what = "failed to list next dataset" in
      Error (e, what, why)

let snapshot_list_next_simple handle name cookie =
  match
    let simple = true in
    Ioctls.snapshot_list_next handle name simple cookie
    |> Result.map_error zfs_standard_error
  with
  | Ok None -> Ok None
  | Ok (Some (next_name, stats, None, next_cookie)) ->
      Ok (Some (next_name, stats, next_cookie))
  | Ok (Some (_, _, Some _, _)) ->
      failwith "snapshot_list_next returned unexpected bytes"
  | Error (e, why) ->
      let what = "failed to list next snapshot" in
      Error (e, what, why)

let snapshot_list_next handle name cookie =
  match
    let simple = false in
    Ioctls.snapshot_list_next handle name simple cookie
    |> Result.map_error zfs_standard_error
  with
  | Ok None -> Ok None
  | Ok (Some (next_name, stats, Some packed_props, next_cookie)) ->
      let props = Nvlist.unpack packed_props in
      Ok (Some (next_name, stats, props, next_cookie))
  | Ok (Some (_, _, None, _)) ->
      failwith "snapshot_list_next failed to return props"
  | Error (e, why) ->
      let what = "failed to list next snapshot" in
      Error (e, what, why)

let set handle name props dataset_type zoned =
  let ( let* ) = Result.bind in
  match
    let create = false in
    let keyok = false in
    let* props = Zfs_prop.validate props dataset_type zoned create keyok in
    (* XXX: libzfs automates reservation if volsize is being set *)
    match
      let packed_props = Nvlist.(pack props Native) in
      Ioctls.set_prop handle name packed_props
    with
    | Ok () -> Ok ()
    | Error (None, errno) -> Error (zfs_standard_error errno)
    | Error (Some packed_errors, _errno) ->
        let errors = Nvlist.unpack packed_errors in
        let rec format_description prev e list =
          match Nvlist.next_nvpair errors prev with
          | Some pair ->
              let propname = Nvpair.name pair in
              let prop = Zfs_prop.of_string propname in
              (*
               * XXX: libzfs ignores the individual errors and uses
               * errno from the ioctl for all props instead.
               *)
              let errno = Nvpair.value_int32 pair |> Int32.to_int in
              let error = Util.error_of_int errno in
              let e, why = Zfs_prop.zfs_setprop_error prop error in
              let msg = Printf.sprintf "%s: %s" propname why in
              format_description (Some pair) e (msg :: list)
          | None -> (e, String.concat "\n" (List.rev list))
        in
        Error (format_description None EzfsBadProp [])
  with
  | Ok () -> Ok ()
  | Error (e, why) ->
      let what = Printf.sprintf "failed to set props for '%s'" name in
      Error (e, what, why)

let create handle name propsopt dataset_type zoned =
  let ( let* ) = Result.bind in
  match
    let* () =
      Zfs_prop.validate_name name [| dataset_type |] true
      |> Result.map_error (fun why -> (EzfsInvalidName, why))
    in
    (* TODO: validate depth *)
    let args = Nvlist.alloc () in
    let* ost =
      match dataset_type with
      | Filesystem -> Ok Types.ObjsetTypeZfs
      | Volume -> Ok Types.ObjsetTypeZvol
      | _ -> Error (EzfsBadType, to_string EzfsBadType)
    in
    let ost = Util.int_of_objset_type ost in
    Nvlist.add_int32 args "type" @@ Int32.of_int ost;
    let* () =
      if Option.is_some propsopt then
        let props = Option.get propsopt in
        let create = true in
        let keyok = true in
        match Zfs_prop.validate props dataset_type zoned create keyok with
        | Ok props ->
            (* TODO: crypto create *)
            if Zfs_prop.has_encryption_props props then
              Error (EzfsBadProp, "encryption is TODO")
            else (
              Nvlist.add_nvlist args "props" props;
              Ok ())
        | Error e -> Error e
      else Ok ()
    in
    match
      let packed_args = Nvlist.(pack args Native) in
      Ioctls.create handle name packed_args
    with
    | Ok () -> Ok ()
    | Error Unix.ENOENT ->
        (* TODO: check parent exists, add name to error message *)
        Error (EzfsNoEnt, "no such parent")
    | Error Unix.EOPNOTSUPP ->
        Error
          (EzfsBadVersion, "pool must be upgraded to set this property or value")
    | Error Unix.EACCES ->
        Error
          (EzfsCryptoFailed, "encryption root's key is not loaded or provided")
    | Error Unix.ERANGE ->
        Error (EzfsBadProp, "invalid property value(s) specified")
    | Error errno -> Error (zfs_standard_error errno)
  with
  | Ok () -> Ok ()
  | Error (e, why) ->
      let what = Printf.sprintf "cannot create '%s'" name in
      Error (e, what, why)

let destroy handle name =
  match
    (* NB: to defer use destroy_snaps *)
    let defer = false in
    Ioctls.destroy handle name defer |> Result.map_error zfs_standard_error
  with
  | Ok () ->
      (* XXX: caller must remove mountpoint *)
      Ok ()
  | Error (e, why) ->
      let what = Printf.printf "cannot destroy '%s'" name in
      Error (e, what, why)
