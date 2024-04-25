type t =
  | Allocated
  | Altroot
  | Ashift
  | Autoexpand
  | Autoreplace
  | Autotrim
  | Bcloneratio
  | Bclonesaved
  | Bcloneused
  | Bootfs
  | Cachefile
  | Capacity
  | Checkpoint
  | Comment
  | Compatibility
  | Dedupditto
  | Dedupratio
  | Delegation
  | Expandsz
  | Failuremode
  | Fragmentation
  | Free
  | Freeing
  | Guid
  | Health
  | Inval
  | Leaked
  | Listsnaps
  | Load_guid
  | Maxblocksize
  | Maxdnodesize
  | Multihost
  | Name
  | Readonly
  | Size
  | Tname
  | Version

let of_string = function
  | "allocated" -> Allocated
  | "altroot" -> Altroot
  | "ashift" -> Ashift
  | "autoexpand" -> Autoexpand
  | "autoreplace" -> Autoreplace
  | "autotrim" -> Autotrim
  | "bcloneratio" -> Bcloneratio
  | "bclonesaved" -> Bclonesaved
  | "bcloneused" -> Bcloneused
  | "bootfs" -> Bootfs
  | "cachefile" -> Cachefile
  | "capacity" -> Capacity
  | "checkpoint" -> Checkpoint
  | "comment" -> Comment
  | "compatibility" -> Compatibility
  | "dedupditto" -> Dedupditto
  | "dedupratio" -> Dedupratio
  | "delegation" -> Delegation
  | "expandsize" -> Expandsz
  | "failmode" -> Failuremode
  | "fragmentation" -> Fragmentation
  | "free" -> Free
  | "freeing" -> Freeing
  | "guid" -> Guid
  | "health" -> Health
  | "leaked" -> Leaked
  | "listsnapshots" -> Listsnaps
  | "load_guid" -> Load_guid
  | "maxblocksize" -> Maxblocksize
  | "maxdnodesize" -> Maxdnodesize
  | "multihost" -> Multihost
  | "name" -> Name
  | "readonly" -> Readonly
  | "size" -> Size
  | "tname" -> Tname
  | "version" -> Version
  | _ -> Inval

type prop_type = Number | String | Index

type attributes = {
  name : string;
  prop_type : prop_type;
  numdefault : int64;
  strdefault : string option;
  readonly : bool;
  onetime : bool;
  values : string option;
  colname : string;
  rightalign : bool;
  visible : bool;
  flex : bool;
  index_table : (string * int64) array;
}

let attributes = function
  | Inval -> failwith "not a valid property"
  | Allocated ->
      {
        name = "allocated";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        onetime = false;
        values = Some "<size>";
        colname = "ALLOC";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Altroot ->
      {
        name = "altroot";
        prop_type = String;
        numdefault = 0L;
        strdefault = None;
        readonly = false;
        onetime = false;
        values = Some "<path>";
        colname = "ALTROOT";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [||];
      }
  | Ashift ->
      {
        name = "ashift";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = false;
        onetime = false;
        values = Some "<ashift; 9-16; or 0=default";
        colname = "ASHIFT";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Autoexpand ->
      {
        name = "autoexpand";
        prop_type = Index;
        numdefault = 0L;
        strdefault = None;
        readonly = false;
        onetime = false;
        values = Some "on | off";
        colname = "EXPAND";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [| ("off", 0L); ("on", 1L) |];
      }
  | Autoreplace ->
      {
        name = "autoreplace";
        prop_type = Index;
        numdefault = 0L;
        strdefault = None;
        readonly = false;
        onetime = false;
        values = Some "on | off";
        colname = "REPLACE";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [| ("off", 0L); ("on", 1L) |];
      }
  | Autotrim ->
      {
        name = "autotrim";
        prop_type = Index;
        numdefault = 0L;
        strdefault = None;
        readonly = false;
        onetime = false;
        values = Some "on | off";
        colname = "AUTOTRIM";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [| ("off", 0L); ("on", 1L) |];
      }
  | Bcloneratio ->
      {
        name = "bcloneratio";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        onetime = false;
        values = Some "<1.00x or higher if cloned>";
        colname = "BCLONE_RATIO";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Bclonesaved ->
      {
        name = "bclonesaved";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        onetime = false;
        values = Some "<size>";
        colname = "BCLONE_SAVED";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Bcloneused ->
      {
        name = "bcloneused";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        onetime = false;
        values = Some "<size>";
        colname = "BCLONE_USED";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Bootfs ->
      {
        name = "bootfs";
        prop_type = String;
        numdefault = 0L;
        strdefault = None;
        readonly = false;
        onetime = false;
        values = Some "<filesystem>";
        colname = "BOOTFS";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [||];
      }
  | Cachefile ->
      {
        name = "cachefile";
        prop_type = String;
        numdefault = 0L;
        strdefault = None;
        readonly = false;
        onetime = false;
        values = Some "<file> | none";
        colname = "CACHEFILE";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [||];
      }
  | Capacity ->
      {
        name = "capacity";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        onetime = false;
        values = Some "<size>";
        colname = "CAP";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Checkpoint ->
      {
        name = "checkpoint";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        onetime = false;
        values = Some "<size>";
        colname = "CKPOINT";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Comment ->
      {
        name = "comment";
        prop_type = String;
        numdefault = 0L;
        strdefault = None;
        readonly = false;
        onetime = false;
        values = Some "<comment-string>";
        colname = "COMMENT";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [||];
      }
  | Compatibility ->
      {
        name = "compatibility";
        prop_type = String;
        numdefault = 0L;
        strdefault = Some "off";
        readonly = false;
        onetime = false;
        values = Some "<file[,file...]> | off | legacy";
        colname = "COMPATIBILITY";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [||];
      }
  | Dedupditto ->
      {
        name = "dedupditto";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = false;
        onetime = false;
        values = None;
        colname = "DEDUPDITTO";
        rightalign = true;
        visible = false;
        flex = false;
        index_table = [||];
      }
  | Dedupratio ->
      {
        name = "dedupratio";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        onetime = false;
        values = Some "<1.00x or higher if deduped>";
        colname = "DEDUP";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Delegation ->
      {
        name = "delegation";
        prop_type = Index;
        numdefault = 1L;
        strdefault = None;
        readonly = false;
        onetime = false;
        values = Some "on | off";
        colname = "DELEGATION";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [| ("off", 0L); ("on", 1L) |];
      }
  | Expandsz ->
      {
        name = "expandsize";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        onetime = false;
        values = Some "<size>";
        colname = "EXPANDSZ";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Failuremode ->
      {
        name = "failmode";
        prop_type = Index;
        numdefault = 0L;
        strdefault = None;
        readonly = false;
        onetime = false;
        values = Some "wait | continue | panic";
        colname = "FAILMODE";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [| ("wait", 0L); ("continue", 1L); ("panic", 2L) |];
      }
  | Fragmentation ->
      {
        name = "fragmentation";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        onetime = false;
        values = Some "<percent>";
        colname = "FRAG";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Free ->
      {
        name = "free";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        onetime = false;
        values = Some "<size>";
        colname = "FREE";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Freeing ->
      {
        name = "freeing";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        onetime = false;
        values = Some "<size>";
        colname = "FREEING";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Guid ->
      {
        name = "guid";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        onetime = false;
        values = Some "<guid>";
        colname = "GUID";
        rightalign = true;
        visible = true;
        flex = true;
        index_table = [||];
      }
  | Health ->
      {
        name = "health";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        onetime = false;
        values = Some "<state>";
        colname = "HEALTH";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Leaked ->
      {
        name = "leaked";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        onetime = false;
        values = Some "<size>";
        colname = "LEAKED";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Listsnaps ->
      {
        name = "listsnapshots";
        prop_type = Index;
        numdefault = 0L;
        strdefault = None;
        readonly = false;
        onetime = false;
        values = Some "on | off";
        colname = "LISTSNAPS";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [| ("off", 0L); ("on", 1L) |];
      }
  | Load_guid ->
      {
        name = "load_guid";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        onetime = false;
        values = Some "<load_guid>";
        colname = "LOAD_GUID";
        rightalign = true;
        visible = true;
        flex = true;
        index_table = [||];
      }
  | Maxblocksize ->
      {
        name = "maxblocksize";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        onetime = false;
        values = None;
        colname = "MAXBLOCKSIZE";
        rightalign = true;
        visible = false;
        flex = false;
        index_table = [||];
      }
  | Maxdnodesize ->
      {
        name = "maxdnodesize";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        onetime = false;
        values = None;
        colname = "MAXDNODESIZE";
        rightalign = true;
        visible = false;
        flex = false;
        index_table = [||];
      }
  | Multihost ->
      {
        name = "multihost";
        prop_type = Index;
        numdefault = 0L;
        strdefault = None;
        readonly = false;
        onetime = false;
        values = Some "on | off";
        colname = "MULTIHOST";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [| ("off", 0L); ("on", 1L) |];
      }
  | Name ->
      {
        name = "name";
        prop_type = String;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        onetime = false;
        values = None;
        colname = "NAME";
        rightalign = false;
        visible = false;
        flex = true;
        index_table = [||];
      }
  | Readonly ->
      {
        name = "readonly";
        prop_type = Index;
        numdefault = 0L;
        strdefault = None;
        readonly = false;
        onetime = false;
        values = Some "on | off";
        colname = "RDONLY";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [| ("off", 0L); ("on", 1L) |];
      }
  | Size ->
      {
        name = "size";
        prop_type = Number;
        numdefault = 0L;
        strdefault = None;
        readonly = true;
        onetime = false;
        values = Some "<size>";
        colname = "SIZE";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Tname ->
      {
        name = "tname";
        prop_type = String;
        numdefault = 0L;
        strdefault = None;
        readonly = false;
        onetime = true;
        values = None;
        colname = "TNAME";
        rightalign = false;
        visible = false;
        flex = true;
        index_table = [||];
      }
  | Version ->
      {
        name = "version";
        prop_type = Number;
        numdefault = 5000L (* SPA_VERSION *);
        strdefault = None;
        readonly = false;
        onetime = false;
        values = Some "<version>";
        colname = "VERSION";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }

let to_string prop = (attributes prop).name

let string_to_index prop str =
  (attributes prop).index_table
  |> Array.find_map (fun (s, i) -> if s = str then Some i else None)

let index_to_string prop idx =
  (attributes prop).index_table
  |> Array.find_map (fun (s, i) -> if i = idx then Some s else None)
