open Nvpair
open Lib
open Lib.Types

let () =
  if Unix.getuid () != 0 then (
    Printf.eprintf "must be root to run these tests\n";
    exit 1)

let test_pool_name = "testpool"
let test_dataset_name = Printf.sprintf "%s/testdataset" test_pool_name
let test_snapshot_name = Printf.sprintf "%s@testsnapshot" test_dataset_name
let test_bookmark_name = Printf.sprintf "%s#testbookmark" test_dataset_name
let test_mount_name = "testmnt"
let test_file_name = "testfile"
let test_property_name = "user:testproperty"
let test_property_value = "testvalue"
let test_tag_name = "testtag"
let test_vdev_name = "testdev"
let test_vdev_size = Int.shift_left 128 20 (* 128 MiB *)
let test_channel_program_instrlimit = 1024L
let test_channel_program_memlimit = Int64.shift_left 256L 10 (* 256 KiB *)

let test_channel_program =
  "args = ...\n\
   DS = args['DS']\n\
   res = {}\n\
   for fs in zfs.list.children(DS) do\n\
  \  res[#res+1] = fs\n\
   end\n\
   zfs.debug('found ' .. tostring(#res) .. ' children')\n\
   return res\n"

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
  Array.iter
    (fun feature ->
      let attrs = Zfeature.attributes feature in
      let name = Printf.sprintf "feature@%s" attrs.name in
      Nvlist.add_uint64 props name 0L)
    Zfeature.all_features;
  Nvlist.pack props Nvlist.Native

let common_zpool_create vdevs =
  let handle = Ioctls.open_handle () in
  let config = common_pack_root_vdevs vdevs in
  let props = common_pack_all_features () in
  match Ioctls.pool_create handle test_pool_name config (Some props) with
  | Ok () -> ()
  | Error e ->
      Printf.eprintf "pool_create failed\n";
      failwith @@ Unix.error_message e

let common_zpool_destroy () =
  let handle = Ioctls.open_handle () in
  match Ioctls.pool_destroy handle test_pool_name "deleting test pool" with
  | Ok () -> ()
  | Error e ->
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
  let label = Option.get @@ vdev_label_read @@ List.hd vdevs in
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
  let handle = Ioctls.open_handle () in
  match Ioctls.pool_tryimport handle packed_conf with
  | Ok packed_config -> packed_config
  | Error e ->
      Printf.eprintf "pool_tryimport failed\n";
      failwith @@ Unix.error_message e

let common_vdev_attach vdevs name =
  let label = Option.get @@ vdev_label_read @@ List.hd vdevs in
  let vdev = Option.get @@ Nvlist.lookup_nvlist label "vdev_tree" in
  let guid = Option.get @@ Nvlist.lookup_uint64 vdev "guid" in
  let path = vdev_file_create name in
  let packed_config = common_pack_root_vdevs [ path ] in
  let handle = Ioctls.open_handle () in
  (match
     Ioctls.vdev_attach handle test_pool_name guid packed_config false false
   with
  | Ok () -> ()
  | Error e ->
      Printf.eprintf "vdev_attach failed\n";
      failwith @@ Unix.error_message e);
  List.cons path vdevs

let common_dataset_create name =
  let args = Nvlist.alloc () in
  Nvlist.add_int32 args "type" 2l (* ObjsetTypeZfs *);
  let packed_args = Nvlist.pack args Nvlist.Native in
  let handle = Ioctls.open_handle () in
  match Ioctls.create handle name packed_args with
  | Ok () -> ()
  | Error e ->
      Printf.eprintf "create failed\n";
      failwith @@ Unix.error_message e

let common_snapshot_create name =
  let pool = List.hd @@ Str.bounded_split (Str.regexp "[/@]") name 2 in
  let args = Nvlist.alloc () in
  let snaps = Nvlist.alloc () in
  Nvlist.add_boolean snaps name;
  Nvlist.add_nvlist args "snaps" snaps;
  let packed_args = Nvlist.pack args Nvlist.Native in
  let handle = Ioctls.open_handle () in
  match Ioctls.snapshot handle pool packed_args with
  | Ok () -> ()
  | Error (Some packed_errors, e) ->
      ignore @@ Nvlist.unpack packed_errors;
      Printf.eprintf "snapshot failed with errors\n";
      failwith @@ Unix.error_message e
  | Error (None, e) ->
      Printf.eprintf "snapshot failed\n";
      failwith @@ Unix.error_message e

let common_clone_create origin name =
  let args = Nvlist.alloc () in
  Nvlist.add_string args "origin" origin;
  let packed_args = Nvlist.pack args Nvlist.Native in
  let handle = Ioctls.open_handle () in
  match Ioctls.clone handle name packed_args with
  | Ok () -> ()
  | Error (Some packed_errors, e) ->
      let _errors = Nvlist.unpack packed_errors in
      Printf.eprintf "clone failed (with errors)\n";
      failwith @@ Unix.error_message e
  | Error (None, e) ->
      Printf.eprintf "clone failed (without errors)\n";
      failwith @@ Unix.error_message e

let common_bookmark_create pool snap name =
  let args = Nvlist.alloc () in
  Nvlist.add_string args name snap;
  let packed_args = Nvlist.pack args Nvlist.Native in
  let handle = Ioctls.open_handle () in
  match Ioctls.bookmark handle pool packed_args with
  | Ok () -> ()
  | Error (Some packed_errors, e) ->
      let _errors = Nvlist.unpack packed_errors in
      Printf.eprintf "bookmark failed (with errors)\n";
      failwith @@ Unix.error_message e
  | Error (None, e) ->
      Printf.eprintf "bookmark failed (without errors)\n";
      failwith @@ Unix.error_message e

let common_hold_create snap tag =
  let args = Nvlist.alloc () in
  let holds = Nvlist.alloc () in
  Nvlist.add_string holds snap tag;
  Nvlist.add_nvlist args "holds" holds;
  let packed_args = Nvlist.pack args Nvlist.Native in
  let handle = Ioctls.open_handle () in
  match Ioctls.hold handle test_pool_name packed_args with
  | Ok () -> ()
  | Error (Some packed_errors, e) ->
      let _errors = Nvlist.unpack packed_errors in
      Printf.eprintf "hold failed (with errors)\n";
      failwith @@ Unix.error_message e
  | Error (None, e) ->
      Printf.eprintf "hold failed (without errors)\n";
      failwith @@ Unix.error_message e

let common_stats_get name =
  let handle = Ioctls.open_handle () in
  match Ioctls.objset_stats handle name false with
  | Ok (_stats, Some packed_stats) -> Nvlist.unpack packed_stats
  | Ok (_stats, None) -> failwith "objset_stats didn't return nvlist"
  | Error e ->
      Printf.eprintf "objset_stats failed\n";
      failwith @@ Unix.error_message e

let common_objset_id_lookup name =
  let stats = common_stats_get name in
  let prop = Option.get @@ Nvlist.lookup_nvlist stats "objsetid" in
  Option.get @@ Nvlist.lookup_uint64 prop "value"

let common_inject_fault vdevs =
  let label = Option.get @@ vdev_label_read @@ List.hd vdevs in
  let guid = Option.get @@ Nvlist.lookup_uint64 label "guid" in
  let record =
    {
      objset = 0L;
      obj = 0L;
      range_start = 0L;
      range_end = 0L;
      guid;
      level = 0l;
      error = 6l (* ENXIO *);
      inject_type = 0L;
      freq = 0l;
      failfast = 0l;
      func = "";
      iotype = 7l (* ZIO_TYPES *);
      duration = 0l;
      timer = 10L;
      nlanes = 2L;
      cmd = 6l (* ZINJECT_DELAY_IO *);
      dvas = 0l;
    }
  in
  let handle = Ioctls.open_handle () in
  match Ioctls.inject_fault handle test_pool_name record 0 with
  | Ok fault_id -> fault_id
  | Error e ->
      Printf.eprintf "inject_fault failed\n";
      failwith @@ Unix.error_message e

let common_clear_fault fault_id =
  let handle = Ioctls.open_handle () in
  match Ioctls.clear_fault handle fault_id with
  | Ok () -> ()
  | Error e ->
      Printf.eprintf "clear_fault failed\n";
      failwith @@ Unix.error_message e

(* pool_create *)
(* pool_destroy *)
let () =
  let vdevs = common_setup () in
  common_cleanup vdevs

(* pool_set_props *)
let () =
  let vdevs = common_setup () in
  let handle = Ioctls.open_handle () in
  let props = Nvlist.alloc () in
  Nvlist.add_string props "bootfs" test_pool_name;
  let packed = Nvlist.pack props Nvlist.Native in
  (match Ioctls.pool_set_props handle test_pool_name packed with
  | Ok () -> ()
  | Error e ->
      Printf.eprintf "pool_set_props failed\n";
      failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* pool_get_props *)
let () =
  let vdevs = common_setup () in
  let handle = Ioctls.open_handle () in
  (match Ioctls.pool_get_props handle test_pool_name with
  | Ok packed_props ->
      let props = Nvlist.unpack packed_props in
      ignore props
  | Error e ->
      Printf.eprintf "pool_get_props failed\n";
      failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* pool_export *)
let () =
  let vdevs = common_setup () in
  let handle = Ioctls.open_handle () in
  (match
     Ioctls.pool_export handle test_pool_name false false
       (Some "exporting test pool")
   with
  | Ok () -> ()
  | Error e ->
      Printf.eprintf "pool_export failed\n";
      failwith @@ Unix.error_message e);
  common_cleanup_vdevs vdevs

(* pool_tryimport *)
let () =
  let vdevs = common_setup () in
  let handle = Ioctls.open_handle () in
  (match
     Ioctls.pool_export handle test_pool_name false false
       (Some "exporting test pool")
   with
  | Ok () -> ()
  | Error e ->
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
  let handle = Ioctls.open_handle () in
  (match
     Ioctls.pool_export handle test_pool_name false false
       (Some "exporting test pool")
   with
  | Ok () -> ()
  | Error e ->
      Printf.eprintf "pool_export failed (pool_import)\n";
      failwith @@ Unix.error_message e);
  let packed_config = common_get_config vdevs in
  let config = Nvlist.unpack packed_config in
  let guid = Option.get @@ Nvlist.lookup_uint64 config "pool_guid" in
  Printf.printf "pool guid: %Lu\n" guid;
  (match
     Ioctls.pool_import handle test_pool_name guid packed_config None
       [| ImportOnly |]
   with
  | Ok packed_conf ->
      let conf = Nvlist.unpack packed_conf in
      let name = Option.get @@ Nvlist.lookup_string conf "name" in
      Printf.printf "imported pool: %s\n" name
  | Error (packed_conf, e) ->
      let _conf = Nvlist.unpack packed_conf in
      Printf.eprintf "pool_import failed\n";
      failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* pool_configs *)
let () =
  let vdevs = common_setup () in
  let handle = Ioctls.open_handle () in
  (match Ioctls.pool_configs handle 0L with
  | Ok None -> ()
  | Ok (Some (ns_gen, packed_configs)) ->
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
  | Error e ->
      Printf.eprintf "pool_configs failed\n";
      failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* pool_stats *)
let () =
  let vdevs = common_setup () in
  let handle = Ioctls.open_handle () in
  (match Ioctls.pool_stats handle test_pool_name with
  | Ok packed_config ->
      let config = Nvlist.unpack packed_config in
      ignore config
  | Error (Some packed_config, e) ->
      Printf.eprintf "failed pool_stats with config";
      let config = Nvlist.unpack packed_config in
      ignore config;
      failwith @@ Unix.error_message e
  | Error (None, e) -> failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* pool_scan *)
let () =
  let vdevs = common_setup () in
  let handle = Ioctls.open_handle () in
  (match Ioctls.pool_scan handle test_pool_name ScanScrub ScrubNormal with
  | Ok () -> ()
  | Error e ->
      Printf.eprintf "pool_scan failed\n";
      failwith @@ Unix.error_message e);
  (match Ioctls.pool_scan handle test_pool_name ScanNone ScrubNormal with
  | Ok () -> ()
  | Error e ->
      Printf.eprintf "pool_scan failed (ScanNone)\n";
      failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* pool_freeze *)
let () =
  let vdevs = common_setup () in
  let handle = Ioctls.open_handle () in
  (match Ioctls.pool_freeze handle test_pool_name with
  | Ok () -> ()
  | Error e ->
      Printf.eprintf "pool_freeze failed\n";
      failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* pool_upgrade *)
let () =
  let vdevs = common_setup () in
  let handle = Ioctls.open_handle () in
  (match Ioctls.pool_upgrade handle test_pool_name 5000L with
  | Ok () -> ()
  | Error e ->
      Printf.eprintf "pool_upgrade failed\n";
      failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* pool_get_history *)
let () =
  let vdevs = common_setup () in
  let handle = Ioctls.open_handle () in
  let rec history_loop offset =
    match Ioctls.pool_get_history handle test_pool_name offset with
    | Ok None -> ()
    | Ok (Some historybuf) ->
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
    | Error e ->
        Printf.eprintf "pool_get_history failed at offset %Lu\n" offset;
        failwith @@ Unix.error_message e
  in
  history_loop 0L;
  common_cleanup vdevs

(* pool_reguid *)
let () =
  let vdevs = common_setup () in
  let handle = Ioctls.open_handle () in
  (match Ioctls.pool_reguid handle test_pool_name with
  | Ok () -> ()
  | Error e ->
      Printf.eprintf "pool_reguid failed\n";
      failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* pool_reopen *)
let () =
  let vdevs = common_setup () in
  let handle = Ioctls.open_handle () in
  (match Ioctls.pool_reopen handle test_pool_name None with
  | Ok () -> ()
  | Error e ->
      Printf.eprintf "pool_reopen failed\n";
      failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* pool_checkpoint *)
let () =
  let vdevs = common_setup () in
  let handle = Ioctls.open_handle () in
  (match Ioctls.pool_checkpoint handle test_pool_name with
  | Ok () -> ()
  | Error e ->
      Printf.eprintf "pool_checkpoint failed\n";
      failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* pool_discard_checkpoint *)
let () =
  let vdevs = common_setup () in
  let handle = Ioctls.open_handle () in
  (match Ioctls.pool_checkpoint handle test_pool_name with
  | Ok () -> ()
  | Error e ->
      Printf.eprintf "pool_checkpoint failed (pool_discard_checkpoint)\n";
      failwith @@ Unix.error_message e);
  (match Ioctls.pool_discard_checkpoint handle test_pool_name with
  | Ok () -> ()
  | Error e ->
      Printf.eprintf "pool_discard_checkpoint failed\n";
      failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* pool_initialize *)
let () =
  let vdevs = common_setup () in
  let guids = Nvlist.alloc () in
  List.iter
    (fun path ->
      let label = Option.get @@ vdev_label_read path in
      let guid = Option.get @@ Nvlist.lookup_uint64 label "guid" in
      Nvlist.add_uint64 guids path guid)
    vdevs;
  let args = Nvlist.alloc () in
  Nvlist.add_uint64 args "initialize_command" 0L (* POOL_INITIALIZE_START *);
  Nvlist.add_nvlist args "initialize_vdevs" guids;
  let packed_args = Nvlist.pack args Nvlist.Native in
  let handle = Ioctls.open_handle () in
  (match Ioctls.pool_initialize handle test_pool_name packed_args with
  | Ok () -> ()
  | Error (Some packed_errors, e) ->
      let errors = Nvlist.unpack packed_errors in
      ignore errors;
      Printf.eprintf "pool_initialize failed with errors\n";
      failwith @@ Unix.error_message e
  | Error (None, e) ->
      Printf.eprintf "pool_initialize failed without errors\n";
      failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* pool_scrub *)
let () =
  let vdevs = common_setup () in
  let args = Nvlist.alloc () in
  Nvlist.add_uint64 args "scan_type"
  @@ Int64.of_int
  @@ Util.int_of_pool_scan_func ScanScrub;
  Nvlist.add_uint64 args "scan_command"
  @@ Int64.of_int
  @@ Util.int_of_pool_scrub_cmd ScrubNormal;
  let packed_args = Nvlist.pack args Nvlist.Native in
  let handle = Ioctls.open_handle () in
  (match Ioctls.pool_scrub handle test_pool_name packed_args with
  | Ok () -> ()
  | Error e ->
      Printf.eprintf "pool_scrub failed\n";
      failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* pool_sync *)
let () =
  let vdevs = common_setup () in
  let args = Nvlist.alloc () in
  Nvlist.add_boolean_value args "force" false;
  let packed_args = Nvlist.pack args Nvlist.Native in
  let handle = Ioctls.open_handle () in
  (match Ioctls.pool_sync handle test_pool_name packed_args with
  | Ok () -> ()
  | Error e ->
      Printf.eprintf "pool_sync failed\n";
      failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* pool_trim *)
let () =
  let vdevs = common_setup () in
  let args = Nvlist.alloc () in
  Nvlist.add_uint64 args "trim_command" 0L (* POOL_TRIM_START *);
  let vdev = List.hd vdevs in
  let label = Option.get @@ vdev_label_read vdev in
  let guid = Option.get @@ Nvlist.lookup_uint64 label "guid" in
  let trim_vdevs = Nvlist.alloc () in
  Nvlist.add_uint64 trim_vdevs vdev guid;
  Nvlist.add_nvlist args "trim_vdevs" trim_vdevs;
  let packed_args = Nvlist.pack args Nvlist.Native in
  let handle = Ioctls.open_handle () in
  (match Ioctls.pool_trim handle test_pool_name packed_args with
  | Ok () -> ()
  | Error (Some packed_errors, e) ->
      let _errors = Nvlist.unpack packed_errors in
      Printf.eprintf "pool_trim failed (with errors)\n";
      failwith @@ Unix.error_message e
  | Error (None, e) ->
      Printf.eprintf "pool_trim failed (without errors)\n";
      failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* vdev_add *)
let () =
  let vdevs = common_setup () in
  let vdev = vdev_file_create @@ Printf.sprintf "%s0" test_vdev_name in
  let packed_conf = common_pack_root_vdevs [ vdev ] in
  let handle = Ioctls.open_handle () in
  (match Ioctls.vdev_add handle test_pool_name packed_conf false with
  | Ok () -> ()
  | Error e ->
      Printf.eprintf "vdev_add failed\n";
      failwith @@ Unix.error_message e);
  common_cleanup @@ List.cons vdev vdevs

(* vdev_remove *)
let () =
  let vdevs =
    List.init 4 (fun i ->
        vdev_file_create @@ Printf.sprintf "%s%d" test_vdev_name i)
  in
  common_zpool_create vdevs;
  let label = Option.get @@ vdev_label_read @@ List.hd vdevs in
  let vdev = Option.get @@ Nvlist.lookup_nvlist label "vdev_tree" in
  let guid = Option.get @@ Nvlist.lookup_uint64 vdev "guid" in
  let handle = Ioctls.open_handle () in
  (match Ioctls.vdev_remove handle test_pool_name guid with
  | Ok () -> ()
  | Error e ->
      Printf.eprintf "vdev_remove failed\n";
      failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* vdev_remove_cancel *)
let () =
  let vdevs =
    List.init 4 (fun i ->
        vdev_file_create @@ Printf.sprintf "%s%d" test_vdev_name i)
  in
  common_zpool_create vdevs;
  let label = Option.get @@ vdev_label_read @@ List.hd vdevs in
  let vdev = Option.get @@ Nvlist.lookup_nvlist label "vdev_tree" in
  let guid = Option.get @@ Nvlist.lookup_uint64 vdev "guid" in
  let handle = Ioctls.open_handle () in
  (match Ioctls.vdev_remove handle test_pool_name guid with
  | Ok () -> ()
  | Error e ->
      Printf.eprintf "vdev_remove failed (vdev_remove_cancel)\n";
      failwith @@ Unix.error_message e);
  (match Ioctls.vdev_remove_cancel handle test_pool_name with
  | Ok () -> ()
  | Error e ->
      Printf.eprintf "vdev_remove_cancel failed\n";
      failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* vdev_set_state *)
let () =
  let vdevs = common_setup () in
  let label = Option.get @@ vdev_label_read @@ List.hd vdevs in
  let vdev = Option.get @@ Nvlist.lookup_nvlist label "vdev_tree" in
  let guid = Option.get @@ Nvlist.lookup_uint64 vdev "guid" in
  let flags =
    11L
    (* VDEV_AUX_ERR_EXCEEDED (flags not always vdev_aux_t) *)
  in
  let handle = Ioctls.open_handle () in
  (match
     Ioctls.vdev_set_state handle test_pool_name guid VdevStateFaulted flags
   with
  (* returns VdevStateUnknown except when assigning VdevStateOnline *)
  | Ok VdevStateUnknown -> ()
  | Ok state ->
      Printf.eprintf "vdev_set_state returned unexpected state: ";
      let name =
        match state with
        | VdevStateUnknown -> "unknown"
        | VdevStateClosed -> "closed"
        | VdevStateOffline -> "offline"
        | VdevStateRemoved -> "removed"
        | VdevStateCantOpen -> "can't open"
        | VdevStateFaulted -> "faulted"
        | VdevStateDegraded -> "degraded"
        | VdevStateHealthy -> "healthy"
      in
      Printf.eprintf "%s\n" name;
      failwith "unexpected state"
  | Error e ->
      Printf.eprintf "vdev_set_state failed\n";
      failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* vdev_attach *)
let () =
  let vdevs = common_setup () in
  let vdevs = common_vdev_attach vdevs @@ Printf.sprintf "%s0" test_vdev_name in
  common_cleanup vdevs

(* vdev_detach *)
let () =
  let vdevs = common_setup () in
  (* Get the guid of the initial vdev. *)
  let label = Option.get @@ vdev_label_read @@ List.hd vdevs in
  let vdev = Option.get @@ Nvlist.lookup_nvlist label "vdev_tree" in
  let guid = Option.get @@ Nvlist.lookup_uint64 vdev "guid" in
  (* Attach a vdev to create a mirror. *)
  let vdevs = common_vdev_attach vdevs @@ Printf.sprintf "%s0" test_vdev_name in
  Unix.sleep 1;
  (* Detach the vdev. *)
  let handle = Ioctls.open_handle () in
  (match Ioctls.vdev_detach handle test_pool_name guid with
  | Ok () -> ()
  | Error e ->
      Printf.eprintf "vdev_detach failed\n";
      failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* vdev_split *)
let () =
  let vdevs = common_setup () in
  let vdevs = common_vdev_attach vdevs @@ Printf.sprintf "%s0" test_vdev_name in
  (* Build the config for the new pool. *)
  let conf = Nvlist.alloc () in
  let root = Nvlist.alloc () in
  let label = Option.get @@ vdev_label_read @@ List.hd vdevs in
  let version = Option.get @@ Nvlist.lookup_uint64 label "version" in
  let top = Option.get @@ Nvlist.lookup_nvlist label "vdev_tree" in
  let children = Option.get @@ Nvlist.lookup_nvlist_array top "children" in
  assert (Array.length children == 2);
  Nvlist.add_string root "type" "root";
  Nvlist.add_nvlist_array root "children" @@ Array.sub children 0 1;
  let newname = Printf.sprintf "%s0" test_pool_name in
  Nvlist.add_string conf "name" newname;
  Nvlist.add_uint64 conf "version" version;
  Nvlist.add_nvlist conf "vdev_tree" root;
  let packed_conf = Nvlist.pack conf Nvlist.Native in
  (* Split the pool. *)
  let handle = Ioctls.open_handle () in
  (match
     Ioctls.vdev_split handle test_pool_name newname packed_conf None true
   with
  | Ok () -> ()
  | Error e ->
      Printf.eprintf "vdev_split failed\n";
      failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* vdev_setpath *)
let () =
  let vdevs = common_setup () in
  let label = Option.get @@ vdev_label_read @@ List.hd vdevs in
  let vdev = Option.get @@ Nvlist.lookup_nvlist label "vdev_tree" in
  let guid = Option.get @@ Nvlist.lookup_uint64 vdev "guid" in
  let path = Option.get @@ Nvlist.lookup_string vdev "path" in
  (* Not actually a different path, but good enough for a test. *)
  let handle = Ioctls.open_handle () in
  (match Ioctls.vdev_setpath handle test_pool_name guid path with
  | Ok () -> ()
  | Error e ->
      Printf.eprintf "vdev_setpath failed\n";
      failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* vdev_setfru *)
let () =
  let vdevs = common_setup () in
  let label = Option.get @@ vdev_label_read @@ List.hd vdevs in
  let vdev = Option.get @@ Nvlist.lookup_nvlist label "vdev_tree" in
  let guid = Option.get @@ Nvlist.lookup_uint64 vdev "guid" in
  let handle = Ioctls.open_handle () in
  (match Ioctls.vdev_setfru handle test_pool_name guid "test" with
  | Ok () -> ()
  | Error e ->
      Printf.eprintf "vdev_setfru failed\n";
      failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* vdev_set_props *)
(* vdev_get_props *)
let () =
  let vdevs = common_setup () in
  (* Set a property on the vdev. *)
  let label = Option.get @@ vdev_label_read @@ List.hd vdevs in
  let guid = Option.get @@ Nvlist.lookup_uint64 label "guid" in
  let args = Nvlist.alloc () in
  Nvlist.add_uint64 args "vdevprops_set_vdev" guid;
  let props = Nvlist.alloc () in
  Nvlist.add_string props "comment" test_property_value;
  Nvlist.add_nvlist args "vdevprops_set_props" props;
  let packed_args = Nvlist.pack args Nvlist.Native in
  let handle = Ioctls.open_handle () in
  (match Ioctls.vdev_set_props handle test_pool_name packed_args with
  | Ok () -> ()
  | Error (Some packed_errors, e) ->
      let _errors = Nvlist.unpack packed_errors in
      Printf.eprintf "vdev_set_props failed (with errors)\n";
      failwith @@ Unix.error_message e
  | Error (None, e) ->
      Printf.eprintf "vdev_set_props failed (without errors)\n";
      failwith @@ Unix.error_message e);
  (* Get the properties of the vdev. *)
  let args = Nvlist.alloc () in
  Nvlist.add_uint64 args "vdevprops_get_vdev" guid;
  let props = Nvlist.alloc () in
  Nvlist.add_boolean props "comment";
  Nvlist.add_nvlist args "vdevprops_get_props" props;
  let packed_args = Nvlist.pack args Nvlist.Native in
  let props =
    match Ioctls.vdev_get_props handle test_pool_name packed_args with
    | Ok packed_props -> Nvlist.unpack packed_props
    | Error e ->
        Printf.eprintf "vdev_get_props failed\n";
        failwith @@ Unix.error_message e
  in
  let prop = Option.get @@ Nvlist.lookup_nvlist props "comment" in
  let value = Option.get @@ Nvlist.lookup_string prop "value" in
  assert (value = test_property_value);
  common_cleanup vdevs

(* objset_stats *)
let () =
  let vdevs = common_setup () in
  ignore @@ common_stats_get test_pool_name;
  common_cleanup vdevs

(* objset_zplprops *)
let () =
  let vdevs = common_setup () in
  let handle = Ioctls.open_handle () in
  let props =
    match Ioctls.objset_zplprops handle test_pool_name with
    | Ok packed_zplprops -> Nvlist.unpack packed_zplprops
    | Error e ->
        Printf.eprintf "objset_zplprops failed\n";
        failwith @@ Unix.error_message e
  in
  ignore props;
  common_cleanup vdevs

(* objset_recvd_props requires a received dataset *)

(* dsobj_to_dsname *)
let () =
  let vdevs = common_setup () in
  common_dataset_create test_dataset_name;
  let dsobj = common_objset_id_lookup test_dataset_name in
  let handle = Ioctls.open_handle () in
  let name =
    match Ioctls.dsobj_to_dsname handle test_pool_name dsobj with
    | Ok name -> name
    | Error e ->
        Printf.eprintf "dsobj_to_dsname failed\n";
        failwith @@ Unix.error_message e
  in
  assert (name = test_dataset_name);
  common_cleanup vdevs

(* next_obj *)
let () =
  let vdevs = common_setup () in
  let handle = Ioctls.open_handle () in
  (match Ioctls.next_obj handle test_pool_name 0L with
  | Ok next_opt -> ignore next_opt
  | Error e ->
      Printf.eprintf "next_obj failed\n";
      failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* diff *)
let () =
  let vdevs = common_setup () in
  common_dataset_create test_dataset_name;
  let snap0 = Printf.sprintf "%s0" test_snapshot_name in
  let snap1 = Printf.sprintf "%s1" test_snapshot_name in
  common_snapshot_create snap0;
  common_snapshot_create snap1;
  let _pfd0, pfd1 = Unix.pipe () in
  let handle = Ioctls.open_handle () in
  (match Ioctls.diff handle snap1 snap0 pfd1 with
  | Ok () -> ()
  | Error e ->
      Printf.eprintf "diff failed\n";
      failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* obj_to_path *)
let () =
  let vdevs = common_setup () in
  (* Create the mountpoint. *)
  Unix.mkdir test_mount_name 0o770;
  (* Mount the dataset. *)
  let mount_cmd =
    Printf.sprintf "/sbin/mount -t zfs %s %s" test_pool_name test_mount_name
  in
  assert (Unix.WEXITED 0 = Unix.system mount_cmd);
  (* Make a moderately sized file so we can find and corrupt it. *)
  let buflen =
    65536
    (* max size Unix.read can read *)
  in
  let buffer = Bytes.create buflen in
  let content = "openzfs!" in
  let blitlen = String.length content in
  for i = 0 to (buflen / blitlen) - 1 do
    let offset = i * blitlen in
    Bytes.blit_string content 0 buffer offset blitlen
  done;
  let path = Printf.sprintf "%s/%s" test_mount_name test_file_name in
  let fd = Unix.openfile path [ Unix.O_WRONLY; Unix.O_CREAT ] 0o660 in
  assert (buflen = Unix.write fd buffer 0 buflen);
  Unix.fsync fd;
  Unix.close fd;
  (* Corrupt the file by overwriting some of the data. *)
  let umount_cmd = Printf.sprintf "/sbin/umount -f %s" test_mount_name in
  assert (Unix.WEXITED 0 = Unix.system umount_cmd);
  let handle = Ioctls.open_handle () in
  (match
     Ioctls.pool_export handle test_pool_name false false
       (Some "exporting test pool")
   with
  | Ok () -> ()
  | Error e ->
      Printf.eprintf "pool_export failed (obj_to_path)\n";
      failwith @@ Unix.error_message e);
  let fd = Unix.openfile (List.hd vdevs) [ Unix.O_RDWR ] 0o660 in
  let size = (Unix.fstat fd).st_size in
  let offset =
    Option.get
    @@ Seq.find_map
         (fun offset ->
           assert (buflen = Unix.read fd buffer 0 buflen);
           let s = Bytes.to_string buffer in
           let re = Str.regexp_string content in
           let f i = if Str.string_match re s i then Some i else None in
           let idxs = Seq.take (buflen - blitlen) (Seq.ints 0) in
           match Seq.find_map f idxs with
           | Some i ->
               let corruption = "corrupt" in
               let corruption_len = String.length corruption in
               Bytes.blit_string corruption 0 buffer i corruption_len;
               Some offset
           | None -> None)
         (Seq.init ((size / buflen) - 1) (fun x -> x * buflen))
  in
  assert (offset = Unix.lseek fd (-buflen) Unix.SEEK_CUR);
  assert (buflen = Unix.write fd buffer 0 buflen) (* Heavy, but effective. *);
  Unix.fsync fd;
  Unix.close fd;
  (* Reveal the error. *)
  let packed_config = common_get_config vdevs in
  let config = Nvlist.unpack packed_config in
  let guid = Option.get @@ Nvlist.lookup_uint64 config "pool_guid" in
  let config =
    match
      Ioctls.pool_import handle test_pool_name guid packed_config None
        [| ImportOnly |]
    with
    | Ok packed_config -> Nvlist.unpack packed_config
    | Error (packed_config, e) ->
        let _config = Nvlist.unpack packed_config in
        Printf.eprintf "pool_import failed (obj_to_path)\n";
        failwith @@ Unix.error_message e
  in
  ignore config;
  assert (Unix.WEXITED 0 = Unix.system mount_cmd);
  let fd = Unix.openfile path [ Unix.O_RDONLY ] 0o660 in
  (try
     ignore @@ Unix.read fd buffer 0 buflen;
     failwith "read didn't fail"
   with Unix.Unix_error (Unix.EIO, _func, _param) -> ());
  Unix.close fd;
  (* Read the error log. *)
  let error_log =
    match Ioctls.error_log handle test_pool_name with
    | Ok entries -> entries
    | Error e ->
        Printf.eprintf "error_log failed\n";
        failwith @@ Unix.error_message e
  in
  (* Get the object's path. *)
  let zb = Array.get error_log 0 in
  Printf.printf "got %d errors\n" (Array.length error_log);
  Printf.printf "objset=%Lu object=%Lu level=%Ld blkid=%Lu\n" zb.objset zb.obj
    zb.level zb.blkid;
  let obj_path =
    match Ioctls.obj_to_path handle test_pool_name zb.obj with
    | Ok path -> path
    | Error e ->
        Printf.eprintf "obj_to_path failed\n";
        failwith @@ Unix.error_message e
  in
  Printf.printf "Found error in %s%s\n" test_mount_name obj_path;
  assert (Unix.WEXITED 0 = Unix.system umount_cmd);
  Unix.rmdir test_mount_name;
  common_cleanup vdevs

(* obj_to_stats *)
let () =
  let vdevs = common_setup () in
  common_dataset_create test_dataset_name;
  let snap0 = Printf.sprintf "%s0" test_snapshot_name in
  let snap1 = Printf.sprintf "%s1" test_snapshot_name in
  common_snapshot_create snap0;
  (* Create the mountpoint. *)
  Unix.mkdir test_mount_name 0o770;
  (* Mount the dataset. *)
  let mount_cmd =
    Printf.sprintf "/sbin/mount -t zfs %s %s" test_dataset_name test_mount_name
  in
  assert (Unix.WEXITED 0 = Unix.system mount_cmd);
  (* Make a few files. *)
  Seq.iter (fun i ->
      let path = Printf.sprintf "%s/%s%d" test_mount_name test_file_name i in
      let fd = Unix.openfile path [ Unix.O_WRONLY; Unix.O_CREAT ] 0o660 in
      let buffer = Bytes.of_string @@ Printf.sprintf "foo%dbar%d" i i in
      let buflen = Bytes.length buffer in
      assert (buflen = Unix.write fd buffer 0 buflen);
      Unix.close fd)
  @@ Seq.take 8 @@ Seq.ints 0;
  common_snapshot_create snap1;
  (* Do a diff. *)
  let pfd0, pfd1 = Unix.pipe () in
  let handle = Ioctls.open_handle () in
  (match Ioctls.diff handle snap1 snap0 pfd1 with
  | Ok () -> ()
  | Error e ->
      Printf.eprintf "diff failed (obj_to_stats)\n";
      failwith @@ Unix.error_message e);
  Unix.close pfd1;
  let record_len = 8 * 3 in
  let buffer = Bytes.create record_len in
  let rec read_inuse_records l =
    let len = Unix.read pfd0 buffer 0 record_len in
    if len != record_len then l
    else
      let ddr_type = Bytes.get_int64_ne buffer 0 in
      let ddr_first = Bytes.get_int64_ne buffer 8 in
      let ddr_last = Bytes.get_int64_ne buffer 16 in
      Printf.printf "ddr_type=%Lu ddr_first=0x%Lx ddr_last=0x%Lx\n" ddr_type
        ddr_first ddr_last;
      if Int64.equal ddr_type 0x2L (* DDR_INUSE *) then
        List.cons (ddr_first, ddr_last) (read_inuse_records l)
      else read_inuse_records l
  in
  let diff_records = read_inuse_records [] in
  Printf.printf "got %d records\n" (List.length diff_records);
  Unix.close pfd0;
  (* Get the object's path. *)
  List.iter
    (fun (ddr_first, ddr_last) ->
      Printf.printf "first=0x%Lx last=0x%Lx " ddr_first ddr_last;
      let num_objs = Int64.to_int @@ Int64.sub ddr_last ddr_first in
      Printf.printf "num_objs=%d\n" num_objs;
      Seq.iter (fun obj ->
          match Ioctls.obj_to_stats handle snap1 obj with
          | Ok (path, stats) ->
              Printf.printf "\tobj=0x%Lx gen=0x%Lu path=%s\n" obj stats.gen path
          | Error _e -> ())
      @@ Seq.map Int64.of_int
      @@ Seq.take num_objs (Seq.ints @@ Int64.to_int ddr_first))
    diff_records;
  let umount_cmd = Printf.sprintf "/sbin/umount -f %s" test_mount_name in
  assert (Unix.WEXITED 0 = Unix.system umount_cmd);
  Unix.rmdir test_mount_name;
  common_cleanup vdevs

(* inject_fault *)
(* clear_fault *)
let () =
  let vdevs = common_setup () in
  let fault_id = common_inject_fault vdevs in
  common_clear_fault fault_id;
  common_cleanup vdevs

(* inject_list_next *)
let () =
  let vdevs = common_setup () in
  let fault_id = common_inject_fault vdevs in
  let handle = Ioctls.open_handle () in
  let next_id, pool, _record =
    match Ioctls.inject_list_next handle 0L with
    | Ok (Some stuff) -> stuff
    | Ok None -> failwith "inject_list_next came back empty\n"
    | Error e ->
        Printf.eprintf "inject_list_next failed\n";
        failwith @@ Unix.error_message e
  in
  assert (next_id = fault_id);
  assert (pool = test_pool_name);
  common_clear_fault fault_id;
  common_cleanup vdevs

(* dataset_list_next *)
let () =
  let vdevs = common_setup () in
  common_dataset_create test_dataset_name;
  let handle = Ioctls.open_handle () in
  let dataset, _stats, packed_props_opt, _cookie =
    match Ioctls.dataset_list_next handle test_pool_name false 0L with
    | Ok (Some results) -> results
    | Ok None -> failwith "dataset_list_next came back empty\n"
    | Error e ->
        Printf.eprintf "dataset_list_next failed\n";
        failwith @@ Unix.error_message e
  in
  let _props = Nvlist.unpack @@ Option.get packed_props_opt in
  assert (dataset = test_dataset_name);
  common_cleanup vdevs

(* snapshot_list_next *)
let () =
  let vdevs = common_setup () in
  common_dataset_create test_dataset_name;
  common_snapshot_create test_snapshot_name;
  let handle = Ioctls.open_handle () in
  let snapshot, _stats, packed_props_opt, _cookie =
    match Ioctls.snapshot_list_next handle test_dataset_name false 0L with
    | Ok (Some results) -> results
    | Ok None -> failwith "snapshot_list_next came back empty\n"
    | Error e ->
        Printf.eprintf "snapshot_list_next failed\n";
        failwith @@ Unix.error_message e
  in
  let _props = Nvlist.unpack @@ Option.get packed_props_opt in
  assert (snapshot = test_snapshot_name);
  common_cleanup vdevs

(* get_fsacl *)
let () =
  let vdevs = common_setup () in
  let handle = Ioctls.open_handle () in
  let _fsacl =
    match Ioctls.get_fsacl handle test_pool_name with
    | Ok packed_fsacl -> Nvlist.unpack packed_fsacl
    | Error e ->
        Printf.eprintf "get_fsacl failed\n";
        failwith @@ Unix.error_message e
  in
  common_cleanup vdevs

(* set_fsacl *)
let () =
  let vdevs = common_setup () in
  let acl = Nvlist.alloc () in
  let perms = Nvlist.alloc () in
  Nvlist.add_boolean perms "allow";
  Nvlist.add_nvlist acl "el$" perms;
  Nvlist.add_nvlist acl "El$" perms;
  Nvlist.add_nvlist acl "ed$" perms;
  Nvlist.add_nvlist acl "Ed$" perms;
  let packed_acl = Nvlist.pack acl Nvlist.Native in
  let handle = Ioctls.open_handle () in
  (match Ioctls.set_fsacl handle test_pool_name false packed_acl with
  | Ok () -> ()
  | Error e ->
      Printf.eprintf "set_fsacl failed\n";
      failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* set_prop *)
let () =
  let vdevs = common_setup () in
  let props = Nvlist.alloc () in
  Nvlist.add_string props test_property_name test_property_value;
  let packed_props = Nvlist.pack props Nvlist.Native in
  let handle = Ioctls.open_handle () in
  (match Ioctls.set_prop handle test_pool_name packed_props with
  | Ok () -> ()
  | Error (Some packed_errors, e) ->
      let _errors = Nvlist.unpack packed_errors in
      Printf.eprintf "set_prop failed (with errors)\n";
      failwith @@ Unix.error_message e
  | Error (None, e) ->
      Printf.eprintf "set_prop failed (without errors)\n";
      failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* create *)
let () =
  let vdevs = common_setup () in
  common_dataset_create test_dataset_name;
  common_cleanup vdevs

(* destroy *)
let () =
  let vdevs = common_setup () in
  common_dataset_create test_dataset_name;
  let handle = Ioctls.open_handle () in
  (match Ioctls.destroy handle test_dataset_name false with
  | Ok () -> ()
  | Error e ->
      Printf.eprintf "destroy failed\n";
      failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* rename *)
let () =
  let vdevs = common_setup () in
  common_dataset_create test_dataset_name;
  let newname = Printf.sprintf "%s0" test_dataset_name in
  let handle = Ioctls.open_handle () in
  (match Ioctls.rename handle test_dataset_name newname [||] with
  | Ok () -> ()
  | Error (Some failed, e) ->
      Printf.eprintf "rename failed on %s\n" failed;
      failwith @@ Unix.error_message e
  | Error (None, e) ->
      Printf.eprintf "rename failed\n";
      failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* snapshot *)
let () =
  let vdevs = common_setup () in
  common_dataset_create test_dataset_name;
  common_snapshot_create test_snapshot_name;
  common_cleanup vdevs

(* rollback *)
let () =
  let vdevs = common_setup () in
  common_dataset_create test_dataset_name;
  common_snapshot_create test_snapshot_name;
  let handle = Ioctls.open_handle () in
  let target =
    match Ioctls.rollback handle test_dataset_name None with
    | Ok packed_result ->
        let result = Nvlist.unpack packed_result in
        Option.get @@ Nvlist.lookup_string result "target"
    | Error e ->
        Printf.eprintf "rollback failed\n";
        failwith @@ Unix.error_message e
  in
  assert (target = test_snapshot_name);
  common_cleanup vdevs

(* clone *)
let () =
  let vdevs = common_setup () in
  common_dataset_create test_dataset_name;
  common_snapshot_create test_snapshot_name;
  let clone_name = Printf.sprintf "%s0" test_dataset_name in
  common_clone_create test_snapshot_name clone_name;
  common_cleanup vdevs

(* promote *)
let () =
  let vdevs = common_setup () in
  common_dataset_create test_dataset_name;
  common_snapshot_create test_snapshot_name;
  let clone_name = Printf.sprintf "%s0" test_dataset_name in
  common_clone_create test_snapshot_name clone_name;
  let handle = Ioctls.open_handle () in
  (match Ioctls.promote handle clone_name with
  | Ok () -> ()
  | Error (Some snapname, e) ->
      Printf.eprintf "promote failed (conflicting snapshot %s)\n" snapname;
      failwith @@ Unix.error_message e
  | Error (None, e) ->
      Printf.eprintf "promote failed\n";
      failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* redact *)
let () =
  let vdevs = common_setup () in
  common_dataset_create test_dataset_name;
  let snap0 = Printf.sprintf "%s0" test_snapshot_name in
  let snap1 = Printf.sprintf "%s1" test_snapshot_name in
  common_snapshot_create snap0;
  common_snapshot_create snap1;
  let args = Nvlist.alloc () in
  Nvlist.add_string args "bookname" "testredaction";
  let snaps = Nvlist.alloc () in
  Nvlist.add_boolean snaps snap1;
  Nvlist.add_nvlist args "snapnv" snaps;
  let packed_args = Nvlist.pack args Nvlist.Native in
  let handle = Ioctls.open_handle () in
  (match Ioctls.redact handle snap0 packed_args with
  | Ok () -> ()
  | Error e ->
      Printf.eprintf "redact failed\n";
      failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* destroy_snaps *)
let () =
  let vdevs = common_setup () in
  common_dataset_create test_dataset_name;
  common_snapshot_create test_snapshot_name;
  let args = Nvlist.alloc () in
  let snaps = Nvlist.alloc () in
  Nvlist.add_boolean snaps test_snapshot_name;
  Nvlist.add_nvlist args "snaps" snaps;
  let packed_args = Nvlist.pack args Nvlist.Native in
  let handle = Ioctls.open_handle () in
  (match Ioctls.destroy_snaps handle test_pool_name packed_args with
  | Ok () -> ()
  | Error (Some packed_errors, e) ->
      let _errors = Nvlist.unpack packed_errors in
      Printf.eprintf "destroy_snaps failed (with errors)\n";
      failwith @@ Unix.error_message e
  | Error (None, e) ->
      Printf.eprintf "destroy_snaps failed (without errors)\n";
      failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* inherit_prop *)
let () =
  let vdevs = common_setup () in
  let handle = Ioctls.open_handle () in
  (match Ioctls.inherit_prop handle test_pool_name test_property_name false with
  | Ok () -> ()
  | Error e ->
      Printf.eprintf "inherit_prop failed\n";
      failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* userspace_one *)
let () =
  let vdevs = common_setup () in
  let handle = Ioctls.open_handle () in
  let space =
    match Ioctls.userspace_one handle test_pool_name Userused "" 0L with
    | Ok space -> space
    | Error e ->
        Printf.eprintf "userspace_one failed\n";
        failwith @@ Unix.error_message e
  in
  Printf.printf "user root (0) used %Lu bytes\n" space;
  common_cleanup vdevs

(* userspace_many *)
let () =
  let vdevs = common_setup () in
  let handle = Ioctls.open_handle () in
  (match Ioctls.userspace_many handle test_pool_name Userused 8 0L with
  | Ok (_cookie, useraccts) ->
      let nuseraccts = Array.length useraccts in
      Printf.printf "got %d useracct record(s)\n" nuseraccts
  | Error e ->
      Printf.eprintf "userspace_many failed\n";
      failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* userspace_upgrade *)
let () =
  let vdevs = common_setup () in
  let handle = Ioctls.open_handle () in
  (match Ioctls.userspace_upgrade handle test_pool_name with
  | Ok () -> ()
  | Error e ->
      Printf.eprintf "userspace_upgrade failed\n";
      failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* hold *)
let () =
  let vdevs = common_setup () in
  common_dataset_create test_dataset_name;
  common_snapshot_create test_snapshot_name;
  common_hold_create test_snapshot_name test_tag_name;
  common_cleanup vdevs

(* release *)
let () =
  let vdevs = common_setup () in
  common_dataset_create test_dataset_name;
  common_snapshot_create test_snapshot_name;
  common_hold_create test_snapshot_name test_tag_name;
  let args = Nvlist.alloc () in
  let holds = Nvlist.alloc () in
  Nvlist.add_boolean holds test_tag_name;
  Nvlist.add_nvlist args test_snapshot_name holds;
  let packed_args = Nvlist.pack args Nvlist.Native in
  let handle = Ioctls.open_handle () in
  (match Ioctls.release handle test_pool_name packed_args with
  | Ok () -> ()
  | Error (Some packed_errors, e) ->
      let _errors = Nvlist.unpack packed_errors in
      Printf.eprintf "release failed (with errors)\n";
      failwith @@ Unix.error_message e
  | Error (None, e) ->
      Printf.eprintf "release failed (without errors)\n";
      failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* get_holds *)
let () =
  let vdevs = common_setup () in
  common_dataset_create test_dataset_name;
  common_snapshot_create test_snapshot_name;
  common_hold_create test_snapshot_name test_tag_name;
  let handle = Ioctls.open_handle () in
  let _holds =
    match Ioctls.get_holds handle test_snapshot_name with
    | Ok packed_holds -> Nvlist.unpack packed_holds
    | Error e ->
        Printf.eprintf "get_holds failed\n";
        failwith @@ Unix.error_message e
  in
  common_cleanup vdevs

(* send *)
let () =
  let vdevs = common_setup () in
  common_dataset_create test_dataset_name;
  common_snapshot_create test_snapshot_name;
  let objsetid = common_objset_id_lookup test_snapshot_name in
  let fd = Unix.openfile "/dev/null" [ Unix.O_WRONLY ] 0 in
  let handle = Ioctls.open_handle () in
  (match
     Ioctls.send handle test_snapshot_name (Some fd) true objsetid None false
       [||]
   with
  | Ok None -> ()
  | Ok (Some _estimate) -> failwith "send returned an estimate unexpectedly"
  | Error e ->
      Printf.eprintf "send failed\n";
      failwith @@ Unix.error_message e);
  Unix.close fd;
  common_cleanup vdevs

(* recv is too complicated for testing here *)

(* send_progress *)
let () =
  let vdevs = common_setup () in
  common_dataset_create test_dataset_name;
  common_snapshot_create test_snapshot_name;
  (*
   * Create a pipe and fill it up.  We want to block in the middle of
   * the send operation.
   *)
  let pfd0, pfd1 = Unix.pipe () in
  Unix.set_nonblock pfd0;
  let buflen =
    4096
    (* standard page size *)
  in
  let buffer = Bytes.create buflen in
  (try
     while buflen = Unix.single_write pfd0 buffer 0 buflen do
       ()
     done
   with
  | Unix.Unix_error (Unix.EWOULDBLOCK, _func, _param) -> ()
  | Unix.Unix_error (Unix.EAGAIN, _func, _param) -> ());
  Unix.clear_nonblock pfd0;
  (* Start the send operation in a thread. *)
  let sender () =
    let objsetid = common_objset_id_lookup test_snapshot_name in
    let handle = Ioctls.open_handle () in
    match
      Ioctls.send handle test_snapshot_name (Some pfd0) true objsetid None false
        [||]
    with
    | Ok None -> ()
    | Error Unix.EPIPE -> ()
    | Ok (Some _estimate) -> failwith "send returned unexpected estimate"
    | Error e ->
        Printf.eprintf "send failed (send_progress)\n";
        failwith @@ Unix.error_message e
  in
  let td = Domain.spawn sender in
  (* Check the send progress. *)
  Unix.sleep 1;
  let handle = Ioctls.open_handle () in
  let written, logical =
    match Ioctls.send_progress handle test_snapshot_name pfd0 with
    | Ok sizes -> sizes
    | Error e ->
        Printf.eprintf "send_progress failed\n";
        failwith @@ Unix.error_message e
  in
  Printf.printf "sent %Lu bytes (logical %Lu bytes)\n" written logical;
  (* Clean up the sender thread. *)
  Unix.close pfd1;
  Unix.close pfd0;
  Domain.join td;
  common_cleanup vdevs

(* send_new *)
let () =
  let vdevs = common_setup () in
  common_dataset_create test_dataset_name;
  common_snapshot_create test_snapshot_name;
  let fd = Unix.openfile "/dev/null" [ Unix.O_WRONLY ] 0 in
  let args = Nvlist.alloc () in
  Nvlist.add_int32 args "fd" @@ Int32.of_int @@ Util.int_of_descr fd;
  let packed_args = Nvlist.pack args Nvlist.Native in
  let handle = Ioctls.open_handle () in
  (match Ioctls.send_new handle test_snapshot_name packed_args with
  | Ok () -> ()
  | Error e ->
      Printf.eprintf "send_new failed\n";
      failwith @@ Unix.error_message e);
  Unix.close fd;
  common_cleanup vdevs

(* send_space *)
let () =
  let vdevs = common_setup () in
  common_dataset_create test_dataset_name;
  common_snapshot_create test_snapshot_name;
  let handle = Ioctls.open_handle () in
  let space =
    match Ioctls.send_space handle test_snapshot_name None with
    | Ok packed_result ->
        let result = Nvlist.unpack packed_result in
        Option.get @@ Nvlist.lookup_uint64 result "space"
    | Error e ->
        Printf.eprintf "send_space failed\n";
        failwith @@ Unix.error_message e
  in
  Printf.printf "send space: %Lu bytes\n" space;
  common_cleanup vdevs

(* clear *)
let () =
  let vdevs = common_setup () in
  let handle = Ioctls.open_handle () in
  (match Ioctls.clear handle test_pool_name None None with
  | Ok None -> ()
  | Ok (Some _packed_config) -> failwith "clear returned unexpected config\n"
  | Error e ->
      Printf.eprintf "clear failed\n";
      failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* bookmark *)
let () =
  let vdevs = common_setup () in
  common_dataset_create test_dataset_name;
  common_snapshot_create test_snapshot_name;
  common_bookmark_create test_pool_name test_snapshot_name test_bookmark_name;
  common_cleanup vdevs

(* get_bookmarks *)
let () =
  let vdevs = common_setup () in
  common_dataset_create test_dataset_name;
  common_snapshot_create test_snapshot_name;
  common_bookmark_create test_pool_name test_snapshot_name test_bookmark_name;
  let props = Nvlist.alloc () in
  Nvlist.add_boolean props "guid";
  let packed_props = Nvlist.pack props Nvlist.Native in
  let handle = Ioctls.open_handle () in
  let _bookmarks =
    match Ioctls.get_bookmarks handle test_dataset_name (Some packed_props) with
    | Ok packed_props -> Nvlist.unpack packed_props
    | Error e ->
        Printf.eprintf "get_bookmarks failed\n";
        failwith @@ Unix.error_message e
  in
  common_cleanup vdevs

(* get_bookmark_props *)
let () =
  let vdevs = common_setup () in
  common_dataset_create test_dataset_name;
  common_snapshot_create test_snapshot_name;
  common_bookmark_create test_pool_name test_snapshot_name test_bookmark_name;
  let handle = Ioctls.open_handle () in
  let _props =
    match Ioctls.get_bookmark_props handle test_bookmark_name with
    | Ok packed_props -> Nvlist.unpack packed_props
    | Error e ->
        Printf.eprintf "get_bookmark_props failed\n";
        failwith @@ Unix.error_message e
  in
  common_cleanup vdevs

(* destroy_bookmarks *)
let () =
  let vdevs = common_setup () in
  common_dataset_create test_dataset_name;
  common_snapshot_create test_snapshot_name;
  common_bookmark_create test_pool_name test_snapshot_name test_bookmark_name;
  let list = Nvlist.alloc () in
  Nvlist.add_boolean list test_bookmark_name;
  let packed_list = Nvlist.pack list Nvlist.Native in
  let handle = Ioctls.open_handle () in
  (match Ioctls.destroy_bookmarks handle test_pool_name packed_list with
  | Ok () -> ()
  | Error (Some packed_errors, e) ->
      let _errors = Nvlist.unpack packed_errors in
      Printf.eprintf "destroy_bookmarks failed (with errors)\n";
      failwith @@ Unix.error_message e
  | Error (None, e) ->
      Printf.eprintf "destroy_bookmarks failed (without errors)\n";
      failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* nextboot *)
let () =
  let vdevs = common_setup () in
  let label = Option.get @@ vdev_label_read @@ List.hd vdevs in
  let pool_guid = Option.get @@ Nvlist.lookup_uint64 label "pool_guid" in
  let guid = Option.get @@ Nvlist.lookup_uint64 label "guid" in
  let args = Nvlist.alloc () in
  Nvlist.add_uint64 args "pool_guid" pool_guid;
  Nvlist.add_uint64 args "guid" guid;
  Nvlist.add_string args "command" "";
  let packed_args = Nvlist.pack args Nvlist.Native in
  let handle = Ioctls.open_handle () in
  (match Ioctls.nextboot handle packed_args with
  | Ok () -> ()
  | Error e ->
      Printf.eprintf "nextboot failed\n";
      failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* channel_program *)
let () =
  let vdevs = common_setup () in
  common_dataset_create test_dataset_name;
  let args = Nvlist.alloc () in
  Nvlist.add_string args "program" test_channel_program;
  let arglist = Nvlist.alloc () in
  Nvlist.add_string arglist "DS" test_pool_name;
  Nvlist.add_nvlist args "arg" arglist;
  Nvlist.add_boolean_value args "sync" true;
  Nvlist.add_uint64 args "instrlimit" test_channel_program_instrlimit;
  Nvlist.add_uint64 args "memlimit" test_channel_program_memlimit;
  let packed_args = Nvlist.pack args Nvlist.Native in
  let handle = Ioctls.open_handle () in
  let _result =
    match
      Ioctls.channel_program handle test_pool_name packed_args
        test_channel_program_memlimit
    with
    | Ok packed_result -> Nvlist.unpack packed_result
    | Error (Some packed_errors, e) ->
        let _errors = Nvlist.unpack packed_errors in
        Printf.eprintf "channel_program failed (with errors)\n";
        failwith @@ Unix.error_message e
    | Error (None, e) ->
        Printf.eprintf "channel_program failed (without errors)\n";
        failwith @@ Unix.error_message e
  in
  common_cleanup vdevs

(* error_log *)
let () =
  let vdevs = common_setup () in
  let handle = Ioctls.open_handle () in
  let errors =
    match Ioctls.error_log handle test_pool_name with
    | Ok error_log -> error_log
    | Error e ->
        Printf.eprintf "error_log failed\n";
        failwith @@ Unix.error_message e
  in
  assert (errors = [||]);
  common_cleanup vdevs

(* log_history *)
let () =
  let vdevs = common_setup () in
  let args = Nvlist.alloc () in
  Nvlist.add_string args "message" "this is a test";
  let packed_args = Nvlist.pack args Nvlist.Native in
  let handle = Ioctls.open_handle () in
  (match Ioctls.log_history handle packed_args with
  | Ok () -> ()
  | Error e ->
      Printf.eprintf "log_history failed\n";
      failwith @@ Unix.error_message e);
  common_cleanup vdevs

(* tmp_snapshot *)
let () =
  let vdevs = common_setup () in
  common_dataset_create test_dataset_name;
  let prefix = Printf.sprintf "zfs-diff-%d" @@ Unix.getpid () in
  let fd = Unix.openfile "/dev/zfs" [ Unix.O_RDWR ] 0 in
  let handle = Ioctls.open_handle () in
  let name =
    match Ioctls.tmp_snapshot handle test_dataset_name prefix fd with
    | Ok name -> name
    | Error e ->
        Printf.eprintf "tmp_snapshot failed\n";
        failwith @@ Unix.error_message e
  in
  Printf.printf "tmp_snapshot named %s\n" name;
  common_cleanup vdevs

(* jail and unjail are a bit complicated for these tests (require a jail) *)

(* space_written *)
let () =
  let vdevs = common_setup () in
  common_dataset_create test_dataset_name;
  common_snapshot_create test_snapshot_name;
  let handle = Ioctls.open_handle () in
  let space, compressed, uncompressed =
    match Ioctls.space_written handle test_dataset_name test_snapshot_name with
    | Ok result -> result
    | Error e ->
        Printf.eprintf "space_written failed\n";
        failwith @@ Unix.error_message e
  in
  Printf.printf "space written: %Lu bytes (%Lu compressed, %Lu uncompressed)\n"
    space compressed uncompressed;
  common_cleanup vdevs

(* space_snaps *)
let () =
  let vdevs = common_setup () in
  common_dataset_create test_dataset_name;
  let snap0 = Printf.sprintf "%s0" test_snapshot_name in
  let snap1 = Printf.sprintf "%s1" test_snapshot_name in
  common_snapshot_create snap0;
  common_snapshot_create snap1;
  let args = Nvlist.alloc () in
  Nvlist.add_string args "firstsnap" snap0;
  let packed_args = Nvlist.pack args Nvlist.Native in
  let handle = Ioctls.open_handle () in
  let _result =
    match Ioctls.space_snaps handle snap1 packed_args with
    | Ok packed_result -> Nvlist.unpack packed_result
    | Error e ->
        Printf.eprintf "space_snaps failed\n";
        failwith @@ Unix.error_message e
  in
  common_cleanup vdevs

(* set_bootenv *)
(* get_bootenv *)
let () =
  let vdevs = common_setup () in
  let bootenv = Nvlist.alloc () in
  Nvlist.add_uint64 bootenv "version" 1L (* VB_NVLIST *);
  Nvlist.add_string bootenv "testvar" "testvalue";
  let packed_bootenv = Nvlist.pack bootenv Nvlist.Native in
  let handle = Ioctls.open_handle () in
  (match Ioctls.set_bootenv handle test_pool_name packed_bootenv with
  | Ok () -> ()
  | Error e ->
      Printf.eprintf "set_bootenv failed\n";
      failwith @@ Unix.error_message e);
  let bootenv =
    match Ioctls.get_bootenv handle test_pool_name with
    | Ok packed_bootenv -> Nvlist.unpack packed_bootenv
    | Error e ->
        Printf.eprintf "get_bootenv failed\n";
        failwith @@ Unix.error_message e
  in
  let value = Option.get @@ Nvlist.lookup_string bootenv "testvar" in
  assert (value = "testvalue");
  common_cleanup vdevs

(* wait *)
let () =
  let vdevs = common_setup () in
  let args = Nvlist.alloc () in
  Nvlist.add_int32 args "wait_activity" 1l (* ZPOOL_WAIT_FREE *);
  let packed_args = Nvlist.pack args Nvlist.Native in
  let handle = Ioctls.open_handle () in
  let result =
    match Ioctls.wait handle test_pool_name packed_args with
    | Ok packed_result -> Nvlist.unpack packed_result
    | Error e ->
        Printf.eprintf "wait failed\n";
        failwith @@ Unix.error_message e
  in
  let waited = Option.get @@ Nvlist.lookup_boolean_value result "wait_waited" in
  Printf.printf "waited=%s\n" (if waited then "true" else "false");
  common_cleanup vdevs

(* wait_fs *)
let () =
  let vdevs = common_setup () in
  let args = Nvlist.alloc () in
  Nvlist.add_int32 args "wait_activity" 0l (* ZFS_WAIT_DELETEQ *);
  let packed_args = Nvlist.pack args Nvlist.Native in
  let handle = Ioctls.open_handle () in
  let result =
    match Ioctls.wait_fs handle test_pool_name packed_args with
    | Ok packed_result -> Nvlist.unpack packed_result
    | Error e ->
        Printf.eprintf "wait_fs failed\n";
        failwith @@ Unix.error_message e
  in
  let waited = Option.get @@ Nvlist.lookup_boolean_value result "wait_waited" in
  Printf.printf "fs waited=%s\n" (if waited then "true" else "false");
  common_cleanup vdevs

(* load_key, unload_key, change_key are too complicated for these tests *)
