type t =
  | Allocation_classes
  | Async_destroy
  | Avz_v2
  | Blake3
  | Block_cloning
  | Block_cloning_endian
  | Bookmark_v2
  | Bookmark_written
  | Bookmarks
  | Device_rebuild
  | Device_removal
  | Dynamic_gang_header
  | Draid
  | Draid_fail_domains
  | Edonr
  | Embedded_data
  | Empty_bpobj
  | Enabled_txg
  | Encryption
  | Extensible_dataset
  | Fast_dedup
  | Fs_ss_limit
  | Head_errlog
  | Hole_birth
  | Large_blocks
  | Large_dnode
  | Large_microzap
  | Livelist
  | Log_spacemap
  | Longname
  | Lz4_compress
  | Multi_vdev_crash_dump
  | None
  | Obsolete_counts
  | Physical_rewrite
  | Pool_checkpoint
  | Project_quota
  | Raidz_expansion
  | Redacted_datasets
  | Redaction_bookmarks
  | Redaction_list_spill
  | Resilver_defer
  | Sha512
  | Skein
  | Spacemap_histogram
  | Spacemap_v2
  | Userobj_accounting
  | Zilsaxattr
  | Zstd_compress

let of_string = function
  | "allocation_classes" -> Allocation_classes
  | "async_destroy" -> Async_destroy
  | "blake3" -> Blake3
  | "block_cloning" -> Block_cloning
  | "block_cloning_endian" -> Block_cloning_endian
  | "bookmark_v2" -> Bookmark_v2
  | "bookmark_written" -> Bookmark_written
  | "bookmarks" -> Bookmarks
  | "device_rebuild" -> Device_rebuild
  | "device_removal" -> Device_removal
  | "draid" -> Draid
  | "draid_failure_domains" -> Draid_fail_domains
  | "dynamic_gang_header" -> Dynamic_gang_header
  | "edonr" -> Edonr
  | "embedded_data" -> Embedded_data
  | "empty_bpobj" -> Empty_bpobj
  | "enabled_txg" -> Enabled_txg
  | "encryption" -> Encryption
  | "extensible_dataset" -> Extensible_dataset
  | "fast_dedup" -> Fast_dedup
  | "filesystem_limits" -> Fs_ss_limit
  | "head_errlog" -> Head_errlog
  | "hole_birth" -> Hole_birth
  | "large_blocks" -> Large_blocks
  | "large_dnode" -> Large_dnode
  | "large_microzap" -> Large_microzap
  | "livelist" -> Livelist
  | "log_spacemap" -> Log_spacemap
  | "longname" -> Longname
  | "lz4_compress" -> Lz4_compress
  | "multi_vdev_crash_dump" -> Multi_vdev_crash_dump
  | "obsolete_counts" -> Obsolete_counts
  | "physical_rewrite" -> Physical_rewrite
  | "project_quota" -> Project_quota
  | "raidz_expansion" -> Raidz_expansion
  | "redacted_datasets" -> Redacted_datasets
  | "redaction_bookmarks" -> Redaction_bookmarks
  | "redaction_list_spill" -> Redaction_list_spill
  | "resilver_defer" -> Resilver_defer
  | "sha512" -> Sha512
  | "skein" -> Skein
  | "spacemap_histogram" -> Spacemap_histogram
  | "spacemap_v2" -> Spacemap_v2
  | "userobj_accounting" -> Userobj_accounting
  | "vdev_zaps_v2" -> Avz_v2
  | "zilsaxattr" -> Zilsaxattr
  | "zpool_checkpoint" -> Pool_checkpoint
  | "zstd_compress" -> Zstd_compress
  | _ -> None

let of_propname propname = Scanf.sscanf_opt propname "feature@%s" of_string

type attributes = {
  name : string;
  guid : string;
  description : string;
  readonly_compat : bool;
  required_for_mos : bool;
  activate_on_enable : bool;
  per_dataset : bool;
  no_upgrade : bool;
  depends : t array;
}

let attributes = function
  | None -> failwith "not a valid feature"
  | Allocation_classes ->
      {
        name = "allocation_classes";
        guid = "org.zfsonlinux:allocation_classes";
        description = "Support for separate allocation classes.";
        readonly_compat = true;
        required_for_mos = false;
        activate_on_enable = false;
        per_dataset = false;
        no_upgrade = false;
        depends = [||];
      }
  | Async_destroy ->
      {
        name = "async_destroy";
        guid = "com.delphix:async_destroy";
        description = "Destroy filesystems asynchronously.";
        readonly_compat = true;
        required_for_mos = false;
        activate_on_enable = false;
        per_dataset = false;
        no_upgrade = false;
        depends = [||];
      }
  | Avz_v2 ->
      {
        name = "vdev_zaps_v2";
        guid = "com.klarasystems:vdev_zaps_v2";
        description = "Support for root vdev ZAP.";
        readonly_compat = false;
        required_for_mos = true;
        activate_on_enable = false;
        per_dataset = false;
        no_upgrade = false;
        depends = [||];
      }
  | Blake3 ->
      {
        name = "blake3";
        guid = "org.openzfs:blake3";
        description = "BLAKE3 hash algorithm.";
        readonly_compat = false;
        required_for_mos = false;
        activate_on_enable = false;
        per_dataset = true;
        no_upgrade = false;
        depends = [| Extensible_dataset |];
      }
  | Block_cloning ->
      {
        name = "block_cloning";
        guid = "com.fudosecurity:block_cloning";
        description = "Support for block cloning via Block Reference Table.";
        readonly_compat = true;
        required_for_mos = false;
        activate_on_enable = false;
        per_dataset = false;
        no_upgrade = false;
        depends = [||];
      }
  | Block_cloning_endian ->
      {
        name = "block_cloning_endian";
        guid = "com.truenas:block_cloning_endian";
        description = "Fixes BRT ZAP endianness on new pools.";
        readonly_compat = true;
        required_for_mos = false;
        activate_on_enable = false;
        per_dataset = false;
        no_upgrade = false;
        depends = [||];
      }
  | Bookmark_v2 ->
      {
        name = "bookmark_v2";
        guid = "com.datto:bookmark_v2";
        description = "Support for larger bookmarks";
        readonly_compat = false;
        required_for_mos = false;
        activate_on_enable = false;
        per_dataset = false;
        no_upgrade = false;
        depends = [| Extensible_dataset; Bookmarks |];
      }
  | Bookmark_written ->
      {
        name = "bookmark_written";
        guid = "com.delphix:bookmark_written";
        description =
          "Additional accounting, enabling the written#<bookmark> property \
           (space written since a bookmark), and estimates of send stream \
           sizes for incrementals from bookmarks.";
        readonly_compat = false;
        required_for_mos = false;
        activate_on_enable = false;
        per_dataset = false;
        no_upgrade = false;
        depends = [| Bookmark_v2; Extensible_dataset; Bookmarks |];
      }
  | Bookmarks ->
      {
        name = "bookmarks";
        guid = "com.delphix:bookmarks";
        description = {|"zfs bookmark" command|};
        readonly_compat = true;
        required_for_mos = false;
        activate_on_enable = false;
        per_dataset = false;
        no_upgrade = false;
        depends = [| Extensible_dataset |];
      }
  | Device_rebuild ->
      {
        name = "device_rebuild";
        guid = "org.openzfs:device_rebuild";
        description = "Support for sequential mirror/dRAID device rebuilds.";
        readonly_compat = true;
        required_for_mos = false;
        activate_on_enable = false;
        per_dataset = false;
        no_upgrade = false;
        depends = [||];
      }
  | Device_removal ->
      {
        name = "device_removal";
        guid = "com.delphix:device_removal";
        description =
          "Top-level vdevs can be removed, reducing logical pool size.";
        readonly_compat = false;
        required_for_mos = true;
        activate_on_enable = false;
        per_dataset = false;
        no_upgrade = false;
        depends = [||];
      }
  | Draid ->
      {
        name = "draid";
        guid = "org.openzfs:draid";
        description = "Support for distributed spare RAID";
        readonly_compat = false;
        required_for_mos = true;
        activate_on_enable = false;
        per_dataset = false;
        no_upgrade = false;
        depends = [||];
      }
  | Draid_fail_domains ->
      {
        name = "draid_failure_domains";
        guid = "com.seagate:draid_failure_domains";
        description = "Support for failure domains in dRAID";
        readonly_compat = false;
        required_for_mos = true;
        activate_on_enable = false;
        per_dataset = false;
        no_upgrade = false;
        depends = [| Draid |];
      }
  | Dynamic_gang_header ->
      {
        name = "dynamic_gang_header";
        guid = "com.klarasystems:dynamic_gang_header";
        description = "com.klarasystems:dynamic_gang_header";
        readonly_compat = false;
        required_for_mos = true;
        activate_on_enable = false;
        per_dataset = false;
        no_upgrade = true;
        depends = [||];
      }
  | Edonr ->
      {
        name = "edonr";
        guid = "org.illumos:edonr";
        description = "Edon-R hash algorithm.";
        readonly_compat = false;
        required_for_mos = false;
        activate_on_enable = false;
        per_dataset = true;
        no_upgrade = false;
        depends = [| Extensible_dataset |];
      }
  | Embedded_data ->
      {
        name = "embedded_data";
        guid = "com.delphix:embedded_data";
        description = "Blocks which compress very well use even less space.";
        readonly_compat = false;
        required_for_mos = true;
        activate_on_enable = true;
        per_dataset = false;
        no_upgrade = false;
        depends = [||];
      }
  | Empty_bpobj ->
      {
        name = "empty_bpobj";
        guid = "com.delphix:empty_bpobj";
        description = "Snapshots use less space.";
        readonly_compat = true;
        required_for_mos = false;
        activate_on_enable = false;
        per_dataset = false;
        no_upgrade = false;
        depends = [||];
      }
  | Enabled_txg ->
      {
        name = "enabled_txg";
        guid = "com.delphix:enabled_txg";
        description = "Record txg at which a feature is enabled";
        readonly_compat = true;
        required_for_mos = false;
        activate_on_enable = false;
        per_dataset = false;
        no_upgrade = false;
        depends = [||];
      }
  | Encryption ->
      {
        name = "encryption";
        guid = "com.datto:encryption";
        description = "Support for dataset level encryption";
        readonly_compat = false;
        required_for_mos = false;
        activate_on_enable = false;
        per_dataset = true;
        no_upgrade = false;
        depends = [| Extensible_dataset; Bookmark_v2 |];
      }
  | Extensible_dataset ->
      {
        name = "extensible_dataset";
        guid = "com.delphix:extensible_dataset";
        description = "Enhanced dataset functionality, used by other features.";
        readonly_compat = false;
        required_for_mos = false;
        activate_on_enable = false;
        per_dataset = false;
        no_upgrade = false;
        depends = [||];
      }
  | Fast_dedup ->
      {
        name = "fast_dedup";
        guid = "com.klarasystems:fast_dedup";
        description = "Support for advanced deduplication";
        readonly_compat = true;
        required_for_mos = false;
        activate_on_enable = false;
        per_dataset = false;
        no_upgrade = false;
        depends = [||];
      }
  | Fs_ss_limit ->
      {
        name = "filesystem_limits";
        guid = "com.joyent:filesystem_limits";
        description = "Filesystem and snapshot limits.";
        readonly_compat = true;
        required_for_mos = false;
        activate_on_enable = false;
        per_dataset = false;
        no_upgrade = false;
        depends = [| Extensible_dataset |];
      }
  | Head_errlog ->
      {
        name = "head_errlog";
        guid = "com.delphix:head_errlog";
        description = "Support for per-dataset on-disk error logs.";
        readonly_compat = false;
        required_for_mos = false;
        activate_on_enable = true;
        per_dataset = false;
        no_upgrade = false;
        depends = [||];
      }
  | Hole_birth ->
      {
        name = "hole_birth";
        guid = "com.delphix:hole_birth";
        description = "Retain hole birth txg for more precise zfs send";
        readonly_compat = false;
        required_for_mos = true;
        activate_on_enable = true;
        per_dataset = false;
        no_upgrade = false;
        depends = [| Enabled_txg |];
      }
  | Large_blocks ->
      {
        name = "large_blocks";
        guid = "org.open-zfs:large_blocks";
        description = "Support for blocks larger than 128KB.";
        readonly_compat = false;
        required_for_mos = false;
        activate_on_enable = false;
        per_dataset = true;
        no_upgrade = false;
        depends = [| Extensible_dataset |];
      }
  | Large_dnode ->
      {
        name = "large_dnode";
        guid = "org.zfsonlinux:large_dnode";
        description = "Variable on-disk size of dnodes.";
        readonly_compat = false;
        required_for_mos = false;
        activate_on_enable = false;
        per_dataset = true;
        no_upgrade = false;
        depends = [| Extensible_dataset |];
      }
  | Large_microzap ->
      {
        name = "large_microzap";
        guid = "com.klarasystems:large_microzap";
        description = "Support for microzaps larger than 128KB.";
        readonly_compat = true;
        required_for_mos = false;
        activate_on_enable = false;
        per_dataset = true;
        no_upgrade = false;
        depends = [| Extensible_dataset; Large_blocks |];
      }
  | Livelist ->
      {
        name = "livelist";
        guid = "com.delphix:livelist";
        description = "Improved clone deletion performance.";
        readonly_compat = true;
        required_for_mos = false;
        activate_on_enable = false;
        per_dataset = false;
        no_upgrade = false;
        depends = [| Extensible_dataset |];
      }
  | Log_spacemap ->
      {
        name = "log_spacemap";
        guid = "com.delphix:log_spacemap";
        description =
          "Log metaslab changes on a single spacemap and flush them \
           periodically.";
        readonly_compat = true;
        required_for_mos = false;
        activate_on_enable = false;
        per_dataset = false;
        no_upgrade = false;
        depends = [| Spacemap_v2 |];
      }
  | Longname ->
      {
        name = "longname";
        guid = "org.zfsonlinux:longname";
        description = "support filename up to 1024 bytes";
        readonly_compat = false;
        required_for_mos = false;
        activate_on_enable = false;
        per_dataset = true;
        no_upgrade = false;
        depends = [| Extensible_dataset |];
      }
  | Lz4_compress ->
      {
        name = "lz4_compress";
        guid = "org.illumos:lz4_compress";
        description = "LZ4 compression algorithm support.";
        readonly_compat = false;
        required_for_mos = false;
        activate_on_enable = true;
        per_dataset = false;
        no_upgrade = false;
        depends = [||];
      }
  | Multi_vdev_crash_dump ->
      {
        name = "multi_vdev_crash_dump";
        guid = "com.joyent:multi_vdev_crash_dump";
        description = "Crash dumps to multiple vdev pools.";
        readonly_compat = false;
        required_for_mos = false;
        activate_on_enable = false;
        per_dataset = false;
        no_upgrade = false;
        depends = [||];
      }
  | Obsolete_counts ->
      {
        name = "obsolete_counts";
        guid = "com.delphix:obsolete_counts";
        description =
          "Reduce memory used by removed devices when their blocks are freed \
           or remapped.";
        readonly_compat = true;
        required_for_mos = false;
        activate_on_enable = false;
        per_dataset = false;
        no_upgrade = false;
        depends = [| Extensible_dataset; Device_removal |];
      }
  | Physical_rewrite ->
      {
        name = "physical_rewrite";
        guid = "com.truenas:physical_rewrite";
        description =
          "Support for preserving logical birth time during rewrite.";
        readonly_compat = true;
        required_for_mos = false;
        activate_on_enable = false;
        per_dataset = true;
        no_upgrade = false;
        depends = [| Extensible_dataset |];
      }
  | Pool_checkpoint ->
      {
        name = "zpool_checkpoint";
        guid = "com.delphix:zpool_checkpoint";
        description = "Pool state can be checkpointed, allowing rewind later.";
        readonly_compat = true;
        required_for_mos = false;
        activate_on_enable = false;
        per_dataset = false;
        no_upgrade = false;
        depends = [||];
      }
  | Project_quota ->
      {
        name = "project_quota";
        guid = "org.zfsonlinux:project_quota";
        description = "space/object accounting based on project ID.";
        readonly_compat = true;
        required_for_mos = false;
        activate_on_enable = false;
        per_dataset = true;
        no_upgrade = false;
        depends = [| Extensible_dataset |];
      }
  | Raidz_expansion ->
      {
        name = "raidz_expansion";
        guid = "org.openzfs:raidz_expansion";
        description = "Support for raidz expansion";
        readonly_compat = false;
        required_for_mos = true;
        activate_on_enable = false;
        per_dataset = false;
        no_upgrade = false;
        depends = [||];
      }
  | Redacted_datasets ->
      {
        name = "redacted_datasets";
        guid = "com.delphix:redacted_datasets";
        description =
          "Support for redacted datasets, produced by receiving a redacted zfs \
           send stream.";
        readonly_compat = false;
        required_for_mos = false;
        activate_on_enable = false;
        per_dataset = true;
        no_upgrade = false;
        depends = [| Extensible_dataset |];
      }
  | Redaction_bookmarks ->
      {
        name = "redaction_bookmarks";
        guid = "com.delphix:redaction_bookmarks";
        description =
          "Support for bookmarks which store redaction lists for zfs redacted \
           send/recv.";
        readonly_compat = false;
        required_for_mos = false;
        activate_on_enable = false;
        per_dataset = false;
        no_upgrade = false;
        depends = [| Bookmark_v2; Extensible_dataset; Bookmarks |];
      }
  | Redaction_list_spill ->
      {
        name = "redaction_list_spill";
        guid = "com.delphix:redaction_list_spill";
        description =
          "Support for increased number of redaction_snapshot arguments in zfs \
           redact.";
        readonly_compat = false;
        required_for_mos = false;
        activate_on_enable = false;
        per_dataset = false;
        no_upgrade = false;
        depends = [| Redaction_bookmarks |];
      }
  | Resilver_defer ->
      {
        name = "resilver_defer";
        guid = "com.datto:resilver_defer";
        description =
          "Support for deferring new resilvers when one is already running.";
        readonly_compat = true;
        required_for_mos = false;
        activate_on_enable = false;
        per_dataset = false;
        no_upgrade = false;
        depends = [||];
      }
  | Sha512 ->
      {
        name = "sha512";
        guid = "org.illumos:sha512";
        description = "SHA-512/256 hash algorithm.";
        readonly_compat = false;
        required_for_mos = false;
        activate_on_enable = false;
        per_dataset = true;
        no_upgrade = false;
        depends = [| Extensible_dataset |];
      }
  | Skein ->
      {
        name = "skein";
        guid = "org.illumos:skein";
        description = "Skein hash algorithm.";
        readonly_compat = false;
        required_for_mos = false;
        activate_on_enable = false;
        per_dataset = true;
        no_upgrade = false;
        depends = [| Extensible_dataset |];
      }
  | Spacemap_histogram ->
      {
        name = "spacemap_histogram";
        guid = "com.delphix:spacemap_histogram";
        description = "Spacemaps maintain space histograms.";
        readonly_compat = true;
        required_for_mos = false;
        activate_on_enable = false;
        per_dataset = false;
        no_upgrade = false;
        depends = [||];
      }
  | Spacemap_v2 ->
      {
        name = "spacemap_v2";
        guid = "com.delphix:spacemap_v2";
        description =
          "Space maps representing large segments are more efficient.";
        readonly_compat = true;
        required_for_mos = false;
        activate_on_enable = true;
        per_dataset = false;
        no_upgrade = false;
        depends = [||];
      }
  | Userobj_accounting ->
      {
        name = "userobj_accounting";
        guid = "org.zfsonlinux:userobj_accounting";
        description = "User/group object accounting.";
        readonly_compat = true;
        required_for_mos = false;
        activate_on_enable = false;
        per_dataset = true;
        no_upgrade = false;
        depends = [| Extensible_dataset |];
      }
  | Zilsaxattr ->
      {
        name = "zilsaxattr";
        guid = "org.openzfs:zilsaxattr";
        description = "Support for xattr=sa extended attribute logging in ZIL.";
        readonly_compat = true;
        required_for_mos = false;
        activate_on_enable = false;
        per_dataset = true;
        no_upgrade = false;
        depends = [| Extensible_dataset |];
      }
  | Zstd_compress ->
      {
        name = "zstd_compress";
        guid = "org.freebsd:zstd_compress";
        description = "zstd compression algorithm support.";
        readonly_compat = false;
        required_for_mos = false;
        activate_on_enable = false;
        per_dataset = true;
        no_upgrade = false;
        depends = [| Extensible_dataset |];
      }

let to_string prop = (attributes prop).name

let all_features =
  (* Keep in enum spa_features order for ease of maintenance. *)
  let features =
    [|
      Async_destroy;
      Empty_bpobj;
      Lz4_compress;
      Multi_vdev_crash_dump;
      Spacemap_histogram;
      Enabled_txg;
      Hole_birth;
      Extensible_dataset;
      Embedded_data;
      Bookmarks;
      Fs_ss_limit;
      Large_blocks;
      Large_dnode;
      Sha512;
      Skein;
      Edonr;
      Userobj_accounting;
      Encryption;
      Project_quota;
      Device_removal;
      Obsolete_counts;
      Pool_checkpoint;
      Spacemap_v2;
      Allocation_classes;
      Resilver_defer;
      Bookmark_v2;
      Redaction_bookmarks;
      Redacted_datasets;
      Bookmark_written;
      Log_spacemap;
      Livelist;
      Device_rebuild;
      Zstd_compress;
      Draid;
      Zilsaxattr;
      Head_errlog;
      Blake3;
      Block_cloning;
      Avz_v2;
      Redaction_list_spill;
      Raidz_expansion;
      Fast_dedup;
      Longname;
      Large_microzap;
    |]
  in
  match Sysctl.getbyname "kern.osreldate" with
  | Sysctl.Int freebsd_version ->
      if freebsd_version <= 1500056 then features
      else begin
        let features =
          Array.append features
            [| Dynamic_gang_header; Block_cloning_endian; Physical_rewrite |]
        in
        if freebsd_version <= 1600015 then features
        else begin
          Array.append features [| Draid_fail_domains |]
        end
      end
  | _ -> failwith "kern.osreldate expected Int"
