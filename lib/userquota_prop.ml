type t =
  | Userused
  | Userquota
  | Groupused
  | Groupquota
  | Userobjused
  | Userobjquota
  | Groupobjused
  | Groupobjquota
  | Projectused
  | Projectquota
  | Projectobjused
  | Projectobjquota

let of_string_opt = function
  | "userused" -> Some Userused
  | "userquota" -> Some Userquota
  | "groupused" -> Some Groupused
  | "groupquota" -> Some Groupquota
  | "userobjused" -> Some Userobjused
  | "userobjquota" -> Some Userobjquota
  | "groupobjused" -> Some Groupobjused
  | "groupobjquota" -> Some Groupobjquota
  | "projectused" -> Some Projectused
  | "projectquota" -> Some Projectquota
  | "projectobjused" -> Some Projectobjused
  | "projectobjquota" -> Some Projectobjquota
  | _ -> None

let to_string = function
  | Userused -> "userused"
  | Userquota -> "userquota"
  | Groupused -> "groupused"
  | Groupquota -> "groupquota"
  | Userobjused -> "userobjused"
  | Userobjquota -> "userobjquota"
  | Groupobjused -> "groupobjused"
  | Groupobjquota -> "groupobjquota"
  | Projectused -> "projectused"
  | Projectquota -> "projectquota"
  | Projectobjused -> "projectobjused"
  | Projectobjquota -> "projectoboquota"

let decode_propname s zoned =
  let ( >>= ) = Option.bind in
  Option.join
  @@ Scanf.sscanf_opt s "%s@@%s" (fun propname ident ->
         of_string_opt propname >>= fun prop ->
         match prop with
         | Userused | Userquota | Userobjused | Userobjquota -> (
             try
               let pw = Unix.getpwnam ident in
               if zoned && Util.getzoneid () != 0 then None
               else Some (prop, pw.pw_uid)
             with Not_found ->
               Scanf.sscanf_opt ident "%d%!" (fun rid -> (prop, rid)))
         | Groupused | Groupquota | Groupobjused | Groupobjquota -> (
             try
               let gr = Unix.getgrnam ident in
               if zoned && Util.getzoneid () != 0 then None
               else Some (prop, gr.gr_gid)
             with Not_found ->
               Scanf.sscanf_opt ident "%d%!" (fun rid -> (prop, rid)))
         | Projectused | Projectquota | Projectobjused | Projectobjquota ->
             Scanf.sscanf_opt ident "%d%!" (fun rid -> (prop, rid)))

let encode_propname prop rid domain =
  Printf.sprintf "%s@%x-%s" (to_string prop) rid domain

let encode_propval prop rid intval =
  let intprop =
    match prop with
    | Userused -> 0L
    | Userquota -> 1L
    | Groupused -> 2L
    | Groupquota -> 3L
    | Userobjused -> 4L
    | Userobjquota -> 5L
    | Groupobjused -> 6L
    | Groupobjquota -> 7L
    | Projectused -> 8L
    | Projectquota -> 9L
    | Projectobjused -> 10L
    | Projectobjquota -> 11L
  in
  [| intprop; Int64.of_int rid; intval |]
