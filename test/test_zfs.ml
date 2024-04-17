open Nvpair
open Zfs

let handle = Zfs_ioctls.open_handle ()

let () =
  match Zfs_ioctls.pool_configs handle 0L with
  | Either.Left None -> ()
  | Either.Left Some (new_gen, packed) ->
      Printf.printf "gen: %Lu\n" new_gen;
      let pools = Nvlist.unpack packed in
      let rec iter_pools pair =
        match Nvlist.next_nvpair pools pair with
        | None -> ()
        | Some p ->
            let name = Nvpair.name p in
            Printf.printf "pool name: %s\n" name;
            iter_pools @@ Some p
      in
      iter_pools None
  | Either.Right e ->
      Printf.printf "error: %s\n" @@ Unix.error_message e
