open Nvpair
open Zfs

(* let feature_enabled = "enabled" *)

let test_pool_name = "testpool"

(*
let test_dataset_name = Printf.sprintf "%s/testdataset" test_pool_name
let test_snapshot_name = Printf.sprintf "%s@testsnapshot" test_dataset_name
let test_bookmark_name = Printf.sprintf "%s#testbookmark" test_dataset_name
let test_property_name = "user:testproperty"
let test_property_value = "testvalue"
let test_mount_name = "testmnt"
let test_file_name = "testfile"
let test_tag_name = "testtag"
*)
let test_vdev_name = "testdev"
let test_vdev_size = Int.shift_left 128 20 (* 128 MiB *)

(*
let test_channel_program_instrlimit = 1024
let test_channel_program_memlimit = Int.shift_left 256 10 (* 256 KiB *)
let test_channel_program = "
  args = ...
  DS = args['DS']
  res = {}
  for fs in zfs.list.children(DS) do
      res[#res+1] = fs
  end
  zfs.debug('found ' .. tostring(#res) .. ' children')
  return res
"
*)

let vdev_file_create name =
  let home = Sys.getenv "HOME" in
  let path = Printf.sprintf "%s/%s" home name in
  let fd =
    Unix.openfile path [ Unix.O_WRONLY; Unix.O_CREAT; Unix.O_TRUNC ] 0o660
  in
  ignore @@ Unix.lseek fd (test_vdev_size - 1) Unix.SEEK_SET;
  ignore @@ Unix.write fd (Bytes.make 1 (Char.chr 0)) 0 1;
  Unix.close fd;
  path

let vdev_label_read path =
  let vdev_labels = 4 in
  let sizeof_vdev_label = 256 * 1024 in
  let label_offset size l =
    (l * sizeof_vdev_label)
    + if l < vdev_labels / 2 then 0 else size - (vdev_labels * sizeof_vdev_label)
  in
  let align x = Int.logand x (Int.neg sizeof_vdev_label) in
  let fd = Unix.openfile path [ Unix.O_RDONLY ] 0o660 in
  let stats = Unix.fstat fd in
  let size = align stats.st_size in
  let label = Bytes.create sizeof_vdev_label in
  let config =
    List.find_map
      (fun l ->
        try
          ignore @@ Unix.read fd label (label_offset size l) sizeof_vdev_label;
          let vdev_phys_start = 16 * 1024 in
          let vdev_phys_size = 112 * 1024 in
          let vdev_phys = Bytes.sub label vdev_phys_start vdev_phys_size in
          let nvlist_start = 0 in
          let nvlist_size = vdev_phys_size - (5 * 8) in
          let packed_config = Bytes.sub vdev_phys nvlist_start nvlist_size in
          let config = Nvlist.unpack packed_config in
          Option.bind (Nvlist.lookup_uint64 config "state") @@ fun state ->
          if state > 2L then None
          else
            Option.bind (Nvlist.lookup_uint64 config "txg") @@ fun _txg ->
            Some config
        with _ -> None)
      [ 0; 1; 2; 3 ]
  in
  Unix.close fd;
  config

let common_pack_root_vdevs vdevs =
  let root = Nvlist.alloc () in
  Nvlist.add_string root "type" "root";
  let disks =
    Array.of_list
    @@ List.map
         (fun path ->
           let disk = Nvlist.alloc () in
           Nvlist.add_string disk "path" path;
           Nvlist.add_string disk "type" "file";
           Nvlist.add_uint64 disk "is_log" 0L;
           disk)
         vdevs
  in
  Nvlist.add_nvlist_array root "children" disks;
  Nvlist.pack root Nvlist.Native

let common_pack_all_features () =
  let props = Nvlist.alloc () in
  Nvlist.add_uint64 props "feature@async_destroy" 0L;
  Nvlist.add_uint64 props "feature@empty_bpobj" 0L;
  Nvlist.add_uint64 props "feature@lz4_compress" 0L;
  Nvlist.add_uint64 props "feature@multi_vdev_crash_dump" 0L;
  Nvlist.add_uint64 props "feature@spacemap_histogram" 0L;
  Nvlist.add_uint64 props "feature@enabled_txg" 0L;
  Nvlist.add_uint64 props "feature@hole_birth" 0L;
  Nvlist.add_uint64 props "feature@zpool_checkpoint" 0L;
  Nvlist.add_uint64 props "feature@spacemap_v2" 0L;
  Nvlist.add_uint64 props "feature@extensible_dataset" 0L;
  Nvlist.add_uint64 props "feature@bookmarks" 0L;
  Nvlist.add_uint64 props "feature@filesystem_limits" 0L;
  Nvlist.add_uint64 props "feature@embedded_data" 0L;
  Nvlist.add_uint64 props "feature@livelist" 0L;
  Nvlist.add_uint64 props "feature@log_spacemap" 0L;
  Nvlist.add_uint64 props "feature@large_blocks" 0L;
  Nvlist.add_uint64 props "feature@large_dnode" 0L;
  Nvlist.add_uint64 props "feature@sha512" 0L;
  Nvlist.add_uint64 props "feature@skein" 0L;
  Nvlist.add_uint64 props "feature@edonr" 0L;
  Nvlist.add_uint64 props "feature@redaction_bookmarks" 0L;
  Nvlist.add_uint64 props "feature@redacted_datasets" 0L;
  Nvlist.add_uint64 props "feature@bookmark_written" 0L;
  Nvlist.add_uint64 props "feature@device_removal" 0L;
  Nvlist.add_uint64 props "feature@obsolete_counts" 0L;
  Nvlist.add_uint64 props "feature@userobj_accounting" 0L;
  Nvlist.add_uint64 props "feature@bookmark_v2" 0L;
  Nvlist.add_uint64 props "feature@encryption" 0L;
  Nvlist.add_uint64 props "feature@project_quota" 0L;
  Nvlist.add_uint64 props "feature@allocation_classes" 0L;
  Nvlist.add_uint64 props "feature@resilver_defer" 0L;
  Nvlist.add_uint64 props "feature@device_rebuild" 0L;
  Nvlist.add_uint64 props "feature@zstd_compress" 0L;
  Nvlist.add_uint64 props "feature@draid" 0L;
  Nvlist.add_uint64 props "feature@zilsaxattr" 0L;
  Nvlist.add_uint64 props "feature@head_errlog" 0L;
  Nvlist.add_uint64 props "feature@blake3" 0L;
  Nvlist.add_uint64 props "feature@block_cloning" 0L;
  Nvlist.add_uint64 props "feature@vdev_zaps_v2" 0L;
  Nvlist.add_uint64 props "feature@redaction_list_spill" 0L;
  Nvlist.add_uint64 props "feature@raidz_expansion" 0L;
  Nvlist.pack props Nvlist.Native

let common_zpool_create vdevs =
  let handle = Zfs_ioctls.open_handle () in
  let config = common_pack_root_vdevs vdevs in
  let props = common_pack_all_features () in
  match Zfs_ioctls.pool_create handle test_pool_name config (Some props) with
  | Left () -> ()
  | Right e ->
      Printf.eprintf "pool_create failed\n";
      failwith @@ Unix.error_message e

let common_zpool_destroy () =
  let handle = Zfs_ioctls.open_handle () in
  match Zfs_ioctls.pool_destroy handle test_pool_name "deleting test pool" with
  | Left () -> ()
  | Right e ->
      Printf.eprintf "pool_destroy failed\n";
      failwith @@ Unix.error_message e

let common_setup () =
  let vdevs = [ vdev_file_create test_vdev_name ] in
  common_zpool_create vdevs;
  vdevs

let common_cleanup_vdevs vdevs = List.iter Unix.unlink vdevs

let common_cleanup vdevs =
  common_zpool_destroy ();
  common_cleanup_vdevs vdevs

let common_get_config vdevs =
  let label = Option.get @@ vdev_label_read (List.hd vdevs) in
  let conf = Nvlist.alloc () in
  let children = Option.get @@ Nvlist.lookup_uint64 label "vdev_children" in
  Nvlist.add_uint64 conf "vdev_children" children;
  let version = Option.get @@ Nvlist.lookup_uint64 label "version" in
  Nvlist.add_uint64 conf "version" version;
  let guid = Option.get @@ Nvlist.lookup_uint64 label "pool_guid" in
  Nvlist.add_uint64 conf "pool_guid" guid;
  let name = Option.get @@ Nvlist.lookup_string label "name" in
  Nvlist.add_string conf "name" name;
  (match Nvlist.lookup_string label "comment" with
  | Some comment -> Nvlist.add_string conf "comment" comment
  | None -> ());
  let state = Option.get @@ Nvlist.lookup_uint64 label "state" in
  Nvlist.add_uint64 conf "state" state;
  (match Nvlist.lookup_uint64 label "hostid" with
  | Some hostid ->
      Nvlist.add_uint64 conf "hostid" hostid;
      let hostname = Option.get @@ Nvlist.lookup_string label "hostname" in
      Nvlist.add_string conf "hostname" hostname
  | None -> ());
  let root = Nvlist.alloc () in
  Nvlist.add_string root "type" "root";
  Nvlist.add_uint64 root "id" 0L;
  Nvlist.add_uint64 root "guid" guid;
  let top = Option.get @@ Nvlist.lookup_nvlist label "vdev_tree" in
  Nvlist.add_nvlist_array root "children" [| top |];
  let id = Option.get @@ Nvlist.lookup_uint64 top "id" in
  Nvlist.add_uint64 conf "id" id;
  Nvlist.add_nvlist conf "vdev_tree" root;
  let policy = Nvlist.alloc () in
  Nvlist.add_uint64 policy "load-request-txg" (-1L);
  Nvlist.add_uint32 policy "load-rewind-policy" 1l;
  Nvlist.add_nvlist conf "load-policy" policy;
  let packed_conf = Nvlist.pack conf Nvlist.Native in
  let handle = Zfs_ioctls.open_handle () in
  match Zfs_ioctls.pool_tryimport handle packed_conf with
  | Left packed_config -> packed_config
  | Right e ->
      Printf.eprintf "pool_tryimport failed\n";
      failwith @@ Unix.error_message e

(* pool_create *)
(* pool_destroy *)
let () =
  let vdevs = common_setup () in
  common_cleanup vdevs

(* pool_set_props *)
let () =
  let vdevs = common_setup () in
  let handle = Zfs_ioctls.open_handle () in
  let props = Nvlist.alloc () in
  Nvlist.add_string props "bootfs" test_pool_name;
  let packed = Nvlist.pack props Nvlist.Native in
  (match Zfs_ioctls.pool_set_props handle test_pool_name packed with
  | Left () -> ()
  | Right e ->
      Printf.eprintf "pool_set_props failed\n";
      failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* pool_get_props *)
let () =
  let vdevs = common_setup () in
  let handle = Zfs_ioctls.open_handle () in
  (match Zfs_ioctls.pool_get_props handle test_pool_name with
  | Left packed_props ->
      let props = Nvlist.unpack packed_props in
      ignore props
  | Right e ->
      Printf.eprintf "pool_get_props failed\n";
      failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* pool_export *)
let () =
  let vdevs = common_setup () in
  let handle = Zfs_ioctls.open_handle () in
  (match
     Zfs_ioctls.pool_export handle test_pool_name false false
       "exporting test pool"
   with
  | Left () -> ()
  | Right e ->
      Printf.eprintf "pool_export failed\n";
      failwith @@ Unix.error_message e);
  common_cleanup_vdevs vdevs

(* pool_tryimport *)
let () =
  let vdevs = common_setup () in
  let handle = Zfs_ioctls.open_handle () in
  (match
     Zfs_ioctls.pool_export handle test_pool_name false false
       "exporting test pool"
   with
  | Left () -> ()
  | Right e ->
      Printf.eprintf "pool_export failed (pool_tryimport)\n";
      failwith @@ Unix.error_message e);
  let packed_config = common_get_config vdevs in
  let config = Nvlist.unpack packed_config in
  let name = Option.get @@ Nvlist.lookup_string config "name" in
  Printf.printf "got config for pool: %s\n" name;
  common_cleanup_vdevs vdevs

(* pool_import *)
let () =
  let vdevs = common_setup () in
  let handle = Zfs_ioctls.open_handle () in
  (match
     Zfs_ioctls.pool_export handle test_pool_name false false
       "exporting test pool"
   with
  | Left () -> ()
  | Right e ->
      Printf.eprintf "pool_export failed (pool_import)\n";
      failwith @@ Unix.error_message e);
  let packed_config = common_get_config vdevs in
  let config = Nvlist.unpack packed_config in
  let guid = Option.get @@ Nvlist.lookup_uint64 config "pool_guid" in
  Printf.printf "pool guid: %Lu\n" guid;
  (match
     Zfs_ioctls.pool_import handle test_pool_name guid packed_config None
       [| ImportOnly |]
   with
  | Left packed_conf ->
      let conf = Nvlist.unpack packed_conf in
      let name = Option.get @@ Nvlist.lookup_string conf "name" in
      Printf.printf "imported pool: %s\n" name
  | Right e ->
      Printf.eprintf "pool_import failed\n";
      failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* pool_configs *)
let () =
  let vdevs = common_setup () in
  let handle = Zfs_ioctls.open_handle () in
  (match Zfs_ioctls.pool_configs handle 0L with
  | Left None -> ()
  | Left (Some (ns_gen, packed_configs)) ->
      Printf.printf "got configs for namespace generation: %Lu\n" ns_gen;
      let configs = Nvlist.unpack packed_configs in
      let rec iter_pools pair =
        match Nvlist.next_nvpair configs pair with
        | None -> ()
        | Some p ->
            let name = Nvpair.name p in
            Printf.printf "\t%s\n" name;
            iter_pools @@ Some p
      in
      iter_pools None
  | Right e ->
      Printf.eprintf "pool_configs failed\n";
      failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* pool_stats *)
let () =
  let vdevs = common_setup () in
  let handle = Zfs_ioctls.open_handle () in
  (match Zfs_ioctls.pool_stats handle test_pool_name with
  | Left packed_config ->
      let config = Nvlist.unpack packed_config in
      ignore config
  | Right (Some packed_config, e) ->
      Printf.eprintf "failed pool_stats with config";
      let config = Nvlist.unpack packed_config in
      ignore config;
      failwith @@ Unix.error_message e
  | Right (None, e) -> failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* pool_scan *)
let () =
  let vdevs = common_setup () in
  let handle = Zfs_ioctls.open_handle () in
  (match Zfs_ioctls.pool_scan handle test_pool_name ScanScrub ScrubNormal with
  | Left () -> ()
  | Right e ->
      Printf.eprintf "pool_scan failed\n";
      failwith @@ Unix.error_message e);
  (match Zfs_ioctls.pool_scan handle test_pool_name ScanNone ScrubNormal with
  | Left () -> ()
  | Right e ->
      Printf.eprintf "pool_scan failed (ScanNone)\n";
      failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* pool_freeze *)
let () =
  let vdevs = common_setup () in
  let handle = Zfs_ioctls.open_handle () in
  (match Zfs_ioctls.pool_freeze handle test_pool_name with
  | Left () -> ()
  | Right e ->
      Printf.eprintf "pool_freeze failed\n";
      failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* pool_upgrade *)
let () =
  let vdevs = common_setup () in
  let handle = Zfs_ioctls.open_handle () in
  (match Zfs_ioctls.pool_upgrade handle test_pool_name 5000L with
  | Left () -> ()
  | Right e ->
      Printf.eprintf "pool_upgrade failed\n";
      failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* pool_get_history *)
let () =
  let vdevs = common_setup () in
  let handle = Zfs_ioctls.open_handle () in
  let rec history_loop offset =
    match Zfs_ioctls.pool_get_history handle test_pool_name offset with
    | Left None -> ()
    | Left (Some historybuf) ->
        let historybuf_len = Bytes.length historybuf in
        let rec entries_at size_offset =
          let size_len = 8 in
          if size_offset + size_len > historybuf_len then size_offset
          else
            let entry_offset = size_offset + size_len in
            let entry_len =
              Int64.to_int @@ Bytes.get_int64_le historybuf size_offset
            in
            let entry_end = entry_offset + entry_len in
            if entry_end > historybuf_len then size_offset
            else
              let packed_entry = Bytes.sub historybuf entry_offset entry_len in
              let entry = Nvlist.unpack packed_entry in
              let rec entry_loop pair =
                match Nvlist.next_nvpair entry pair with
                | None -> ()
                | Some p ->
                    Printf.printf "\t%s\n" @@ Nvpair.name p;
                    entry_loop @@ Some p
              in
              Printf.printf "history entry at offset %u:\n" entry_offset;
              entry_loop None;
              entries_at entry_end
        in
        let entries_end = Int64.of_int @@ entries_at 0 in
        let next_offset = Int64.add offset entries_end in
        history_loop next_offset
    | Right e ->
        Printf.eprintf "pool_get_history failed at offset %Lu\n" offset;
        failwith @@ Unix.error_message e
  in
  history_loop 0L;
  common_cleanup vdevs

(* pool_reguid *)
let () =
  let vdevs = common_setup () in
  let handle = Zfs_ioctls.open_handle () in
  (match Zfs_ioctls.pool_reguid handle test_pool_name with
  | Left () -> ()
  | Right e ->
      Printf.eprintf "pool_reguid failed\n";
      failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* pool_reopen *)
let () =
  let vdevs = common_setup () in
  let handle = Zfs_ioctls.open_handle () in
  (match Zfs_ioctls.pool_reopen handle test_pool_name None with
  | Left () -> ()
  | Right e ->
      Printf.eprintf "pool_reopen failed\n";
      failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* pool_checkpoint *)
let () =
  let vdevs = common_setup () in
  let handle = Zfs_ioctls.open_handle () in
  (match Zfs_ioctls.pool_checkpoint handle test_pool_name with
  | Left () -> ()
  | Right e ->
      Printf.eprintf "pool_checkpoint failed\n";
      failwith @@ Unix.error_message e);
  common_cleanup vdevs
