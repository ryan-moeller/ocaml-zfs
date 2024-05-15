open Types

external int_of_descr : Unix.file_descr -> int = "caml_zfs_util_int_of_descr"

external int_of_pool_scan_func : pool_scan_func -> int
  = "caml_zfs_util_int_of_pool_scan_func"

external int_of_pool_scrub_cmd : pool_scrub_cmd -> int
  = "caml_zfs_util_int_of_pool_scrub_cmd"

external get_system_hostid : unit -> int32 = "caml_zfs_util_get_system_hostid"
external getzoneid : unit -> int = "caml_zfs_util_getzoneid"

type time = int64

type passwd = {
  name : string;
  passwd : string;
  uid : int;
  gid : int;
  change : time;
  access_class : string;
  gecos : string;
  dir : string;
  shell : string;
  expire : time;
}

external getpwnam : string -> (passwd option, Unix.error) result
  = "caml_zfs_util_getpwnam"

type group = {
  name : string;
  passwd : string;
  gid : int;
  members : string array;
}

external getgrnam : string -> (group option, Unix.error) result
  = "caml_zfs_util_getgrnam"

let nicestrtonum s =
  let shiftamt suffix =
    match String.uppercase_ascii suffix with
    | "" | "B" -> Some 0
    | "K" | "KB" | "KIB" -> Some 10
    | "M" | "MB" | "MIB" -> Some 20
    | "G" | "GB" | "GIB" -> Some 30
    | "T" | "TB" | "TIB" -> Some 40
    | "P" | "PB" | "PIB" -> Some 50
    | "E" | "EB" | "EIB" -> Some 60
    | "Z" | "ZB" | "ZIB" -> Some 70
    | _ -> None
  in
  match
    if String.contains s '.' then
      Scanf.sscanf_opt s "%f%s" (fun floatval suffix ->
          match shiftamt suffix with
          | Some amt ->
              let finalfloat = floatval *. Float.pow 2.0 (Float.of_int amt) in
              let maxfloat = Int64.to_float Int64.max_int in
              if finalfloat > maxfloat then Error "numeric value is too large"
              else Ok (Int64.of_float finalfloat)
          | None -> Error (Printf.sprintf "invalid numeric suffix '%s'" suffix))
    else
      Scanf.sscanf_opt s "%Lu%s" (fun intval suffix ->
          match shiftamt suffix with
          | Some amt ->
              if amt >= 64 then Error "numeric value is too large"
              else
                let finalint = Int64.shift_left intval amt in
                let unshifted = Int64.shift_right finalint amt in
                if unshifted != intval then Error "numeric value is too large"
                else Ok finalint
          | None -> Error (Printf.sprintf "invalid numeric suffix '%s'" suffix))
  with
  | Some result -> result
  | None -> Error (Printf.sprintf "bad numeric value '%s'" s)

let isprint c = c >= Char.chr 0x20 && c <= Char.chr 0x7e
let max_prop_len = 1024 (* 1024 on FreeBSD, 4096 on Linux *)
let max_name_len = 256
let max_comment_len = 32
let origin_dir_name = "$ORIGIN"

let validate_name name dstypes modifying =
  if (not (Array.mem Zfs_prop.Snapshot dstypes)) && String.contains name '@'
  then Error "snapshot delimiter '@' is not expected here"
  else if Array.mem Zfs_prop.Snapshot dstypes && not (String.contains name '@')
  then Error "missing '@' delimiter in snapshot name"
  else if
    (not (Array.mem Zfs_prop.Bookmark dstypes)) && String.contains name '#'
  then Error "bookmark delimiter '#' is not expected here"
  else if Array.mem Zfs_prop.Bookmark dstypes && not (String.contains name '#')
  then Error "missing '#' delimiter in bookmark name"
  else if modifying && String.contains name '%' then
    Error "invalid character '%' in name"
  else if String.length name >= max_name_len then Error "name is too long"
  else if String.starts_with ~prefix:"/" name then Error "leading slash in name"
  else if String.ends_with ~suffix:"/" name then Error "trailing slash in name"
  else
    match
      Str.split_delim (Str.regexp "[/@#]") name
      |> List.find_map (function
           | "" ->
               Some "empty component or misplaced '@' or '#' delimiter in name"
           | "." -> Some "self reference, '.' is found in name"
           | ".." -> Some "parent reference, '..' is found in name"
           | component ->
               String.to_seq component
               |> Seq.find_map (fun c ->
                      let valid_chars =
                        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_.: \
                         %"
                      in
                      if String.contains valid_chars c then None
                      else
                        Some (Printf.sprintf "invalid character '%c' in name" c)))
    with
    | Some errmsg -> Error errmsg
    | None ->
        let ndelim =
          String.fold_left
            (fun count c -> count + if String.contains "@#" c then 1 else 0)
            0 name
        in
        if ndelim > 1 then Error "multiple '@' and/or '#' delimiters in name"
        else Ok ()

let version_is_supported v = (v >= 1L && v <= 28L) || v = 5000L

let load_compat compat =
  let module StringSet = Set.Make (String) in
  if compat = "" || compat = "off" then Ok (Array.to_list Zfeature.all_features)
  else if compat = "legacy" then Ok []
  else
    let read_compat_file path =
      try
        let fd = Unix.openfile path [ Unix.O_RDONLY; Unix.O_CLOEXEC ] 0 in
        let st = Unix.fstat fd in
        if st.st_size < 1 || st.st_size > 16384 then None
        else
          let ic = Unix.in_channel_of_descr fd in
          really_input_string ic st.st_size
          |> String.split_on_char '\n'
          |> List.map (String.split_on_char '#')
          |> List.map List.hd
          |> List.concat_map (Str.split (Str.regexp "[, \t][ \t]*"))
          |> List.map String.trim
          |> List.filter_map (fun feature ->
                 match String.split_on_char ':' feature with
                 | [ _org; featname ] ->
                     let feat = Zfeature.of_string featname in
                     if feat = None then None
                     else
                       let attrs = Zfeature.attributes feat in
                       if attrs.guid = feature then Some attrs.name else None
                 | _ -> None)
          |> StringSet.of_list |> Option.some
      with Unix.Unix_error (Unix.ENOENT, _, _) -> None
    in
    let results =
      String.split_on_char ',' compat
      |> List.map (fun filename ->
             [ "/etc/zfs/compatibility.d/"; "/usr/share/zfs/compatibility.d/" ]
             |> List.find_map (fun directory ->
                    read_compat_file (directory ^ filename))
             |> Option.to_result ~none:filename)
    in
    let errors = List.filter Result.is_error results in
    if not (List.is_empty errors) then
      Error (List.map Result.get_error errors |> String.concat ", ")
    else
      let sets = List.map Result.get_ok results in
      let full =
        Zfeature.all_features
        |> Array.map (fun feature -> (Zfeature.attributes feature).name)
        |> Array.to_list |> StringSet.of_list
      in
      let intersection = List.fold_left StringSet.inter full sets in
      Ok (StringSet.to_list intersection |> List.map Zfeature.of_string)

let spa_minblockshift = 9
let spa_minblocksize = Int64.shift_left 1L spa_minblockshift
let spa_old_maxblockshift = 17
let spa_old_maxblocksize = Int64.shift_left 1L spa_old_maxblockshift
let spa_maxblockshift = 24
let spa_maxblocksize = Int64.shift_left 1L spa_maxblockshift
let ispower2 x = Int64.logand x (Int64.sub x 1L) = 0L
