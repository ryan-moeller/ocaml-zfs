open Types

external int_of_descr : Unix.file_descr -> int = "caml_zfs_util_int_of_t"

external int_of_pool_scan_func : pool_scan_func -> int
  = "caml_zfs_util_int_of_t"

external int_of_pool_scrub_cmd : pool_scrub_cmd -> int
  = "caml_zfs_util_int_of_t"

let pool_scan_stat_of_array array =
  assert (Array.length array = 22);
  {
    func = array.(0);
    state = array.(1);
    start_time = array.(2);
    end_time = array.(3);
    to_examine = array.(4);
    examined = array.(5);
    skipped = array.(6);
    processed = array.(7);
    errors = array.(8);
    pass_exam = array.(9);
    pass_start = array.(10);
    pass_scrub_pause = array.(11);
    pass_scrub_spent_paused = array.(12);
    pass_issued = array.(13);
    issued = array.(14);
    error_scrub_func = array.(15);
    error_scrub_state = array.(16);
    error_scrub_start = array.(17);
    error_scrub_end = array.(18);
    error_scrub_examined = array.(19);
    error_scrub_to_be_examined = array.(20);
    pass_error_scrub_pause = array.(21);
  }

external int_of_dsl_scan_state : dsl_scan_state -> int
  = "caml_zfs_util_int_of_t"

external int_of_zinject_type : zinject_type -> int = "caml_zfs_util_int_of_t"

let zinject_type_of_int = function
  | i when i = int_of_zinject_type ZinjectUninitialized -> ZinjectUninitialized
  | i when i = int_of_zinject_type ZinjectDataFault -> ZinjectDataFault
  | i when i = int_of_zinject_type ZinjectDeviceFault -> ZinjectDeviceFault
  | i when i = int_of_zinject_type ZinjectLabelFault -> ZinjectLabelFault
  | i when i = int_of_zinject_type ZinjectIgnoredWrites -> ZinjectIgnoredWrites
  | i when i = int_of_zinject_type ZinjectPanic -> ZinjectPanic
  | i when i = int_of_zinject_type ZinjectDelayIo -> ZinjectDelayIo
  | i when i = int_of_zinject_type ZinjectDecryptFault -> ZinjectDecryptFault
  | i when i = int_of_zinject_type ZinjectDelayImport -> ZinjectDelayImport
  | i when i = int_of_zinject_type ZinjectDelayExport -> ZinjectDelayExport
  | _ -> failwith "unknown zinject_type"

external int_of_pool_initialize_func : pool_initialize_func -> int
  = "caml_zfs_util_int_of_t"

external int_of_pool_trim_func : pool_trim_func -> int
  = "caml_zfs_util_int_of_t"

external get_system_hostid : unit -> int32 = "caml_zfs_util_get_system_hostid"
external getzoneid : unit -> int = "caml_zfs_util_getzoneid"

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

(* Exponentiation by squaring. *)
let rec pow x = function
  | n when n < 0 -> invalid_arg "exponent must be >= 0"
  | 0 -> 1L
  | 1 -> x
  | n when n mod 2 = 0 -> pow (Int64.mul x x) (n / 2)
  | n -> Int64.mul x (pow (Int64.mul x x) ((n - 1) / 2))

let nicenum_format units k_unit num =
  let n, i =
    let rec loop n i =
      if Int64.unsigned_compare n k_unit < 0 || i >= Array.length units then
        (n, i)
      else loop (Int64.unsigned_div n k_unit) (i + 1)
    in
    loop num 0
  in
  let u = Array.get units i in
  let denom = pow k_unit i in
  if i = 0 || Int64.rem num denom = 0L then Printf.sprintf "%Lu%s" n u
  else
    let v = Int64.to_float num /. Int64.to_float denom in
    let rec loop = function
      | precision when precision > 0 ->
          let str = Printf.sprintf "%.*f%s" precision v u in
          if String.length str <= 5 then str else loop (precision - 1)
      | _ -> Printf.sprintf "%.0f%s" v u
    in
    loop 2

let nicenum = nicenum_format [| ""; "K"; "M"; "G"; "T"; "P"; "E" |] 1024L
let nicebytes = nicenum_format [| "B"; "K"; "M"; "G"; "T"; "P"; "E" |] 1024L
let version_is_supported v = (v >= 1L && v <= 28L) || v = 5000L
let isprint c = c >= Char.chr 0x20 && c <= Char.chr 0x7e
let ispower2 x = Int64.logand x (Int64.sub x 1L) = 0L

let rec format_vdev_tree nvl s nameopt indent =
  let open Nvpair in
  let is_log =
    match Nvlist.lookup_uint64 nvl "is_log" with Some 1L -> true | _ -> false
  in
  let s =
    match nameopt with
    | Some name ->
        Printf.sprintf "%s\t%*s%s%s\n" s indent "" name
          (if is_log then " [log]" else "")
    | None -> s
  in
  match Nvlist.lookup_nvlist_array nvl "children" with
  | Some children ->
      (* TODO: formatting env vars *)
      let format_vdev child s =
        let name =
          if Nvlist.exists child "not_present" then
            Nvlist.lookup_uint64 child "guid"
            |> Option.get |> Printf.sprintf "%Lu"
          else
            let vdev_type = Option.get @@ Nvlist.lookup_string child "type" in
            match Nvlist.lookup_string child "path" with
            | Some path ->
                if vdev_type = "disk" then
                  let prefix = "/dev/" in
                  if String.starts_with ~prefix path then
                    let pos = String.length prefix in
                    let len = String.length path - pos in
                    String.sub path pos len
                  else path
                else path
            | None ->
                let path =
                  if vdev_type = "raidz" then
                    Nvlist.lookup_uint64 child "nparity"
                    |> Option.get
                    |> Printf.sprintf "%s%Lu" vdev_type
                  else if vdev_type = "draid" then
                    let children =
                      Option.get @@ Nvlist.lookup_nvlist_array child "children"
                    in
                    let nchildren = Array.length children in
                    let nparity =
                      Option.get @@ Nvlist.lookup_uint64 child "nparity"
                    in
                    let ndata =
                      Option.get @@ Nvlist.lookup_uint64 child "draid_ndata"
                    in
                    let nspares =
                      Option.get @@ Nvlist.lookup_uint64 child "draid_nspares"
                    in
                    Printf.sprintf "draid%Lu:%Lud:%uc:%Lus" nparity ndata
                      nchildren nspares
                  else vdev_type
                in
                let id = Option.get @@ Nvlist.lookup_uint64 child "id" in
                Printf.sprintf "%s-%Lu" path id
        in
        format_vdev_tree child s (Some name) (indent + 2)
      in
      Array.fold_right format_vdev children ""
  | None -> s

let get_load_policy config =
  let open Nvpair in
  let policies = 31l in
  let default =
    {
      rewind = 1l (* ZPOOL_NO_REWIND *);
      maxmeta = 0L;
      maxdata = -1L;
      txg = -1L;
    }
  in
  match Nvlist.lookup_nvlist config "load-policy" with
  | Some policy ->
      let rewind =
        Nvlist.lookup_uint32 policy "load-rewind-policy"
        |> Option.value ~default:default.rewind
      in
      let rewind =
        if Int32.logand rewind (Int32.lognot policies) != 0l then default.rewind
        else if rewind = 0l then default.rewind
        else rewind
      in
      let maxmeta =
        Nvlist.lookup_uint64 policy "load-meta-thresh"
        |> Option.value ~default:default.maxmeta
      in
      let maxdata =
        Nvlist.lookup_uint64 policy "load-data-threash"
        |> Option.value ~default:default.maxdata
      in
      let txg =
        Nvlist.lookup_uint64 policy "load-request-txg"
        |> Option.value ~default:default.txg
      in
      { rewind; maxmeta; maxdata; txg }
  | None -> default
