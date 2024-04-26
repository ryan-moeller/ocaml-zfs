type t =
  | Allocated
  | Allocating
  | Ashift
  | Asize
  | Bootsize
  | Bytes_claim
  | Bytes_free
  | Bytes_null
  | Bytes_read
  | Bytes_trim
  | Bytes_write
  | Capacity
  | Checksum_errors
  | Checksum_n
  | Checksum_t
  | Children
  | Comment
  | Devid
  | Enc_path
  | Expandsz
  | Failfast
  | Fragmentation
  | Free
  | Fru
  | Guid
  | Initialize_errors
  | Inval
  | Io_n
  | Io_t
  | Name
  | Numchildren
  | Ops_claim
  | Ops_free
  | Ops_null
  | Ops_read
  | Ops_trim
  | Ops_write
  | Parent
  | Parity
  | Path
  | Phys_path
  | Psize
  | Raidz_expanding
  | Read_errors
  | Removing
  | Size
  | Slow_io_n
  | Slow_io_t
  | State
  | Userprop
  | Write_errors

let of_string = function
  | "allocated" -> Allocated
  | "allocating" -> Allocating
  | "ashift" -> Ashift
  | "asize" -> Asize
  | "bootsize" -> Bootsize
  | "capacity" -> Capacity
  | "checksum_errors" -> Checksum_errors
  | "checksum_n" -> Checksum_n
  | "checksum_t" -> Checksum_t
  | "children" -> Children
  | "claim_bytes" -> Bytes_claim
  | "claim_ops" -> Ops_claim
  | "comment" -> Comment
  | "devid" -> Devid
  | "encpath" -> Enc_path
  | "expandsize" -> Expandsz
  | "failfast" -> Failfast
  | "fragmentation" -> Fragmentation
  | "free" -> Free
  | "free_bytes" -> Bytes_free
  | "free_ops" -> Ops_free
  | "fru" -> Fru
  | "guid" -> Guid
  | "initialize_errors" -> Initialize_errors
  | "io_n" -> Io_n
  | "io_t" -> Io_t
  | "name" -> Name
  | "null_bytes" -> Bytes_null
  | "null_ops" -> Ops_null
  | "numchildren" -> Numchildren
  | "parent" -> Parent
  | "parity" -> Parity
  | "path" -> Path
  | "physpath" -> Phys_path
  | "psize" -> Psize
  | "raidz_expanding" -> Raidz_expanding
  | "read_bytes" -> Bytes_read
  | "read_errors" -> Read_errors
  | "read_ops" -> Ops_read
  | "removing" -> Removing
  | "size" -> Size
  | "slow_io_n" -> Slow_io_n
  | "slow_io_t" -> Slow_io_t
  | "state" -> State
  | "trim_bytes" -> Bytes_trim
  | "trim_ops" -> Ops_trim
  | "write_bytes" -> Bytes_write
  | "write_errors" -> Write_errors
  | "write_ops" -> Ops_write
  | _ -> Inval

type prop_type = Number | String | Index

type attributes = {
  name : string;
  prop_type : prop_type;
  numdefault : int64;
  readonly : bool;
  values : string option;
  colname : string;
  rightalign : bool;
  visible : bool;
  flex : bool;
  index_table : (string * int64) array;
}

let attributes = function
  | Inval | Userprop -> failwith "not a valid property"
  | Allocated ->
      {
        name = "allocated";
        prop_type = Number;
        numdefault = 0L;
        readonly = true;
        values = Some "<size>";
        colname = "ALLOC";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Allocating ->
      {
        name = "allocating";
        prop_type = Index;
        numdefault = 1L;
        readonly = false;
        values = Some "on | off";
        colname = "ALLOCATING";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [| ("off", 0L); ("on", 1L); ("-", 2L) |];
      }
  | Ashift ->
      {
        name = "ashift";
        prop_type = Number;
        numdefault = 0L;
        readonly = true;
        values = Some "<ashift>";
        colname = "ASHIFT";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Asize ->
      {
        name = "asize";
        prop_type = Number;
        numdefault = 0L;
        readonly = true;
        values = Some "<asize>";
        colname = "ASIZE";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Bootsize ->
      {
        name = "bootsize";
        prop_type = Number;
        numdefault = 0L;
        readonly = true;
        values = Some "<size>";
        colname = "BOOTSIZE";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Bytes_claim ->
      {
        name = "claim_bytes";
        prop_type = Number;
        numdefault = 0L;
        readonly = true;
        values = Some "<bytes>";
        colname = "CLAIMBYTE";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Bytes_free ->
      {
        name = "free_bytes";
        prop_type = Number;
        numdefault = 0L;
        readonly = true;
        values = Some "<bytes>";
        colname = "FREEBYTE";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Bytes_null ->
      {
        name = "null_bytes";
        prop_type = Number;
        numdefault = 0L;
        readonly = true;
        values = Some "<bytes>";
        colname = "NULLBYTE";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Bytes_read ->
      {
        name = "read_bytes";
        prop_type = Number;
        numdefault = 0L;
        readonly = true;
        values = Some "<bytes>";
        colname = "READBYTE";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Bytes_trim ->
      {
        name = "trim_bytes";
        prop_type = Number;
        numdefault = 0L;
        readonly = true;
        values = Some "<bytes>";
        colname = "TRIMBYTE";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Bytes_write ->
      {
        name = "write_bytes";
        prop_type = Number;
        numdefault = 0L;
        readonly = true;
        values = Some "<bytes>";
        colname = "WRITEBYTE";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Capacity ->
      {
        name = "capacity";
        prop_type = Number;
        numdefault = 0L;
        readonly = true;
        values = Some "<size>";
        colname = "CAP";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Checksum_errors ->
      {
        name = "checksum_errors";
        prop_type = Number;
        numdefault = 0L;
        readonly = true;
        values = Some "<errors>";
        colname = "CKERR";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Checksum_n ->
      {
        name = "checksum_n";
        prop_type = Number;
        numdefault = -1L;
        readonly = false;
        values = Some "<events>";
        colname = "CKSUM_N";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Checksum_t ->
      {
        name = "checksum_t";
        prop_type = Number;
        numdefault = -1L;
        readonly = false;
        values = Some "<seconds>";
        colname = "CKSUM_T";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Children ->
      {
        name = "children";
        prop_type = String;
        numdefault = 0L;
        readonly = true;
        values = Some "<child>[,...]";
        colname = "CHILDREN";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [||];
      }
  | Comment ->
      {
        name = "comment";
        prop_type = String;
        numdefault = 0L;
        readonly = false;
        values = Some "<comment-string>";
        colname = "COMMENT";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [||];
      }
  | Devid ->
      {
        name = "devid";
        prop_type = String;
        numdefault = 0L;
        readonly = true;
        values = Some "<devid>";
        colname = "DEVID";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [||];
      }
  | Enc_path ->
      {
        name = "encpath";
        prop_type = String;
        numdefault = 0L;
        readonly = true;
        values = Some "<encpath>";
        colname = "ENCPATH";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [||];
      }
  | Expandsz ->
      {
        name = "expandsize";
        prop_type = Number;
        numdefault = 0L;
        readonly = true;
        values = Some "<size>";
        colname = "EXPANDSZ";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Failfast ->
      {
        name = "failfast";
        prop_type = Index;
        numdefault = 1L;
        readonly = false;
        values = Some "on | off";
        colname = "FAILFAST";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [| ("off", 0L); ("on", 1L) |];
      }
  | Fragmentation ->
      {
        name = "fragmentation";
        prop_type = Number;
        numdefault = 0L;
        readonly = true;
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
        readonly = true;
        values = Some "<size>";
        colname = "FREE";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Fru ->
      {
        name = "fru";
        prop_type = String;
        numdefault = 0L;
        readonly = true;
        values = Some "<fru>";
        colname = "FRU";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [||];
      }
  | Guid ->
      {
        name = "guid";
        prop_type = Number;
        numdefault = 0L;
        readonly = true;
        values = Some "<guid>";
        colname = "GUID";
        rightalign = true;
        visible = true;
        flex = true;
        index_table = [||];
      }
  | Initialize_errors ->
      {
        name = "initialize_errors";
        prop_type = Number;
        numdefault = 0L;
        readonly = true;
        values = Some "<errors>";
        colname = "INITERR";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Io_n ->
      {
        name = "io_n";
        prop_type = Number;
        numdefault = -1L;
        readonly = false;
        values = Some "<events>";
        colname = "IO_N";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Io_t ->
      {
        name = "io_t";
        prop_type = Number;
        numdefault = -1L;
        readonly = false;
        values = Some "<seconds>";
        colname = "IO_T";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Name ->
      {
        name = "name";
        prop_type = Number;
        numdefault = 0L;
        readonly = true;
        values = None;
        colname = "NAME";
        rightalign = false;
        visible = false;
        flex = true;
        index_table = [||];
      }
  | Numchildren ->
      {
        name = "numchildren";
        prop_type = Number;
        numdefault = 0L;
        readonly = true;
        values = Some "<number-of-children>";
        colname = "NUMCHILD";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Ops_claim ->
      {
        name = "claim_ops";
        prop_type = Number;
        numdefault = 0L;
        readonly = true;
        values = Some "<operations>";
        colname = "CLAIMOP";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Ops_free ->
      {
        name = "free_ops";
        prop_type = Number;
        numdefault = 0L;
        readonly = true;
        values = Some "<operations>";
        colname = "FREEOP";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Ops_null ->
      {
        name = "null_ops";
        prop_type = Number;
        numdefault = 0L;
        readonly = true;
        values = Some "<operations>";
        colname = "NULLOP";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Ops_read ->
      {
        name = "read_ops";
        prop_type = Number;
        numdefault = 0L;
        readonly = true;
        values = Some "<operations>";
        colname = "READOP";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Ops_trim ->
      {
        name = "trim_ops";
        prop_type = Number;
        numdefault = 0L;
        readonly = true;
        values = Some "<operations>";
        colname = "TRIMOP";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Ops_write ->
      {
        name = "write_ops";
        prop_type = Number;
        numdefault = 0L;
        readonly = true;
        values = Some "<operations>";
        colname = "WRITEOP";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Parent ->
      {
        name = "parent";
        prop_type = String;
        numdefault = 0L;
        readonly = true;
        values = Some "<parent>";
        colname = "PARENT";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [||];
      }
  | Parity ->
      {
        name = "parity";
        prop_type = Number;
        numdefault = 0L;
        readonly = true;
        values = Some "<parity>";
        colname = "PARITY";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Path ->
      {
        name = "path";
        prop_type = String;
        numdefault = 0L;
        readonly = false;
        values = Some "<device-path>";
        colname = "PATH";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [||];
      }
  | Phys_path ->
      {
        name = "physpath";
        prop_type = String;
        numdefault = 0L;
        readonly = true;
        values = Some "<physpath>";
        colname = "PHYSPATH";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [||];
      }
  | Psize ->
      {
        name = "psize";
        prop_type = Number;
        numdefault = 0L;
        readonly = true;
        values = Some "<psize>";
        colname = "PSIZE";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Raidz_expanding ->
      {
        name = "raidz_expanding";
        prop_type = Index;
        numdefault = 0L;
        readonly = true;
        values = Some "on | off";
        colname = "RAIDZ_EXPANDING";
        rightalign = false;
        visible = true;
        flex = true;
        index_table = [| ("off", 0L); ("on", 1L) |];
      }
  | Read_errors ->
      {
        name = "read_errors";
        prop_type = Number;
        numdefault = 0L;
        readonly = true;
        values = Some "<errors>";
        colname = "RDERR";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Removing ->
      {
        name = "removing";
        prop_type = Index;
        numdefault = 0L;
        readonly = true;
        values = Some "on | off";
        colname = "REMOVING";
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
        readonly = true;
        values = Some "<size>";
        colname = "SIZE";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Slow_io_n ->
      {
        name = "slow_io_n";
        prop_type = Number;
        numdefault = -1L;
        readonly = false;
        values = Some "<events>";
        colname = "SLOW_IO_N";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Slow_io_t ->
      {
        name = "slow_io_t";
        prop_type = Number;
        numdefault = -1L;
        readonly = false;
        values = Some "<seconds>";
        colname = "SLOW_IO_T";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | State ->
      {
        name = "state";
        prop_type = Number;
        numdefault = 0L;
        readonly = true;
        values = Some "<state>";
        colname = "STATE";
        rightalign = true;
        visible = true;
        flex = false;
        index_table = [||];
      }
  | Write_errors ->
      {
        name = "write_errors";
        prop_type = Number;
        numdefault = 0L;
        readonly = true;
        values = Some "<errors>";
        colname = "WRERR";
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
