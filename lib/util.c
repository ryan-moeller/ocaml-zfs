#include <sys/param.h>
#include <sys/sysctl.h>
#include <pwd.h>
#include <unistd.h>
#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/fail.h>
#include <caml/memory.h>
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

	size = sizeof hostid;
	if (sysctlbyname("kern.hostid", &hostid, &size, NULL, 0) == -1) {
		caml_failwith("sysctlbyname");
	}
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

CAMLprim value
caml_zfs_util_getpwnam(value name)
{
	CAMLparam1 (name);
	CAMLlocal2 (ret, record);
	char buf[2048];
	struct passwd pwd = {"\0"};
	struct passwd *pw;
	int err;

	err = getpwnam_r(String_val(name), &pwd, buf, sizeof buf, &pw);
	if (err != 0) {
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
