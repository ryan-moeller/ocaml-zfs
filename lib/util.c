#include <sys/param.h>
#include <sys/sysctl.h>
#include <unistd.h>
#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/fail.h>
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

CAMLprim value
caml_zfs_util_getzoneid(value unit)
{
	CAMLparam1 (unit);
	size_t size;
	int jid;

	size = sizeof jid;
	if (sysctlbyname("security.jail.param.jid", &jid, &size, NULL, 0) == -1) {
		caml_failwith("sysctlbyname");
	}
	CAMLreturn (Val_int(jid));
}
