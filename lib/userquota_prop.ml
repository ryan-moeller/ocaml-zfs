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
