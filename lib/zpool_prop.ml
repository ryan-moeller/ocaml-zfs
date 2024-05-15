type t =
  | Allocated
  | Altroot
  | Ashift
  | Autoexpand
  | Autoreplace
  | Autotrim
  | Bcloneratio
  | Bclonesaved
  | Bcloneused
  | Bootfs
  | Cachefile
  | Capacity
  | Checkpoint
  | Comment
  | Compatibility
  | Dedupditto
  | Dedupratio
  | Delegation
  | Expandsz
  | Failuremode
  | Fragmentation
  | Free
  | Freeing
  | Guid
  | Health
  | Inval
  | Leaked
  | Listsnaps
  | Load_guid
  | Maxblocksize
  | Maxdnodesize
  | Multihost
  | Name
  | Readonly
  | Size
  | Tname
  | Version

let of_string = function
  | "allocated" -> Allocated
  | "altroot" -> Altroot
  | "ashift" -> Ashift
  | "autoexpand" -> Autoexpand
  | "autoreplace" -> Autoreplace
  | "autotrim" -> Autotrim
  | "bcloneratio" -> Bcloneratio
  | "bclonesaved" -> Bclonesaved
  | "bcloneused" -> Bcloneused
  | "bootfs" -> Bootfs
  | "cachefile" -> Cachefile
  | "capacity" -> Capacity
  | "checkpoint" -> Checkpoint
  | "comment" -> Comment
  | "compatibility" -> Compatibility
  | "dedupditto" -> Dedupditto
  | "dedupratio" -> Dedupratio
  | "delegation" -> Delegation
  | "expandsize" -> Expandsz
  | "failmode" -> Failuremode
  | "fragmentation" -> Fragmentation
  | "free" -> Free
  | "freeing" -> Freeing
  | "guid" -> Guid
  | "health" -> Health
  | "leaked" -> Leaked
  | "listsnapshots" -> Listsnaps
  | "load_guid" -> Load_guid
  | "maxblocksize" -> Maxblocksize
  | "maxdnodesize" -> Maxdnodesize
  | "multihost" -> Multihost
  | "name" -> Name
  | "readonly" -> Readonly
  | "size" -> Size
  | "tname" -> Tname
  | "version" -> Version
  | _ -> Inval

type prop_type = Number | String | Index

type attributes = {
  name : string;
  prop_type : prop_type;
  numdefault : int64;
  strdefault : string option;
  readonly : bool;
  onetime : bool;
  values : string option;
  colname : string;
  rightalign : bool;
  visible : bool;
  flex : bool;
  index_table : (string * int64) array;
}

let attributes = function
  | Inval -> failwith "not a valid property"
  | Allocated ->
      {
        name = "allocated";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        onetime = false;
        values = Some "<size>";
        colname = "ALLOC";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Altroot ->
      {
        name = "altroot";
        prop_type = String;
        numdefault = 0L;
        strdefault = None;
        readonly = false;
        onetime = false;
        values = Some "<path>";
        colname = "ALTROOT";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [||];
      }
  | Ashift ->
      {
        name = "ashift";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = false;
        onetime = false;
        values = Some "<ashift; 9-16; or 0=default";
        colname = "ASHIFT";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Autoexpand ->
      {
        name = "autoexpand";
        prop_type = Index;
        numdefault = 0L;
        strdefault = None;
        readonly = false;
        onetime = false;
        values = Some "on | off";
        colname = "EXPAND";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [| ("off", 0L); ("on", 1L) |];
      }
  | Autoreplace ->
      {
        name = "autoreplace";
        prop_type = Index;
        numdefault = 0L;
        strdefault = None;
        readonly = false;
        onetime = false;
        values = Some "on | off";
        colname = "REPLACE";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [| ("off", 0L); ("on", 1L) |];
      }
  | Autotrim ->
      {
        name = "autotrim";
        prop_type = Index;
        numdefault = 0L;
        strdefault = None;
        readonly = false;
        onetime = false;
        values = Some "on | off";
        colname = "AUTOTRIM";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [| ("off", 0L); ("on", 1L) |];
      }
  | Bcloneratio ->
      {
        name = "bcloneratio";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        onetime = false;
        values = Some "<1.00x or higher if cloned>";
        colname = "BCLONE_RATIO";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Bclonesaved ->
      {
        name = "bclonesaved";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        onetime = false;
        values = Some "<size>";
        colname = "BCLONE_SAVED";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Bcloneused ->
      {
        name = "bcloneused";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        onetime = false;
        values = Some "<size>";
        colname = "BCLONE_USED";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Bootfs ->
      {
        name = "bootfs";
        prop_type = String;
        numdefault = 0L;
        strdefault = None;
        readonly = false;
        onetime = false;
        values = Some "<filesystem>";
        colname = "BOOTFS";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [||];
      }
  | Cachefile ->
      {
        name = "cachefile";
        prop_type = String;
        numdefault = 0L;
        strdefault = None;
        readonly = false;
        onetime = false;
        values = Some "<file> | none";
        colname = "CACHEFILE";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [||];
      }
  | Capacity ->
      {
        name = "capacity";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        onetime = false;
        values = Some "<size>";
        colname = "CAP";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Checkpoint ->
      {
        name = "checkpoint";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        onetime = false;
        values = Some "<size>";
        colname = "CKPOINT";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Comment ->
      {
        name = "comment";
        prop_type = String;
        numdefault = 0L;
        strdefault = None;
        readonly = false;
        onetime = false;
        values = Some "<comment-string>";
        colname = "COMMENT";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [||];
      }
  | Compatibility ->
      {
        name = "compatibility";
        prop_type = String;
        numdefault = 0L;
        strdefault = Some "off";
        readonly = false;
        onetime = false;
        values = Some "<file>[,...] | off | legacy";
        colname = "COMPATIBILITY";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [||];
      }
  | Dedupditto ->
      {
        name = "dedupditto";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = false;
        onetime = false;
        values = None;
        colname = "DEDUPDITTO";
        rightalign = true;
        visible = false;
        flex = false;
        index_table = [||];
      }
  | Dedupratio ->
      {
        name = "dedupratio";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        onetime = false;
        values = Some "<1.00x or higher if deduped>";
        colname = "DEDUP";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Delegation ->
      {
        name = "delegation";
        prop_type = Index;
        numdefault = 1L;
        strdefault = None;
        readonly = false;
        onetime = false;
        values = Some "on | off";
        colname = "DELEGATION";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [| ("off", 0L); ("on", 1L) |];
      }
  | Expandsz ->
      {
        name = "expandsize";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        onetime = false;
        values = Some "<size>";
        colname = "EXPANDSZ";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Failuremode ->
      {
        name = "failmode";
        prop_type = Index;
        numdefault = 0L;
        strdefault = None;
        readonly = false;
        onetime = false;
        values = Some "wait | continue | panic";
        colname = "FAILMODE";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [| ("wait", 0L); ("continue", 1L); ("panic", 2L) |];
      }
  | Fragmentation ->
      {
        name = "fragmentation";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        onetime = false;
        values = Some "<percent>";
        colname = "FRAG";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Free ->
      {
        name = "free";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        onetime = false;
        values = Some "<size>";
        colname = "FREE";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Freeing ->
      {
        name = "freeing";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        onetime = false;
        values = Some "<size>";
        colname = "FREEING";
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
        onetime = false;
        values = Some "<guid>";
        colname = "GUID";
        rightalign = true;
        visible = true;
        flex = true;
        index_table = [||];
      }
  | Health ->
      {
        name = "health";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        onetime = false;
        values = Some "<state>";
        colname = "HEALTH";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Leaked ->
      {
        name = "leaked";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        onetime = false;
        values = Some "<size>";
        colname = "LEAKED";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Listsnaps ->
      {
        name = "listsnapshots";
        prop_type = Index;
        numdefault = 0L;
        strdefault = None;
        readonly = false;
        onetime = false;
        values = Some "on | off";
        colname = "LISTSNAPS";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [| ("off", 0L); ("on", 1L) |];
      }
  | Load_guid ->
      {
        name = "load_guid";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        onetime = false;
        values = Some "<load_guid>";
        colname = "LOAD_GUID";
        rightalign = true;
        visible = true;
        flex = true;
        index_table = [||];
      }
  | Maxblocksize ->
      {
        name = "maxblocksize";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        onetime = false;
        values = None;
        colname = "MAXBLOCKSIZE";
        rightalign = true;
        visible = false;
        flex = false;
        index_table = [||];
      }
  | Maxdnodesize ->
      {
        name = "maxdnodesize";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        onetime = false;
        values = None;
        colname = "MAXDNODESIZE";
        rightalign = true;
        visible = false;
        flex = false;
        index_table = [||];
      }
  | Multihost ->
      {
        name = "multihost";
        prop_type = Index;
        numdefault = 0L;
        strdefault = None;
        readonly = false;
        onetime = false;
        values = Some "on | off";
        colname = "MULTIHOST";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [| ("off", 0L); ("on", 1L) |];
      }
  | Name ->
      {
        name = "name";
        prop_type = String;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        onetime = false;
        values = None;
        colname = "NAME";
        rightalign = false;
        visible = false;
        flex = true;
        index_table = [||];
      }
  | Readonly ->
      {
        name = "readonly";
        prop_type = Index;
        numdefault = 0L;
        strdefault = None;
        readonly = false;
        onetime = false;
        values = Some "on | off";
        colname = "RDONLY";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [| ("off", 0L); ("on", 1L) |];
      }
  | Size ->
      {
        name = "size";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        onetime = false;
        values = Some "<size>";
        colname = "SIZE";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Tname ->
      {
        name = "tname";
        prop_type = String;
        numdefault = 0L;
        strdefault = None;
        readonly = false;
        onetime = true;
        values = None;
        colname = "TNAME";
        rightalign = false;
        visible = false;
        flex = true;
        index_table = [||];
      }
  | Version ->
      {
        name = "version";
        prop_type = Number;
        numdefault = 5000L (* SPA_VERSION *);
        strdefault = None;
        readonly = false;
        onetime = false;
        values = Some "<version>";
        colname = "VERSION";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }

let to_string prop = (attributes prop).name

let string_to_index prop str =
  (attributes prop).index_table
  |> Array.find_map (fun (s, i) -> if s = str then Some i else None)

let index_to_string prop idx =
  (attributes prop).index_table
  |> Array.find_map (fun (s, i) -> if i = idx then Some s else None)

type checked_value = String of string | Uint64 of int64

let validate nvl poolname version create import =
  let open Types in
  let open Nvpair in
  let ( let* ) = Result.bind in
  let ( >>= ) = Result.bind in
  (*
   * Given an nvpair from nvl as property=value, check that the name and value
   * are acceptable to pass on to the kernel.  If the property is index typed,
   * decode the string value to its index.  If the property is number typed,
   * the value may be specified as a string with optional units.  The property
   * name and value are returned on success, otherwise an error type and reason.
   *)
  let check pair =
    let propname = Nvpair.name pair in
    let prop = of_string propname in
    (*
     * Parse the value of a pair into the correct type for the property.
     * Index properties decode the string value into its index.  Number values
     * given as strings are parsed and units if given are applied.
     *)
    let parse_pair attrs =
      let datatype = Nvpair.data_type pair in
      match attrs.prop_type with
      | String ->
          if datatype != String then
            Error (EzfsBadProp, Printf.sprintf "'%s' must be a string" propname)
          else
            let strval = Nvpair.value_string pair in
            if String.length strval > Util.max_prop_len then
              Error (EzfsBadProp, Printf.sprintf "'%s' is too long" propname)
            else Ok (String strval)
      | Index -> (
          if datatype != String then
            Error (EzfsBadProp, Printf.sprintf "'%s' must be a string" propname)
          else
            let strval = Nvpair.value_string pair in
            match string_to_index prop strval with
            | Some intval -> Ok (Uint64 intval)
            | None ->
                Error
                  ( EzfsBadProp,
                    Printf.sprintf "'%s' must be one of '%s'" propname
                      (Option.get attrs.values) ))
      | Number -> (
          match datatype with
          | String -> (
              let strval = Nvpair.value_string pair in
              match Util.nicestrtonum strval with
              | Ok intval -> Ok (Uint64 intval)
              | Error msg -> Error (EzfsBadProp, msg))
          | Uint64 ->
              let intval = Nvpair.value_uint64 pair in
              Ok (Uint64 intval)
          | _ ->
              Error
                (EzfsBadProp, Printf.sprintf "'%s' must be a number" propname))
    in
    if prop = Inval then
      (* Not a zpool property, check if it is a valid feature. *)
      match Zfeature.of_propname propname with
      | Some None ->
          (* Looks like a feature, but not one we know. *)
          Scanf.sscanf propname "feature@%s" (fun fname ->
              Error
                (EzfsBadProp, Printf.sprintf "feature '%s' unsupported" fname))
      | Some _feature ->
          (* We know this feature, validate as such. *)
          if Nvpair.data_type pair != String then
            Error (EzfsBadProp, Printf.sprintf "'%s' must be a string" propname)
          else
            let strval = Nvpair.value_string pair in
            if strval != "enabled" && strval != "disabled" then
              Error
                ( EzfsBadProp,
                  Printf.sprintf
                    "property '%s' can only be set to 'enabled' or 'disabled'"
                    propname )
            else if (not create) && strval = "disabled" then
              Error
                ( EzfsBadProp,
                  Printf.sprintf
                    "property '%s' can only be set to 'disabled' at creation \
                     time"
                    propname )
            else if strval = "disabled" then
              (* FIXME: check pass but add nothing to result? *)
              (* XXX: disabling features broken in libzfs? *)
              Error (EzfsBadProp, "features can't be disabled like this")
            else (* Acceptable feature. *)
              Ok (propname, Uint64 0L)
      | None ->
          (* Not a feature, check if it is a userprop. *)
          if String.contains propname ':' then
            (* Validate as a userprop. *)
            if Nvpair.data_type pair != String then
              Error
                (EzfsBadProp, Printf.sprintf "'%s' must be a string" propname)
            else if String.length propname >= Util.max_name_len then
              Error
                ( EzfsBadProp,
                  Printf.sprintf "property name '%s' is too long" propname )
            else
              let strval = Nvpair.value_string pair in
              if String.length strval >= Util.max_prop_len then
                Error
                  ( EzfsBadProp,
                    Printf.sprintf "property value '%s' is too long" strval )
              else (* Acceptable userprop. *)
                Ok (propname, String strval)
          else
            (* Not a userprop either. *)
            Error (EzfsBadProp, Printf.sprintf "invalid property '%s'" propname)
    else
      (* We have a supported zpool property. *)
      let attrs = attributes prop in
      if attrs.readonly then
        Error (EzfsPropReadonly, Printf.sprintf "'%s' is readonly" propname)
      else if (not create) && attrs.onetime then
        Error
          ( EzfsBadProp,
            Printf.sprintf "property '%s' can only be set at creation time"
              propname )
      else
        match parse_pair attrs with
        | Ok (String strval) ->
            let* () =
              match prop with
              | Bootfs ->
                  if create || import then
                    Error
                      ( EzfsBadProp,
                        Printf.sprintf
                          "property '%s' cannot be set at creation or import \
                           time"
                          propname )
                  else if version < 6L (* SPA_VERSION_BOOTFS *) then
                    Error
                      ( EzfsBadVersion,
                        Printf.sprintf
                          "pool must be upgraded to support '%s' property"
                          propname )
                  else if strval = "" then Ok ()
                  else
                    Zfs_prop.validate_name strval
                      [| Zfs_prop.Filesystem; Zfs_prop.Snapshot |]
                      false
                    >>= (fun () ->
                          if
                            String.equal poolname strval
                            || String.starts_with ~prefix:poolname strval
                               && String.get strval (String.length poolname)
                                  = '/'
                          then Ok ()
                          else
                            Error
                              (Printf.sprintf "'%s' is an invalid name" strval))
                    |> Result.map_error (fun msg -> (EzfsInvalidName, msg))
              | Altroot ->
                  if (not create) && not import then
                    Error
                      ( EzfsBadProp,
                        Printf.sprintf
                          "property '%s' can only be set during pool creation \
                           or import"
                          propname )
                  else if strval = "" || String.get strval 0 != '/' then
                    Error
                      ( EzfsBadPath,
                        Printf.sprintf "bad alternate root '%s'" strval )
                  else Ok ()
              | Cachefile ->
                  if strval = "" || strval = "none" then Ok ()
                  else if not (String.starts_with ~prefix:"/" strval) then
                    Error
                      ( EzfsBadPath,
                        Printf.sprintf
                          "property '%s' must be empty, an absolute path, or \
                           'none'"
                          propname )
                  else
                    let slash_idx = String.rindex strval '/' in
                    let final_comp =
                      String.sub strval slash_idx
                        (String.length strval - slash_idx)
                    in
                    if
                      final_comp = "/" || final_comp = "/."
                      || final_comp = "/.."
                    then
                      Error
                        ( EzfsBadPath,
                          Printf.sprintf "'%s' is not a valid file" strval )
                    else
                      let dirpath = String.sub strval 0 slash_idx in
                      let dirstat = Unix.stat dirpath in
                      if dirstat.st_kind != S_DIR then
                        Error
                          ( EzfsBadPath,
                            Printf.sprintf "'%s' is not a valid directory"
                              dirpath )
                      else Ok ()
              | Compatibility -> (
                  match Util.load_compat strval with
                  | Ok _features -> Ok ()
                  | Error files -> Error (EzfsBadProp, files))
              | Comment ->
                  if not (String.for_all Util.isprint strval) then
                    Error
                      (EzfsBadProp, "comment may only have printable characters")
                  else if String.length strval > Util.max_comment_len then
                    Error
                      ( EzfsBadProp,
                        Printf.sprintf "comment must not exceed %d characters"
                          Util.max_comment_len )
                  else Ok ()
              | _ -> Ok ()
            in
            (* Acceptable string property. *)
            Ok (propname, String strval)
        | Ok (Uint64 intval) ->
            let* () =
              match prop with
              | Version ->
                  if intval < version || not (Util.version_is_supported intval)
                  then
                    Error
                      ( EzfsBadVersion,
                        Printf.sprintf "property '%s' number %Lu is invalid."
                          propname intval )
                  else Ok ()
              | Ashift ->
                  let ashift_min = 9L and ashift_max = 16L in
                  if intval != 0L && (intval < ashift_min || intval > ashift_max)
                  then
                    Error
                      ( EzfsBadProp,
                        Printf.sprintf
                          "property '%s' number %Lu is invalid, only values \
                           between %Lu and %Lu are allowed"
                          propname intval ashift_min ashift_max )
                  else Ok ()
              | Readonly ->
                  if not import then
                    Error
                      ( EzfsBadProp,
                        Printf.sprintf
                          "property '%s' can only be set at import time"
                          propname )
                  else Ok ()
              | Multihost ->
                  if Util.get_system_hostid () = 0l then
                    Error (EzfsBadProp, "requires a non-zero system hostid")
                  else Ok ()
              | _ -> Ok ()
            in
            (* Acceptable integer property. *)
            Ok (propname, Uint64 intval)
        | Error what -> Error what
  in
  (*
   * Build up an nvlist that can be passed to the kernel.
   *)
  let result = Nvlist.alloc () in
  let accept = function
    | propname, String strval -> Nvlist.add_string result propname strval
    | propname, Uint64 intval -> Nvlist.add_uint64 result propname intval
  in
  let rec iter_pairs prev =
    match Nvlist.next_nvpair nvl prev with
    | Some pair -> (
        match check pair with
        | Ok acceptable_pair ->
            accept acceptable_pair;
            iter_pairs (Some pair)
        | Error e -> Error e)
    | None -> Ok result
  in
  iter_pairs None

let validate_name name opening =
  let reserved = [| "mirror"; "raidz"; "draid"; "spare"; "log" |] in
  let name_starts_with prefix = String.starts_with ~prefix name in
  let max_pool_name_len =
    Util.max_name_len - 2 - (2 * String.length Util.origin_dir_name)
  in
  let valid_chars = Str.regexp "^[a-zA-Z0-9-_.: ]+$" in
  let valid_first_char = Str.regexp "^[a-zA-Z]" in
  if (not opening) && Array.exists name_starts_with reserved then
    Error "name is reserved"
  else if String.length name >= max_pool_name_len then Error "name is too long"
  else if not (Str.string_match valid_chars name 0) then
    Error "invalid character in pool name"
  else if not (Str.string_match valid_first_char name 0) then
    Error "name must begin with a letter"
  else Ok ()
