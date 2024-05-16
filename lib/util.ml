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
