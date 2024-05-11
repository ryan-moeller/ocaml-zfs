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

CAMLprim value
caml_zfs_util_getpwnam(value name)
{
	CAMLparam1 (name);
	CAMLlocal2 (ret, record);
	char buf[2048];
	struct passwd pwd = {"\0"};
	struct passwd *pw;
	int err;

	caml_release_runtime_system();
	err = getpwnam_r(String_val(name), &pwd, buf, sizeof buf, &pw);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else if (pw == NULL) {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_none);
	} else {
		record = caml_alloc_tuple(10);
		Store_field(record, 0, caml_copy_string(pw->pw_name));
		Store_field(record, 1, caml_copy_string(pw->pw_passwd));
		Store_field(record, 2, Val_int(pw->pw_uid));
		Store_field(record, 3, Val_int(pw->pw_gid));
		Store_field(record, 4, caml_copy_int64(pw->pw_change));
		Store_field(record, 5, caml_copy_string(pw->pw_class));
		Store_field(record, 6, caml_copy_string(pw->pw_gecos));
		Store_field(record, 7, caml_copy_string(pw->pw_dir));
		Store_field(record, 8, caml_copy_string(pw->pw_shell));
		Store_field(record, 9, caml_copy_int64(pw->pw_expire));
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, caml_alloc_some(record));
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_util_getgrnam(value name)
{
	CAMLparam1 (name);
	CAMLlocal2 (ret, record);
	char buf[2048];
	struct group grp = {"\0"};
	struct group *gr;
	int err;

	caml_release_runtime_system();
	err = getgrnam_r(String_val(name), &grp, buf, sizeof buf, &gr);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else if (gr == NULL) {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_none);
	} else {
		record = caml_alloc_tuple(4);
		Store_field(record, 0, caml_copy_string(gr->gr_name));
		Store_field(record, 1, caml_copy_string(gr->gr_passwd));
		Store_field(record, 2, Val_int(gr->gr_gid));
		Store_field(record, 3,
		    caml_copy_string_array((const char **)gr->gr_mem));
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, caml_alloc_some(record));
	}
	CAMLreturn (ret);
}
