#include <sys/param.h>
#include <unistd.h>
#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/memory.h>

CAMLprim value
caml_zfs_util_int_of_descr(value descr)
{
	CAMLparam1 (descr);
	CAMLreturn (descr);
}

CAMLprim value
caml_zfs_util_int_of_pool_scan_func(value func)
{
	CAMLparam1 (func);
	CAMLreturn (func);
}

CAMLprim value
caml_zfs_util_int_of_pool_scrub_cmd(value cmd)
{
	CAMLparam1 (cmd);
	CAMLreturn (cmd);
}

CAMLprim value
caml_zfs_util_get_system_hostid(value unit)
{
	CAMLparam1 (unit);
	long hostid;

	hostid = gethostid();
	CAMLreturn (caml_copy_int32(hostid));
}
