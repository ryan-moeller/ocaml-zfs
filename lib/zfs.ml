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
