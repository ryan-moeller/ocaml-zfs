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

let decode_propname s zoned =
  let ( >>= ) = Option.bind in
  Option.join
  @@ Scanf.sscanf_opt s "%s@@%s" (fun propname ident ->
         of_string_opt propname >>= fun prop ->
         match prop with
         | Userused | Userquota | Userobjused | Userobjquota -> (
             match Util.getpwnam ident with
             | Ok (Some pw) ->
                 if zoned && Util.getzoneid () != 0 then None
                 else Some (prop, pw.uid)
             | Ok None -> Scanf.sscanf_opt ident "%d%!" (fun rid -> (prop, rid))
             | Error e -> raise (Unix.Unix_error (e, "getpwnam", ident)))
         | Groupused | Groupquota | Groupobjused | Groupobjquota -> (
             match Util.getgrnam ident with
             | Ok (Some gr) ->
                 if zoned && Util.getzoneid () != 0 then None
                 else Some (prop, gr.gid)
             | Ok None -> Scanf.sscanf_opt ident "%d%!" (fun rid -> (prop, rid))
             | Error e -> raise (Unix.Unix_error (e, "getgrnam", ident)))
         | Projectused | Projectquota | Projectobjused | Projectobjquota ->
             Scanf.sscanf_opt ident "%d%!" (fun rid -> (prop, rid)))
