open Zfs

let () =
  assert (
    Some (Userquota_prop.Userquota, 0)
    = Userquota_prop.decode_propname "userquota@root" false)
