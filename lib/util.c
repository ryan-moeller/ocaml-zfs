#include <sys/param.h>
#include <sys/sysctl.h>
#include <grp.h>
#include <pwd.h>
#include <unistd.h>
#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/fail.h>
#include <caml/memory.h>
#include <caml/threads.h>
#include <caml/unixsupport.h>

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
	unsigned long hostid;
	size_t size;
	int err;

	size = sizeof hostid;
	caml_release_runtime_system();
	err = sysctlbyname("kern.hostid", &hostid, &size, NULL, 0);
	caml_acquire_runtime_system();
	if (err) {
		caml_failwith("sysctlbyname");
	}
	CAMLreturn (caml_copy_int32(hostid));
}

CAMLprim value
caml_zfs_util_getzoneid(value unit)
{
	CAMLparam1 (unit);
	size_t size;
	int jid, err;

	size = sizeof jid;
	caml_release_runtime_system();
	err = sysctlbyname("security.jail.param.jid", &jid, &size, NULL, 0);
	caml_acquire_runtime_system();
	if (err) {
		caml_failwith("sysctlbyname");
	}
	CAMLreturn (Val_int(jid));
}
