#include <sys/param.h>
#include <sys/mount.h>
#include <sys/stat.h>
#include <sys/uio.h>
#include <sys/zfs_ioctl.h>
#include <sys/fs/zfs.h>
#include <sys/endian.h>
#include <sys/wait.h>
#include <fcntl.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/memory.h>
#include <caml/fail.h>
#include <caml/threads.h>
#include <caml/unixsupport.h>
#include <caml/custom.h>

#define CONFIG_BUF_MINSIZE 262144

#define ZFS_IOCVER_OZFS 15

typedef struct zfs_iocparm {
	uint32_t zfs_ioctl_version;
	uint64_t zfs_cmd;
	uint64_t zfs_cmd_size;
} zfs_iocparm_t;

static void custom_finalize_devzfs(value);

static const struct custom_operations devzfs_ops = {
	"org.openzfs.devzfs",
	custom_finalize_devzfs,
	custom_compare_default,
	custom_hash_default,
	custom_serialize_default,
	custom_deserialize_default,
	custom_compare_ext_default,
	custom_fixed_length_default
};

#define Devzfs_val(v) (*((int *) Data_custom_val(v)))

static value
custom_alloc_devzfs(int fd)
{
	value v = caml_alloc_custom(&devzfs_ops, sizeof (int), 0, 1);
	Devzfs_val(v) = fd;
	return v;
}

static void
custom_finalize_devzfs(value handle)
{
	close(Devzfs_val(handle));
}

CAMLprim value
caml_devzfs_open(value unit)
{
	CAMLparam1 (unit);
	int fd;

	caml_release_runtime_system();
	fd = open(ZFS_DEV, O_RDWR);
	if (fd == -1) {
		int err = errno;
		caml_acquire_runtime_system();
		caml_unix_error(err, "open", caml_copy_string(ZFS_DEV));
	}
	caml_acquire_runtime_system();
	CAMLreturn (custom_alloc_devzfs(fd));
}

static int
zfs_ioctl(int fd, unsigned long request, zfs_cmd_t *zc)
{
	zfs_iocparm_t zp;
	size_t oldsize;
	int err;

	oldsize = zc->zc_nvlist_dst_size;
	zp.zfs_cmd = (uint64_t)(uintptr_t)zc;
	zp.zfs_cmd_size = sizeof (zfs_cmd_t);
	zp.zfs_ioctl_version = ZFS_IOCVER_OZFS;
	err = ioctl(fd, _IOWR('Z', request, zfs_iocparm_t), &zp);
	if (err == 0 & oldsize < zc->zc_nvlist_dst_size) {
		err = ENOMEM;
	} else if (err) {
		err = errno;
	}
	return (err);
}

CAMLprim value
caml_zfs_ioc_pool_create(value handle, value name, value config, value props_opt)
{
	CAMLparam4 (handle, name, config, props_opt);
	CAMLlocal2 (props, ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_nvlist_conf = (uint64_t)(uintptr_t)Bytes_val(config);
	zc.zc_nvlist_conf_size = caml_string_length(config);
	if (Is_some(props_opt)) {
		props = Some_val(props_opt);
		zc.zc_nvlist_src = (uint64_t)(uintptr_t)Bytes_val(props);
		zc.zc_nvlist_src_size = caml_string_length(props);
	}
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_POOL_CREATE, &zc);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_pool_destroy(value handle, value name, value log_msg)
{
	CAMLparam3 (handle, name, log_msg);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_history = (uint64_t)(uintptr_t)String_val(log_msg);
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_POOL_DESTROY, &zc);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

/* Convert import_flag variant into ZFS_IMPORT_* flag */
#define Import_flag_val(v) ((1ULL << Int_val(v)) >> 1)

CAMLprim value
caml_zfs_ioc_pool_import_native(value handle, value name, value guid,
    value config, value properties, value flags)
{
	CAMLparam5 (handle, name, guid, config, properties);
	CAMLxparam1 (flags);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_guid = Int64_val(guid);
	zc.zc_nvlist_conf = (uint64_t)(uintptr_t)Bytes_val(config);
	zc.zc_nvlist_conf_size = caml_string_length(config);
	if (Is_some(properties)) {
		zc.zc_nvlist_src = (uint64_t)(uintptr_t)Bytes_val(Some_val(properties));
		zc.zc_nvlist_src_size = caml_string_length(Some_val(properties));
	}
	for (uint_t i = 0; i < Wosize_val(flags); i++) {
		zc.zc_cookie |= Import_flag_val(Field(flags, i));
	}
	zc.zc_nvlist_dst_size = 2 * zc.zc_nvlist_conf_size;
	zc.zc_nvlist_dst = (uint64_t)(uintptr_t)malloc(zc.zc_nvlist_dst_size);
	if (zc.zc_nvlist_dst == 0) {
		err = errno;
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
		CAMLreturn (ret);
	}
	caml_release_runtime_system();
	while ((err = zfs_ioctl(fd, ZFS_IOC_POOL_IMPORT, &zc)) == ENOMEM) {
		void *oldptr = (void *)zc.zc_nvlist_dst;
		void *newptr = realloc(oldptr, zc.zc_nvlist_dst_size);
		if (newptr == NULL) {
			err = errno;
			break;
		}
		zc.zc_nvlist_dst = (uint64_t)(uintptr_t)newptr;
	}
	caml_acquire_runtime_system();
	if (err) {
		void *p = (void *)zc.zc_nvlist_dst;
		free(p);
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		char *p = (char *)zc.zc_nvlist_dst;
		size_t len = (size_t)zc.zc_nvlist_dst_size;
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, caml_alloc_initialized_string(len, p));
		free(p);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_pool_import_bytecode(value *argv, int argn)
{
	return (caml_zfs_ioc_pool_import_native(argv[0], argv[1], argv[2],
	    argv[3], argv[4], argv[5]));
}

CAMLprim value
caml_zfs_ioc_pool_export(value handle, value name, value force,
    value hardforce, value log_msg)
{
	CAMLparam5 (handle, name, force, hardforce, log_msg);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_cookie = Bool_val(force);
	zc.zc_guid = Bool_val(hardforce);
	zc.zc_history = (uint64_t)(uintptr_t)String_val(log_msg);
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_POOL_EXPORT, &zc);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_pool_configs(value handle, value ns_gen)
{
	CAMLparam2 (handle, ns_gen);
	CAMLlocal3 (bytes, tuple, ret);
	zfs_cmd_t zc = {"\0"};
	uint64_t gen;
	int fd, err;

	fd = Devzfs_val(handle);
	gen = Int64_val(ns_gen);
	zc.zc_nvlist_dst_size = 256 * 1024;
	zc.zc_nvlist_dst = (uint64_t)(uintptr_t)malloc(zc.zc_nvlist_dst_size);
	if (zc.zc_nvlist_dst == 0) {
		err = errno;
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
		CAMLreturn (ret);
	}
	zc.zc_cookie = gen;
	caml_release_runtime_system();
	while ((err = zfs_ioctl(fd, ZFS_IOC_POOL_CONFIGS, &zc)) == ENOMEM) {
		void *oldptr = (void *)zc.zc_nvlist_dst;
		void *newptr = realloc(oldptr, zc.zc_nvlist_dst_size);
		if (newptr == NULL) {
			err = errno;
			break;
		}
		zc.zc_nvlist_dst = (uint64_t)(uintptr_t)newptr;
		zc.zc_cookie = gen;
	}
	caml_acquire_runtime_system();
	if (err == EEXIST) {
		void *p = (void *)zc.zc_nvlist_dst;
		free(p);
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_none);
	} else if (err) {
		void *p = (void *)zc.zc_nvlist_dst;
		free(p);
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		char *p = (char *)zc.zc_nvlist_dst;
		size_t len = (size_t)zc.zc_nvlist_dst_size;
		bytes = caml_alloc_initialized_string(len, p);
		free(p);
		tuple = caml_alloc_tuple(2);
		Store_field(tuple, 0, caml_copy_int64(zc.zc_cookie));
		Store_field(tuple, 1, bytes);
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, caml_alloc_some(tuple));
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_pool_stats(value handle, value name)
{
	CAMLparam2 (handle, name);
	CAMLlocal3 (bytes, tuple, ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		tuple = caml_alloc_tuple(2);
		Store_field(tuple, 0, Val_none);
		Store_field(tuple, 1, caml_unix_error_of_code(ENAMETOOLONG));
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, tuple);
		CAMLreturn (ret);
	}
	zc.zc_nvlist_dst_size = 1ULL << 16;
	zc.zc_nvlist_dst = (uint64_t)(uintptr_t)malloc(zc.zc_nvlist_dst_size);
	if (zc.zc_nvlist_dst == 0) {
		err = errno;
		tuple = caml_alloc_tuple(2);
		Store_field(tuple, 0, Val_none);
		Store_field(tuple, 1, caml_unix_error_of_code(err));
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, tuple);
		CAMLreturn (ret);
	}
	caml_release_runtime_system();
	while ((err = zfs_ioctl(fd, ZFS_IOC_POOL_STATS, &zc)) == ENOMEM) {
		void *oldptr = (void *)zc.zc_nvlist_dst;
		void *newptr = realloc(oldptr, zc.zc_nvlist_dst_size);
		if (newptr == NULL) {
			err = errno;
			break;
		}
		zc.zc_nvlist_dst = (uint64_t)(uintptr_t)newptr;
	}
	caml_acquire_runtime_system();
	if (err) {
		void *p = (void *)zc.zc_nvlist_dst;
		free(p);
		tuple = caml_alloc_tuple(2);
		Store_field(tuple, 0, Val_none);
		Store_field(tuple, 1, caml_unix_error_of_code(err));
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, tuple);
	} else if (zc.zc_cookie) {
		char *p = (char *)zc.zc_nvlist_dst;
		size_t len = (size_t)zc.zc_nvlist_dst_size;
		bytes = caml_alloc_initialized_string(len, p);
		free(p);
		tuple = caml_alloc_tuple(2);
		Store_field(tuple, 0, caml_alloc_some(bytes));
		Store_field(tuple, 1, caml_unix_error_of_code(zc.zc_cookie));
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, tuple);
	} else {
		char *p = (char *)zc.zc_nvlist_dst;
		size_t len = (size_t)zc.zc_nvlist_dst_size;
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, caml_alloc_initialized_string(len, p));
		free(p);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_pool_tryimport(value handle, value config)
{
	CAMLparam2 (handle, config);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	zc.zc_nvlist_conf = (uint64_t)(uintptr_t)Bytes_val(config);
	zc.zc_nvlist_conf_size = caml_string_length(config);
	zc.zc_nvlist_dst_size = MAX(CONFIG_BUF_MINSIZE,
	    zc.zc_nvlist_conf_size * 32);
	zc.zc_nvlist_dst = (uint64_t)(uintptr_t)malloc(zc.zc_nvlist_dst_size);
	if (zc.zc_nvlist_dst == 0) {
		err = errno;
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
		CAMLreturn (ret);
	}
	caml_release_runtime_system();
	while ((err = zfs_ioctl(fd, ZFS_IOC_POOL_TRYIMPORT, &zc)) == ENOMEM) {
		void *oldptr = (void *)zc.zc_nvlist_dst;
		void *newptr = realloc(oldptr, zc.zc_nvlist_dst_size);
		if (newptr == NULL) {
			err = errno;
			break;
		}
		zc.zc_nvlist_dst = (uint64_t)(uintptr_t)newptr;
	}
	caml_acquire_runtime_system();
	if (err) {
		void *p = (void *)zc.zc_nvlist_dst;
		free(p);
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		char *p = (char *)zc.zc_nvlist_dst;
		size_t len = (size_t)zc.zc_nvlist_dst_size;
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, caml_alloc_initialized_string(len, p));
		free(p);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_pool_scan(value handle, value name, value func, value cmd)
{
	CAMLparam4 (handle, name, func, cmd);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_cookie = Int_val(func);
	zc.zc_flags = Int_val(cmd);
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_POOL_SCAN, &zc);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_pool_freeze(value handle, value name)
{
	CAMLparam2 (handle, name);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_POOL_FREEZE, &zc);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_pool_upgrade(value handle, value name, value version)
{
	CAMLparam3 (handle, name, version);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_cookie = Int64_val(version);
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_POOL_UPGRADE, &zc);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_pool_get_history(value handle, value name, value offset)
{
	CAMLparam3 (handle, name, offset);
	CAMLlocal2 (bytes, ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_history_len = 128 * 1024;
	zc.zc_history = (uint64_t)(uintptr_t)malloc(zc.zc_history_len);
	if (zc.zc_history == 0) {
		err = errno;
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
		CAMLreturn (ret);
	}
	zc.zc_history_offset = Int64_val(offset);
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_POOL_GET_HISTORY, &zc);
	caml_acquire_runtime_system();
	if (err) {
		void *p = (void *)zc.zc_history;
		free(p);
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		char *p = (char *)zc.zc_history;
		size_t len = (size_t)zc.zc_history_len;
		ret = caml_alloc(1, 0);
		if (len == 0) {
			Store_field(ret, 0, Val_none);
		} else {
			bytes = caml_alloc_initialized_string(len, p);
			Store_field(ret, 0, caml_alloc_some(bytes));
		}
		free(p);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_vdev_add(value handle, value name, value config,
    value check_ashift)
{
	CAMLparam4 (handle, name, config, check_ashift);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_nvlist_conf = (uint64_t)(uintptr_t)Bytes_val(config);
	zc.zc_nvlist_conf_size = caml_string_length(config);
	zc.zc_flags = Bool_val(check_ashift);
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_VDEV_ADD, &zc);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_vdev_remove(value handle, value name, value guid)
{
	CAMLparam3 (handle, name, guid);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_guid = Int64_val(guid);
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_VDEV_REMOVE, &zc);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_vdev_remove_cancel(value handle, value name)
{
	CAMLparam2 (handle, name);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_cookie = 1;
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_VDEV_REMOVE, &zc);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_vdev_set_state(value handle, value name, value guid, value state,
    value flags)
{
	CAMLparam5 (handle, name, guid, state, flags);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_guid = Int64_val(guid);
	zc.zc_cookie = Int_val(state);
	zc.zc_obj = Int64_val(flags);
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_VDEV_SET_STATE, &zc);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_int(zc.zc_cookie));
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_vdev_attach_native(value handle, value name, value guid,
    value config, value replacing, value rebuild)
{
	CAMLparam5 (handle, name, guid, config, replacing);
	CAMLxparam1 (rebuild);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_guid = Int64_val(guid);
	zc.zc_nvlist_conf = (uint64_t)(uintptr_t)Bytes_val(config);
	zc.zc_nvlist_conf_size = caml_string_length(config);
	zc.zc_cookie = Bool_val(replacing);
	zc.zc_simple = Bool_val(rebuild);
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_VDEV_ATTACH, &zc);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_vdev_attach_bytecode(value *argv, int argn)
{
	return (caml_zfs_ioc_vdev_attach_native(argv[0], argv[1], argv[2],
	    argv[3], argv[4], argv[5]));
}

CAMLprim value
caml_zfs_ioc_vdev_detach(value handle, value name, value guid)
{
	CAMLparam3 (handle, name, guid);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_guid = Int64_val(guid);
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_VDEV_DETACH, &zc);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_vdev_setpath(value handle, value name, value guid, value path)
{
	CAMLparam4 (handle, name, guid, path);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_guid = Int64_val(guid);
	if (strlcpy(zc.zc_value, String_val(path), sizeof zc.zc_value)
	    >= sizeof zc.zc_value) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_VDEV_SETPATH, &zc);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_vdev_setfru(value handle, value name, value guid, value fru)
{
	CAMLparam4 (handle, name, guid, fru);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_guid = Int64_val(guid);
	if (strlcpy(zc.zc_value, String_val(name), sizeof zc.zc_value)
	    >= sizeof zc.zc_value) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_VDEV_SETFRU, &zc);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

static value
make_objset_stats(const dmu_objset_stats_t *stats)
{
	CAMLparam0 ();
	CAMLlocal1 (record);

	record = caml_alloc_tuple(8);
	Store_field(record, 0, caml_copy_int64(stats->dds_num_clones));
	Store_field(record, 1, caml_copy_int64(stats->dds_creation_txg));
	Store_field(record, 2, caml_copy_int64(stats->dds_guid));
	Store_field(record, 3, Val_int(stats->dds_type));
	Store_field(record, 4, Val_bool(stats->dds_is_snapshot));
	Store_field(record, 5, Val_bool(stats->dds_inconsistent));
	Store_field(record, 6, Val_bool(stats->dds_redacted));
	Store_field(record, 7, caml_copy_string(stats->dds_origin));
	CAMLreturn (record);
}

CAMLprim value
caml_zfs_ioc_objset_stats(value handle, value name, value simple)
{
	CAMLparam3 (handle, name, simple);
	CAMLlocal4 (bytes, record, tuple, ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_simple = Bool_val(simple);
	if (!zc.zc_simple) {
		zc.zc_nvlist_dst_size = 256 * 1024;
		zc.zc_nvlist_dst =
		    (uint64_t)(uintptr_t)malloc(zc.zc_nvlist_dst_size);
		if (zc.zc_nvlist_dst == 0) {
			err = errno;
			ret = caml_alloc(1, 1);
			Store_field(ret, 0, caml_unix_error_of_code(err));
			CAMLreturn (ret);
		}
	}
	caml_release_runtime_system();
	while ((err = zfs_ioctl(fd, ZFS_IOC_OBJSET_STATS, &zc)) == ENOMEM) {
		if (zc.zc_simple) {
			break;
		}
		void *oldptr = (void *)zc.zc_nvlist_dst;
		void *newptr = realloc(oldptr, zc.zc_nvlist_dst_size);
		if (newptr == NULL) {
			err = errno;
			break;
		}
		zc.zc_nvlist_dst = (uint64_t)(uintptr_t)newptr;
	}
	caml_acquire_runtime_system();
	if (err) {
		if (!zc.zc_simple) {
			void *p = (void *)zc.zc_nvlist_dst;
			free(p);
		}
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		record = make_objset_stats(&zc.zc_objset_stats);
		tuple = caml_alloc_tuple(2);
		Store_field(tuple, 0, record);
		if (zc.zc_simple) {
			Store_field(tuple, 1, Val_none);
		} else {
			char *p = (char *)zc.zc_nvlist_dst;
			size_t len = (size_t)zc.zc_nvlist_dst_size;
			bytes = caml_alloc_initialized_string(len, p);
			free(p);
			Store_field(tuple, 1, caml_alloc_some(bytes));
		}
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, tuple);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_objset_zplprops(value handle, value name)
{
	CAMLparam2 (handle, name);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_nvlist_dst_size = 256 * 1024;
	zc.zc_nvlist_dst = (uint64_t)(uintptr_t)malloc(zc.zc_nvlist_dst_size);
	if (zc.zc_nvlist_dst == 0) {
		err = errno;
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
		CAMLreturn (ret);
	}
	caml_release_runtime_system();
	while ((err = zfs_ioctl(fd, ZFS_IOC_OBJSET_ZPLPROPS, &zc)) == ENOMEM) {
		void *oldptr = (void *)zc.zc_nvlist_dst;
		void *newptr = realloc(oldptr, zc.zc_nvlist_dst_size);
		if (newptr == NULL) {
			err = errno;
			break;
		}
		zc.zc_nvlist_dst = (uint64_t)(uintptr_t)newptr;
	}
	caml_acquire_runtime_system();
	if (err) {
		void *p = (void *)zc.zc_nvlist_dst;
		free(p);
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		char *p = (char *)zc.zc_nvlist_dst;
		size_t len = (size_t)zc.zc_nvlist_dst_size;
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, caml_alloc_initialized_string(len, p));
		free(p);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_dataset_list_next(value handle, value name, value simple,
    value cookie)
{
	CAMLparam4 (handle, name, simple, cookie);
	CAMLlocal4 (bytes, record, tuple, ret);
	zfs_cmd_t zc = {"\0"};
	const char *saved_name;
	uint64_t saved_cookie;
	int fd, err;

	fd = Devzfs_val(handle);
	saved_name = String_val(name);
	if (strlcpy(zc.zc_name, saved_name, sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_simple = Bool_val(simple);
	zc.zc_cookie = saved_cookie = Int64_val(cookie);
	if (!zc.zc_simple) {
		zc.zc_nvlist_dst_size = 256 * 1024;
		zc.zc_nvlist_dst =
		    (uint64_t)(uintptr_t)malloc(zc.zc_nvlist_dst_size);
		if (zc.zc_nvlist_dst == 0) {
			err = errno;
			ret = caml_alloc(1, 1);
			Store_field(ret, 0, caml_unix_error_of_code(err));
			CAMLreturn (ret);
		}
	}
	caml_release_runtime_system();
	while ((err = zfs_ioctl(fd, ZFS_IOC_DATASET_LIST_NEXT, &zc)) == ENOMEM) {
		if (zc.zc_simple) {
			break;
		}
		void *oldptr = (void *)zc.zc_nvlist_dst;
		void *newptr = realloc(oldptr, zc.zc_nvlist_dst_size);
		if (newptr == NULL) {
			err = errno;
			break;
		}
		zc.zc_nvlist_dst = (uint64_t)(uintptr_t)newptr;
		(void) strcpy(zc.zc_name, saved_name);
		zc.zc_cookie = saved_cookie;
		zc.zc_objset_stats.dds_creation_txg = 0;
	}
	caml_acquire_runtime_system();
	if (err) {
		if (!zc.zc_simple) {
			void *p = (void *)zc.zc_nvlist_dst;
			free(p);
		}
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		record = make_objset_stats(&zc.zc_objset_stats);
		tuple = caml_alloc_tuple(4);
		Store_field(tuple, 0, caml_copy_string(zc.zc_name));
		Store_field(tuple, 1, record);
		if (zc.zc_simple) {
			Store_field(tuple, 2, Val_none);
		} else {
			char *p = (char *)zc.zc_nvlist_dst;
			size_t len = (size_t)zc.zc_nvlist_dst_size;
			bytes = caml_alloc_initialized_string(len, p);
			free(p);
			Store_field(tuple, 2, caml_alloc_some(bytes));
		}
		Store_field(tuple, 3, caml_copy_int64(zc.zc_cookie));
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, tuple);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_snapshot_list_next(value handle, value name, value simple,
    value cookie)
{
	CAMLparam4 (handle, name, simple, cookie);
	CAMLlocal4 (bytes, record, tuple, ret);
	zfs_cmd_t zc = {"\0"};
	const char *saved_name;
	uint64_t saved_cookie;
	int fd, err;

	fd = Devzfs_val(handle);
	saved_name = String_val(name);
	if (strlcpy(zc.zc_name, saved_name, sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_simple = Bool_val(simple);
	zc.zc_cookie = saved_cookie = Int64_val(cookie);
	if (!zc.zc_simple) {
		zc.zc_nvlist_dst_size = 256 * 1024;
		zc.zc_nvlist_dst =
		    (uint64_t)(uintptr_t)malloc(zc.zc_nvlist_dst_size);
		if (zc.zc_nvlist_dst == 0) {
			err = errno;
			ret = caml_alloc(1, 1);
			Store_field(ret, 0, caml_unix_error_of_code(err));
			CAMLreturn (ret);
		}
	}
	caml_release_runtime_system();
	while ((err = zfs_ioctl(fd, ZFS_IOC_SNAPSHOT_LIST_NEXT, &zc)) == ENOMEM) {
		if (zc.zc_simple) {
			break;
		}
		void *oldptr = (void *)zc.zc_nvlist_dst;
		void *newptr = realloc(oldptr, zc.zc_nvlist_dst_size);
		if (newptr == NULL) {
			err = errno;
			break;
		}
		zc.zc_nvlist_dst = (uint64_t)(uintptr_t)newptr;
		(void) strcpy(zc.zc_name, saved_name);
		zc.zc_cookie = saved_cookie;
		zc.zc_objset_stats.dds_creation_txg = 0;
	}
	caml_acquire_runtime_system();
	if (err) {
		if (!zc.zc_simple) {
			void *p = (void *)zc.zc_nvlist_dst;
			free(p);
		}
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		record = make_objset_stats(&zc.zc_objset_stats);
		tuple = caml_alloc_tuple(4);
		Store_field(tuple, 0, caml_copy_string(zc.zc_name));
		Store_field(tuple, 1, record);
		if (zc.zc_simple) {
			Store_field(tuple, 2, Val_none);
		} else {
			char *p = (char *)zc.zc_nvlist_dst;
			size_t len = (size_t)zc.zc_nvlist_dst_size;
			bytes = caml_alloc_initialized_string(len, p);
			free(p);
			Store_field(tuple, 2, caml_alloc_some(bytes));
		}
		Store_field(tuple, 3, caml_copy_int64(zc.zc_cookie));
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, tuple);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_set_prop(value handle, value name, value props)
{
	CAMLparam3 (handle, name, props);
	CAMLlocal3 (bytes, tuple, ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		tuple = caml_alloc_tuple(2);
		Store_field(tuple, 0, Val_none);
		Store_field(tuple, 1, caml_unix_error_of_code(ENAMETOOLONG));
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, tuple);
		CAMLreturn (ret);
	}
	zc.zc_nvlist_src = (uint64_t)(uintptr_t)Bytes_val(props);
	zc.zc_nvlist_src_size = caml_string_length(props);
	zc.zc_nvlist_dst_size = 256 * 1024;
	zc.zc_nvlist_dst = (uint64_t)(uintptr_t)malloc(zc.zc_nvlist_dst_size);
	if (zc.zc_nvlist_dst == 0) {
		err = errno;
		tuple = caml_alloc_tuple(2);
		Store_field(tuple, 0, Val_none);
		Store_field(tuple, 1, caml_unix_error_of_code(err));
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, tuple);
		CAMLreturn (ret);
	}
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_SET_PROP, &zc);
	caml_acquire_runtime_system();
	if (err) {
		tuple = caml_alloc_tuple(2);
		if (zc.zc_nvlist_dst_filled && err != ENOMEM) {
			char *p = (char *)zc.zc_nvlist_dst;
			size_t len = (size_t)zc.zc_nvlist_dst_size;
			bytes = caml_alloc_initialized_string(len, p);
			free(p);
			Store_field(tuple, 0, caml_alloc_some(bytes));
		} else {
			void *p = (void *)zc.zc_nvlist_dst;
			free(p);
			Store_field(tuple, 0, Val_none);
		}
		Store_field(tuple, 1, caml_unix_error_of_code(err));
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, tuple);
	} else {
		void *p = (void *)zc.zc_nvlist_dst;
		free(p);
		ret = caml_alloc(0, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_create(value handle, value name, value args)
{
	CAMLparam3 (handle, name, args);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_nvlist_src = (uint64_t)(uintptr_t)Bytes_val(args);
	zc.zc_nvlist_src_size = caml_string_length(args);
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_CREATE, &zc);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_destroy(value handle, value name, value defer)
{
	CAMLparam3 (handle, name, defer);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_defer_destroy = Bool_val(defer);
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_DESTROY, &zc);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_rollback(value handle, value name, value args_option)
{
	CAMLparam3 (handle, name, args_option);
	CAMLlocal2 (args, ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
	}
	if (Is_some(args_option)) {
		args = Some_val(args_option);
		zc.zc_nvlist_src = (uint64_t)(uintptr_t)Bytes_val(args);
		zc.zc_nvlist_src_size = caml_string_length(args);
	}
	zc.zc_nvlist_dst_size = 128 * 1024;
	zc.zc_nvlist_dst = (uint64_t)(uintptr_t)malloc(zc.zc_nvlist_dst_size);
	if (zc.zc_nvlist_dst == 0) {
		err = errno;
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
		CAMLreturn (ret);
	}
	caml_release_runtime_system();
	while ((err = zfs_ioctl(fd, ZFS_IOC_ROLLBACK, &zc)) == ENOMEM) {
		void *oldptr = (void *)zc.zc_nvlist_dst;
		void *newptr = realloc(oldptr, zc.zc_nvlist_dst_size);
		if (newptr == NULL) {
			err = errno;
			break;
		}
		zc.zc_nvlist_dst = (uint64_t)(uintptr_t)newptr;
	}
	caml_acquire_runtime_system();
	if (err) {
		void *p = (void *)zc.zc_nvlist_dst;
		free(p);
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		char *p = (char *)zc.zc_nvlist_dst;
		size_t len = (size_t)zc.zc_nvlist_dst_size;
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, caml_alloc_initialized_string(len, p));
		free(p);
	}
	CAMLreturn (ret);
}

/* Convert rename_flag variant into flags bitset */
#define Rename_flag_val(v) (1ULL << Int_val(v))

CAMLprim value
caml_zfs_ioc_rename(value handle, value oldname, value newname, value flags)
{
	CAMLparam4 (handle, oldname, newname, flags);
	CAMLlocal3 (failed, tuple, ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(oldname), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		tuple = caml_alloc_tuple(2);
		Store_field(tuple, 0, Val_none);
		Store_field(tuple, 1, caml_unix_error_of_code(ENAMETOOLONG));
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, tuple);
		CAMLreturn (ret);
	}
	if (strlcpy(zc.zc_value, String_val(newname), sizeof zc.zc_value)
	    >= sizeof zc.zc_value) {
		tuple = caml_alloc_tuple(2);
		Store_field(tuple, 0, Val_none);
		Store_field(tuple, 1, caml_unix_error_of_code(ENAMETOOLONG));
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, tuple);
		CAMLreturn (ret);
	}
	for (uint_t i = 0; i < Wosize_val(flags); i++) {
		zc.zc_cookie |= Rename_flag_val(Field(flags, i));
	}
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_RENAME, &zc);
	caml_acquire_runtime_system();
	if (err) {
		failed = caml_copy_string(zc.zc_name);
		tuple = caml_alloc_tuple(2);
		Store_field(tuple, 0, caml_alloc_some(failed));
		Store_field(tuple, 1, caml_unix_error_of_code(err));
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, tuple);
	} else {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

/* Convert flags bitset to array */
static value
make_flag_array(const int *flags, uint_t len, uint_t bits)
{
	CAMLparam0 ();
	CAMLlocal1 (v);
	uint_t n;

	n = 0;
	for (uint_t i = 0; i < len; i++) {
		if (bits & flags[i]) {
			n++;
		}
	}
	if (n == 0) {
		CAMLreturn (Atom(0));
	}
	v = caml_alloc(n, 0);
	n = 0;
	for (uint_t i = 0; i < len; i++) {
		if (bits & flags[i]) {
			Store_field(v, n++, Int_val(i));
		}
	}
	CAMLreturn (v);
}

static const int zprop_errflags[] = {
	ZPROP_ERR_NOCLEAR,
	ZPROP_ERR_NORESTORE
};

CAMLprim value
caml_zfs_ioc_recv_native(value handle, value name, value props_opt,
    value override_opt, value snapname, value origin_opt, value desc,
    value begin_rec, value force)
{
	CAMLparam5 (handle, name, props_opt, override_opt, snapname);
	CAMLxparam4 (origin_opt, desc, begin_rec, force);
	CAMLlocal5 (string, bytes, errflags, tuple, ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	if (strlcpy(zc.zc_value, String_val(snapname), sizeof zc.zc_value)
	    >= sizeof zc.zc_value) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	if (Is_some(origin_opt)) {
		string = Some_val(origin_opt);
		if (strlcpy(zc.zc_string, String_val(string),
		    sizeof zc.zc_string) >= sizeof zc.zc_string) {
			ret = caml_alloc(1, 1);
			Store_field(ret, 0,
			    caml_unix_error_of_code(ENAMETOOLONG));
			CAMLreturn (ret);
		}
	}
	if (Is_some(props_opt)) {
		bytes = Some_val(props_opt);
		zc.zc_nvlist_src = (uint64_t)(uintptr_t)Bytes_val(bytes);
		zc.zc_nvlist_src_size = caml_string_length(bytes);
	}
	if (Is_some(override_opt)) {
		bytes = Some_val(override_opt);
		zc.zc_nvlist_conf = (uint64_t)(uintptr_t)Bytes_val(bytes);
		zc.zc_nvlist_conf_size = caml_string_length(bytes);
	}
	zc.zc_cookie = Int_val(desc);
	if (caml_string_length(begin_rec) != sizeof zc.zc_begin_record) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(EINVAL));
		CAMLreturn (ret);
	}
	(void)memcpy(&zc.zc_begin_record, Bytes_val(begin_rec),
	    sizeof zc.zc_begin_record);
	zc.zc_guid = Bool_val(force);
	zc.zc_nvlist_dst_size = 256 * 1024;
	zc.zc_nvlist_dst = (uint64_t)(uintptr_t)malloc(zc.zc_nvlist_dst_size);
	if (zc.zc_nvlist_dst == 0) {
		err = errno;
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
		CAMLreturn (ret);
	}
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_RECV, &zc);
	caml_acquire_runtime_system();
	if (err) {
		void *p = (void *)zc.zc_nvlist_dst;
		free(p);
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		char *p = (char *)zc.zc_nvlist_dst;
		size_t len = (size_t)zc.zc_nvlist_dst_size;
		bytes = caml_alloc_initialized_string(len, p);
		free(p);
		errflags = make_flag_array(zprop_errflags,
		    nitems(zprop_errflags), zc.zc_obj);
		tuple = caml_alloc_tuple(3);
		Store_field(tuple, 0, caml_copy_int64(zc.zc_cookie));
		Store_field(tuple, 1, errflags);
		Store_field(tuple, 2, bytes);
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, tuple);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_recv_bytecode(value *argv, int argn)
{
	return (caml_zfs_ioc_recv_native(argv[0], argv[1], argv[2], argv[3],
	    argv[4], argv[5], argv[6], argv[7], argv[8]));
}

/* Convert lzc_send_flag variant into LZC_SEND_* flag */
#define Lzc_send_flag_val(v) (1 << Int_val(v))

CAMLprim value
caml_zfs_ioc_send_native(value handle, value name, value desc_opt,
    value fromorigin, value sendobj, value fromobj_opt, value estimate,
    value flags)
{
	CAMLparam5 (handle, name, desc_opt, fromorigin, sendobj);
	CAMLxparam3 (fromobj_opt, estimate, flags);
	CAMLlocal2 (val, ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	if (Is_some(desc_opt)) {
		if (Bool_val(estimate)) {
			ret = caml_alloc(1, 1);
			Store_field(ret, 0, caml_unix_error_of_code(EINVAL));
			CAMLreturn (ret);
		}
		val = Some_val(desc_opt);
		zc.zc_cookie = Int_val(val);
	} else {
		if (!Bool_val(estimate)) {
			ret = caml_alloc(1, 1);
			Store_field(ret, 0, caml_unix_error_of_code(EINVAL));
			CAMLreturn (ret);
		}
	}
	zc.zc_obj = Bool_val(fromorigin);
	zc.zc_sendobj = Int64_val(sendobj);
	if (Is_some(fromobj_opt)) {
		val = Some_val(fromobj_opt);
		zc.zc_fromobj = Int64_val(val);
	}
	zc.zc_guid = Bool_val(estimate);
	for (uint_t i = 0; i < Wosize_val(flags); i++) {
		zc.zc_flags |= Lzc_send_flag_val(Field(flags, i));
	}
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_SEND, &zc);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		ret = caml_alloc(1, 0);
		if (Bool_val(estimate)) {
			val = caml_copy_int64(zc.zc_objset_type);
			Store_field(ret, 0, caml_alloc_some(val));
		} else {
			Store_field(ret, 0, Val_none);
		}
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_send_bytecode(value *argv, int argn)
{
	return (caml_zfs_ioc_send_native(argv[0], argv[1], argv[2], argv[3],
	    argv[4], argv[5], argv[6], argv[7]));
}

static int
fill_zinject_record(value record, zinject_record_t *r)
{
	CAMLparam1 (record);

	r->zi_objset = Int64_val(Field(record, 0));
	r->zi_object = Int64_val(Field(record, 1));
	r->zi_start = Int64_val(Field(record, 2));
	r->zi_end = Int64_val(Field(record, 3));
	r->zi_guid = Int64_val(Field(record, 4));
	r->zi_level = Int32_val(Field(record, 5));
	r->zi_error = Int32_val(Field(record, 6));
	r->zi_type = Int64_val(Field(record, 7));
	r->zi_freq = Int32_val(Field(record, 8));
	r->zi_failfast = Int32_val(Field(record, 9));
	if (strlcpy(r->zi_func, String_val(Field(record, 10)),
	    sizeof r->zi_func) >= sizeof r->zi_func) {
		CAMLreturnT (int, ENAMETOOLONG);
	}
	r->zi_iotype = Int32_val(Field(record, 11));
	r->zi_duration = Int32_val(Field(record, 12));
	r->zi_timer = Int64_val(Field(record, 13));
	r->zi_nlanes = Int64_val(Field(record, 14));
	r->zi_cmd = Int32_val(Field(record, 15));
	r->zi_dvas = Int32_val(Field(record, 16));
	CAMLreturnT (int, 0);
}

CAMLprim value
caml_zfs_ioc_inject_fault(value handle, value name, value record, value flags)
{
	CAMLparam4 (handle, name, record, flags);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	err = fill_zinject_record(record, &zc.zc_inject_record);
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
		CAMLreturn (ret);
	}
	zc.zc_guid = Int_val(flags);
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_INJECT_FAULT, &zc);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, caml_copy_int64(zc.zc_guid));
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_clear_fault(value handle, value guid)
{
	CAMLparam2 (handle, guid);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	zc.zc_guid = Int64_val(guid);
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_CLEAR_FAULT, &zc);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

static value
make_zinject_record(const zinject_record_t *zi)
{
	CAMLparam0 ();
	CAMLlocal1 (record);

	record = caml_alloc_tuple(17);
	Store_field(record, 0, caml_copy_int64(zi->zi_objset));
	Store_field(record, 1, caml_copy_int64(zi->zi_object));
	Store_field(record, 2, caml_copy_int64(zi->zi_start));
	Store_field(record, 3, caml_copy_int64(zi->zi_end));
	Store_field(record, 4, caml_copy_int64(zi->zi_guid));
	Store_field(record, 5, caml_copy_int32(zi->zi_level));
	Store_field(record, 6, caml_copy_int32(zi->zi_error));
	Store_field(record, 7, caml_copy_int64(zi->zi_type));
	Store_field(record, 8, caml_copy_int32(zi->zi_freq));
	Store_field(record, 9, caml_copy_int32(zi->zi_failfast));
	Store_field(record, 10, caml_copy_string(zi->zi_func));
	Store_field(record, 11, caml_copy_int32(zi->zi_iotype));
	Store_field(record, 12, caml_copy_int32(zi->zi_duration));
	Store_field(record, 13, caml_copy_int64(zi->zi_timer));
	Store_field(record, 14, caml_copy_int64(zi->zi_nlanes));
	Store_field(record, 15, caml_copy_int32(zi->zi_cmd));
	Store_field(record, 16, caml_copy_int32(zi->zi_dvas));
	CAMLreturn (record);
}

CAMLprim value
caml_zfs_ioc_inject_list_next(value handle, value guid)
{
	CAMLparam2 (handle, guid);
	CAMLlocal2 (tuple, ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	zc.zc_guid = Int64_val(guid);
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_INJECT_LIST_NEXT, &zc);
	caml_acquire_runtime_system();
	if (err == ENOENT) {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_none);
	} else if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		tuple = caml_alloc_tuple(3);
		Store_field(tuple, 0, caml_copy_int64(zc.zc_guid));
		Store_field(tuple, 1, caml_copy_string(zc.zc_name));
		Store_field(tuple, 2,
		    make_zinject_record(&zc.zc_inject_record));
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, caml_alloc_some(tuple));
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_error_log(value handle, value name)
{
	CAMLparam2 (handle, name);
	CAMLlocal3 (array, tuple, ret);
	zfs_cmd_t zc = {"\0"};
	zbookmark_phys_t *buf;
	uint64_t buflen;
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	buflen = 10000;
	buf = malloc(buflen * sizeof (zbookmark_phys_t));
	if (buf == NULL) {
		err = errno;
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
		CAMLreturn (ret);
	}
	zc.zc_nvlist_dst = (uint64_t)(uintptr_t)buf;
	zc.zc_nvlist_dst_size = buflen;
	caml_release_runtime_system();
	while ((err = zfs_ioctl(fd, ZFS_IOC_ERROR_LOG, &zc)) == ENOMEM) {
		buflen *= 2;
		void *newptr = realloc(buf, buflen * sizeof (zbookmark_phys_t));
		if (newptr == NULL) {
			err = errno;
			break;
		}
		buf = newptr;
		zc.zc_nvlist_dst = (uint64_t)(uintptr_t)buf;
		zc.zc_nvlist_dst_size = buflen;
	}
	caml_acquire_runtime_system();
	if (err) {
		free(buf);
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		zbookmark_phys_t *bookmarks = buf + zc.zc_nvlist_dst_size;
		size_t nbookmarks = buflen - zc.zc_nvlist_dst_size;
		if (nbookmarks == 0) {
			array = Atom(0);
		} else {
			array = caml_alloc_tuple(nbookmarks);
			for (uint_t i = 0; i < nbookmarks; i++) {
				zbookmark_phys_t *zb = bookmarks + i;
				tuple = caml_alloc_tuple(2);
				Store_field(tuple, 0,
				    caml_copy_int64(zb->zb_objset));
				Store_field(tuple, 1,
				    caml_copy_int64(zb->zb_object));
				Store_field(array, i, tuple);
			}
		}
		free(buf);
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, array);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_clear(value handle, value name, value guid_opt, value rewind_opt)
{
	CAMLparam4 (handle, name, guid_opt, rewind_opt);
	CAMLlocal4 (guid, rewind, bytes, ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	if (Is_some(guid_opt)) {
		guid = Some_val(guid_opt);
		zc.zc_guid = Int64_val(guid);
	}
	if (Is_some(rewind_opt)) {
		rewind = Some_val(rewind_opt);
		zc.zc_nvlist_src = (uint64_t)(uintptr_t)Bytes_val(rewind);
		zc.zc_nvlist_src_size = caml_string_length(rewind);
		zc.zc_nvlist_dst_size = 256 * 1024;
		zc.zc_nvlist_dst =
		    (uint64_t)(uintptr_t)malloc(zc.zc_nvlist_dst_size);
		if (zc.zc_nvlist_dst == 0) {
			err = errno;
			ret = caml_alloc(1, 1);
			Store_field(ret, 0, caml_unix_error_of_code(err));
			CAMLreturn (ret);
		}
	} else {
		zc.zc_cookie = ZPOOL_NO_REWIND;
	}
	caml_release_runtime_system();
	while ((err = zfs_ioctl(fd, ZFS_IOC_CLEAR, &zc)) == ENOMEM) {
		if (zc.zc_cookie & ZPOOL_NO_REWIND) {
			break;
		}
		void *oldptr = (void *)zc.zc_nvlist_dst;
		void *newptr = realloc(oldptr, zc.zc_nvlist_dst_size);
		if (newptr == NULL) {
			err = errno;
			break;
		}
		zc.zc_nvlist_dst = (uint64_t)(uintptr_t)newptr;
	}
	caml_acquire_runtime_system();
	if (err) {
		if (zc.zc_nvlist_dst) {
			void *p = (void *)zc.zc_nvlist_dst;
			free(p);
		}
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		ret = caml_alloc(1, 0);
		if (zc.zc_nvlist_dst) {
			char *p = (char *)zc.zc_nvlist_dst;
			size_t len = (size_t)zc.zc_nvlist_dst_size;
			bytes = caml_alloc_initialized_string(len, p);
			free(p);
			Store_field(ret, 0, caml_alloc_some(bytes));
		} else {
			Store_field(ret, 0, Val_none);
		}
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_promote(value handle, value name)
{
	CAMLparam2 (handle, name);
	CAMLlocal3 (snapname, tuple, ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		tuple = caml_alloc_tuple(2);
		Store_field(tuple, 0, Val_none);
		Store_field(tuple, 1, caml_unix_error_of_code(ENAMETOOLONG));
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, tuple);
		CAMLreturn (ret);
	}
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_PROMOTE, &zc);
	caml_acquire_runtime_system();
	if (err) {
		tuple = caml_alloc_tuple(2);
		if (err == EEXIST) {
			snapname = caml_copy_string(zc.zc_string);
			Store_field(tuple, 0, caml_alloc_some(snapname));
		} else {
			Store_field(tuple, 0, Val_none);
		}
		Store_field(tuple, 1, caml_unix_error_of_code(err));
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, tuple);
	} else {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_snapshot(value handle, value name, value args)
{
	CAMLparam3 (handle, name, args);
	CAMLlocal3 (bytes, tuple, ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		tuple = caml_alloc_tuple(2);
		Store_field(tuple, 0, Val_none);
		Store_field(tuple, 1, caml_unix_error_of_code(ENAMETOOLONG));
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, tuple);
		CAMLreturn (ret);
	}
	zc.zc_nvlist_src = (uint64_t)(uintptr_t)Bytes_val(args);
	zc.zc_nvlist_src_size = caml_string_length(args);
	zc.zc_nvlist_dst_size = MAX(zc.zc_nvlist_src_size * 2, 128 * 1024);
	zc.zc_nvlist_dst = (uint64_t)(uintptr_t)malloc(zc.zc_nvlist_dst_size);
	if (zc.zc_nvlist_dst == 0) {
		err = errno;
		tuple = caml_alloc_tuple(2);
		Store_field(tuple, 0, Val_none);
		Store_field(tuple, 1, caml_unix_error_of_code(err));
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, tuple);
		CAMLreturn (ret);
	}
	caml_release_runtime_system();
	while ((err = zfs_ioctl(fd, ZFS_IOC_SNAPSHOT, &zc)) == ENOMEM) {
		void *oldptr = (void *)zc.zc_nvlist_dst;
		void *newptr = realloc(oldptr, zc.zc_nvlist_dst_size);
		if (newptr == NULL) {
			err = errno;
			break;
		}
		zc.zc_nvlist_dst = (uint64_t)(uintptr_t)newptr;
	}
	caml_acquire_runtime_system();
	if (err) {
		tuple = caml_alloc_tuple(2);
		if (zc.zc_nvlist_dst_filled && err != ENOMEM) {
			char *p = (char *)zc.zc_nvlist_dst;
			size_t len = (size_t)zc.zc_nvlist_dst_size;
			bytes = caml_alloc_initialized_string(len, p);
			free(p);
			Store_field(tuple, 0, caml_alloc_some(bytes));
		} else {
			void *p = (void *)zc.zc_nvlist_dst;
			free(p);
			Store_field(tuple, 0, Val_none);
		}
		Store_field(tuple, 1, caml_unix_error_of_code(err));
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, tuple);
	} else {
		void *p = (void *)zc.zc_nvlist_dst;
		free(p);
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_dsobj_to_dsname(value handle, value name, value dsobj)
{
	CAMLparam3 (handle, name, dsobj);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_obj = Int64_val(dsobj);
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_DSOBJ_TO_DSNAME, &zc);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, caml_copy_string(zc.zc_value));
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_obj_to_path(value handle, value name, value obj)
{
	CAMLparam3 (handle, name, obj);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0 , caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_obj = Int64_val(obj);
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_OBJ_TO_PATH, &zc);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, caml_copy_string(zc.zc_value));
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_pool_set_props(value handle, value name, value props)
{
	CAMLparam3 (handle, name, props);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_nvlist_src = (uint64_t)(uintptr_t)Bytes_val(props);
	zc.zc_nvlist_src_size = caml_string_length(props);
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_POOL_SET_PROPS, &zc);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_pool_get_props(value handle, value name)
{
	CAMLparam2 (handle, name);
	CAMLlocal2 (bytes, ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_nvlist_dst_size = 256 * 1024;
	zc.zc_nvlist_dst = (uint64_t)(uintptr_t)malloc(zc.zc_nvlist_dst_size);
	if (zc.zc_nvlist_dst == 0) {
		err = errno;
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
		CAMLreturn (ret);
	}
	caml_release_runtime_system();
	while ((err = zfs_ioctl(fd, ZFS_IOC_POOL_GET_PROPS, &zc)) == ENOMEM) {
		void *oldptr = (void *)zc.zc_nvlist_dst;
		void *newptr = realloc(oldptr, zc.zc_nvlist_dst_size);
		if (newptr == NULL) {
			err = errno;
			break;
		}
		zc.zc_nvlist_dst = (uint64_t)(uintptr_t)newptr;
	}
	caml_acquire_runtime_system();
	if (err) {
		void *p = (void *)zc.zc_nvlist_dst;
		free(p);
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		char *p = (char *)zc.zc_nvlist_dst;
		size_t len = (size_t)zc.zc_nvlist_dst_size;
		bytes = caml_alloc_initialized_string(len, p);
		free(p);
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, bytes);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_set_fsacl(value handle, value name, value un, value acl)
{
	CAMLparam4 (handle, name, un, acl);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_perm_action = Bool_val(un);
	zc.zc_nvlist_src = (uint64_t)(uintptr_t)Bytes_val(acl);
	zc.zc_nvlist_src_size = caml_string_length(acl);
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_SET_FSACL, &zc);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_get_fsacl(value handle, value name)
{
	CAMLparam2 (handle, name);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_nvlist_dst_size = 2048;
	zc.zc_nvlist_dst = (uint64_t)(uintptr_t)malloc(zc.zc_nvlist_dst_size);
	if (zc.zc_nvlist_dst == 0) {
		err = errno;
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
		CAMLreturn (ret);
	}
	caml_release_runtime_system();
	while ((err = zfs_ioctl(fd, ZFS_IOC_GET_FSACL, &zc)) == ENOMEM) {
		void *oldptr = (void *)zc.zc_nvlist_dst;
		void *newptr = realloc(oldptr, zc.zc_nvlist_dst_size);
		if (newptr == NULL) {
			err = errno;
			break;
		}
		zc.zc_nvlist_dst = (uint64_t)(uintptr_t)newptr;
	}
	caml_acquire_runtime_system();
	if (err) {
		void *p = (void *)zc.zc_nvlist_dst;
		free(p);
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		char *p = (char *)zc.zc_nvlist_dst;
		size_t len = (size_t)zc.zc_nvlist_dst_size;
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, caml_alloc_initialized_string(len, p));
		free(p);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_inherit_prop(value handle, value name, value prop, value received)
{
	CAMLparam4 (handle, name, prop, received);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	if (strlcpy(zc.zc_value, String_val(prop), sizeof zc.zc_value)
	    >= sizeof zc.zc_value) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_cookie = Bool_val(received);
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_INHERIT_PROP, &zc);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_userspace_one(value handle, value name, value prop, value domain,
    value id)
{
	CAMLparam5 (handle, name, prop, domain, id);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_objset_type = Int_val(prop);
	if (strlcpy(zc.zc_value, String_val(domain), sizeof zc.zc_value)
	    >= sizeof zc.zc_value) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_guid = Int64_val(id);
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_USERSPACE_ONE, &zc);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, caml_copy_int64(zc.zc_cookie));
	}
	CAMLreturn (ret);
}

static value
make_useracct(zfs_useracct_t *zu)
{
	CAMLparam0 ();
	CAMLlocal1 (record);

	record = caml_alloc_tuple(3);
	Store_field(record, 0, caml_copy_string(zu->zu_domain));
	Store_field(record, 1, Val_int(zu->zu_rid));
	Store_field(record, 2, caml_copy_int64(zu->zu_space));
	CAMLreturn (record);
}

CAMLprim value
caml_zfs_ioc_userspace_many(value handle, value name, value prop, value count,
    value cursor)
{
	CAMLparam5 (handle, name, prop, count, cursor);
	CAMLlocal3 (array, tuple, ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_objset_type = Int_val(prop);
	zc.zc_cookie = Int64_val(cursor);
	zc.zc_nvlist_dst_size = Int_val(count) * sizeof (zfs_useracct_t);
	zc.zc_nvlist_dst = (uint64_t)(uintptr_t)malloc(zc.zc_nvlist_dst_size);
	if (zc.zc_nvlist_dst == 0) {
		err = errno;
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
		CAMLreturn (ret);
	}
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_USERSPACE_MANY, &zc);
	caml_acquire_runtime_system();
	if (err) {
		void *p = (void *)zc.zc_nvlist_dst;
		free(p);
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		zfs_useracct_t *zu = (zfs_useracct_t *)zc.zc_nvlist_dst;
		uint_t len = zc.zc_nvlist_dst_size / sizeof (zfs_useracct_t);
		if (len == 0) {
			array = Atom(0);
		} else {
			array = caml_alloc_tuple(len);
			for (uint_t i = 0; i < len; i++) {
				Store_field(array, i, make_useracct(&zu[i]));
			}
		}
		free(zu);
		tuple = caml_alloc_tuple(2);
		Store_field(tuple, 0, caml_copy_int64(zc.zc_cookie));
		Store_field(tuple, 1, array);
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, tuple);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_userspace_upgrade(value handle, value name)
{
	CAMLparam2 (handle, name);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_USERSPACE_UPGRADE, &zc);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_hold(value handle, value name, value args)
{
	CAMLparam3 (handle, name, args);
	CAMLlocal3 (bytes, tuple, ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		tuple = caml_alloc_tuple(2);
		Store_field(tuple, 0, Val_none);
		Store_field(tuple, 1, caml_unix_error_of_code(ENAMETOOLONG));
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, tuple);
		CAMLreturn (ret);
	}
	zc.zc_nvlist_src = (uint64_t)(uintptr_t)Bytes_val(args);
	zc.zc_nvlist_src_size = caml_string_length(args);
	zc.zc_nvlist_dst_size = MAX(2 * zc.zc_nvlist_src_size, 128 * 1024);
	zc.zc_nvlist_dst = (uint64_t)(uintptr_t)malloc(zc.zc_nvlist_dst_size);
	if (zc.zc_nvlist_dst == 0) {
		err = errno;
		tuple = caml_alloc_tuple(2);
		Store_field(tuple, 0, Val_none);
		Store_field(tuple, 1, caml_unix_error_of_code(err));
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, tuple);
		CAMLreturn (ret);
	}
	caml_release_runtime_system();
	while ((err = zfs_ioctl(fd, ZFS_IOC_HOLD, &zc)) == ENOMEM) {
		void *oldptr = (void *)zc.zc_nvlist_dst;
		void *newptr = realloc(oldptr, zc.zc_nvlist_dst_size);
		if (newptr == NULL) {
			err = errno;
			break;
		}
		zc.zc_nvlist_dst = (uint64_t)(uintptr_t)newptr;
	}
	caml_acquire_runtime_system();
	if (err) {
		tuple = caml_alloc_tuple(2);
		if (zc.zc_nvlist_dst_filled && err != ENOMEM) {
			char *p = (char *)zc.zc_nvlist_dst;
			size_t len = (size_t)zc.zc_nvlist_dst_size;
			bytes = caml_alloc_initialized_string(len, p);
			free(p);
			Store_field(tuple, 0, caml_alloc_some(bytes));
		} else {
			void *p = (void *)zc.zc_nvlist_dst;
			free(p);
			Store_field(tuple, 0, Val_none);
		}
		Store_field(tuple, 1, caml_unix_error_of_code(err));
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, tuple);
	} else {
		void *p = (void *)zc.zc_nvlist_dst;
		free(p);
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_release(value handle, value name, value args)
{
	CAMLparam3 (handle, name, args);
	CAMLlocal3 (bytes, tuple, ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		tuple = caml_alloc_tuple(2);
		Store_field(tuple, 0, Val_none);
		Store_field(tuple, 1, caml_unix_error_of_code(ENAMETOOLONG));
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, tuple);
		CAMLreturn (ret);
	}
	zc.zc_nvlist_src = (uint64_t)(uintptr_t)Bytes_val(args);
	zc.zc_nvlist_src_size = caml_string_length(args);
	zc.zc_nvlist_dst_size = MAX(2 * zc.zc_nvlist_src_size, 128 * 1024);
	zc.zc_nvlist_dst = (uint64_t)(uintptr_t)malloc(zc.zc_nvlist_dst_size);
	if (zc.zc_nvlist_dst == 0) {
		err = errno;
		tuple = caml_alloc_tuple(2);
		Store_field(tuple, 0, Val_none);
		Store_field(tuple, 1, caml_unix_error_of_code(err));
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, tuple);
		CAMLreturn (ret);
	}
	caml_release_runtime_system();
	while ((err = zfs_ioctl(fd, ZFS_IOC_RELEASE, &zc)) == ENOMEM) {
		void *oldptr = (void *)zc.zc_nvlist_dst;
		void *newptr = realloc(oldptr, zc.zc_nvlist_dst_size);
		if (newptr == NULL) {
			err = errno;
			break;
		}
		zc.zc_nvlist_dst = (uint64_t)(uintptr_t)newptr;
	}
	caml_acquire_runtime_system();
	if (err) {
		tuple = caml_alloc_tuple(2);
		if (zc.zc_nvlist_dst_filled && err != ENOMEM) {
			char *p = (char *)zc.zc_nvlist_dst;
			size_t len = (size_t)zc.zc_nvlist_dst_size;
			bytes = caml_alloc_initialized_string(len, p);
			free(p);
			Store_field(tuple, 0, caml_alloc_some(bytes));
		} else {
			void *p = (void *)zc.zc_nvlist_dst;
			free(p);
			Store_field(tuple, 0, Val_none);
		}
		Store_field(tuple, 1, caml_unix_error_of_code(err));
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, tuple);
	} else {
		void *p = (void *)zc.zc_nvlist_dst;
		free(p);
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_get_holds(value handle, value name)
{
	CAMLparam2 (handle, name);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_nvlist_dst_size = 128 * 1024;
	zc.zc_nvlist_dst = (uint64_t)(uintptr_t)malloc(zc.zc_nvlist_dst_size);
	if (zc.zc_nvlist_dst == 0) {
		err = errno;
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
		CAMLreturn (ret);
	}
	caml_release_runtime_system();
	while ((err = zfs_ioctl(fd, ZFS_IOC_GET_HOLDS, &zc)) == ENOMEM) {
		void *oldptr = (void *)zc.zc_nvlist_dst;
		void *newptr = realloc(oldptr, zc.zc_nvlist_dst_size);
		if (newptr == NULL) {
			err = errno;
			break;
		}
		zc.zc_nvlist_dst = (uint64_t)(uintptr_t)newptr;
	}
	caml_acquire_runtime_system();
	if (err) {
		void *p = (void *)zc.zc_nvlist_dst;
		free(p);
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		char *p = (char *)zc.zc_nvlist_dst;
		size_t len = (size_t)zc.zc_nvlist_dst_size;
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, caml_alloc_initialized_string(len, p));
		free(p);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_objset_recvd_props(value handle, value name)
{
	CAMLparam2 (handle, name);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_nvlist_dst_size = 256 * 1024;
	zc.zc_nvlist_dst = (uint64_t)(uintptr_t)malloc(zc.zc_nvlist_dst_size);
	if (zc.zc_nvlist_dst == 0) {
		err = errno;
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
		CAMLreturn (ret);
	}
	caml_release_runtime_system();
	while ((err = zfs_ioctl(fd, ZFS_IOC_OBJSET_RECVD_PROPS, &zc))
	    == ENOMEM) {
		void *oldptr = (void *)zc.zc_nvlist_dst;
		void *newptr = realloc(oldptr, zc.zc_nvlist_dst_size);
		if (newptr == NULL) {
			err = errno;
			break;
		}
		zc.zc_nvlist_dst = (uint64_t)(uintptr_t)newptr;
	}
	caml_acquire_runtime_system();
	if (err) {
		void *p = (void *)zc.zc_nvlist_dst;
		free(p);
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		char *p = (char *)zc.zc_nvlist_dst;
		size_t len = (size_t)zc.zc_nvlist_dst_size;
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, caml_alloc_initialized_string(len, p));
		free(p);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_vdev_split_native(value handle, value name, value newname,
    value conf, value props_opt, value export)
{
	CAMLparam5 (handle, name, newname, conf, props_opt);
	CAMLxparam1 (export);
	CAMLlocal2 (props, ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	if (strlcpy(zc.zc_string, String_val(newname), sizeof zc.zc_string)
	    >= sizeof zc.zc_string) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_nvlist_conf = (uint64_t)(uintptr_t)Bytes_val(conf);
	zc.zc_nvlist_conf_size = caml_string_length(conf);
	if (Is_some(props_opt)) {
		props = Some_val(props_opt);
		zc.zc_nvlist_src = (uint64_t)(uintptr_t)Bytes_val(props);
		zc.zc_nvlist_src_size = caml_string_length(props);
	}
	if (Bool_val(export)) {
		zc.zc_cookie = ZPOOL_EXPORT_AFTER_SPLIT;
	}
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_VDEV_SPLIT, &zc);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_vdev_split_bytecode(value *argv, int argn)
{
	return (caml_zfs_ioc_vdev_split_native(argv[0], argv[1], argv[2],
	    argv[3], argv[4], argv[5]));
}

CAMLprim value
caml_zfs_ioc_next_obj(value handle, value name, value obj)
{
	CAMLparam3 (handle, name, obj);
	CAMLlocal2 (nextobj, ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_obj = Int64_val(obj);
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_NEXT_OBJ, &zc);
	caml_acquire_runtime_system();
	if (err == ESRCH) {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_none);
	} else if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		nextobj = caml_copy_int64(zc.zc_obj);
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, caml_alloc_some(nextobj));
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_diff(value handle, value to, value from, value desc)
{
	CAMLparam4 (handle, to, from, desc);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(to), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	if (strlcpy(zc.zc_value, String_val(from), sizeof zc.zc_value)
	    >= sizeof zc.zc_value) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_cookie = Int_val(desc);
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_DIFF, &zc);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_tmp_snapshot(value handle, value name, value prefix, value desc)
{
	CAMLparam4 (handle, name, prefix, desc);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	if (strlcpy(zc.zc_value, String_val(prefix), sizeof zc.zc_value)
	    >= sizeof zc.zc_value) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_cleanup_fd = Int_val(desc);
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_TMP_SNAPSHOT, &zc);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, caml_copy_string(zc.zc_value));
	}
	CAMLreturn (ret);
}

static value
make_stat(const zfs_stat_t *zs)
{
	CAMLparam0 ();
	CAMLlocal2 (tuple, record);

	record = caml_alloc_tuple(4);
	Store_field(record, 0, caml_copy_int64(zs->zs_gen));
	Store_field(record, 1, caml_copy_int64(zs->zs_mode));
	Store_field(record, 2, caml_copy_int64(zs->zs_links));
	tuple = caml_alloc_tuple(2);
	Store_field(tuple, 0, caml_copy_int64(zs->zs_ctime[0]));
	Store_field(tuple, 1, caml_copy_int64(zs->zs_ctime[1]));
	Store_field(record, 3, tuple);
	CAMLreturn (record);
}

CAMLprim value
caml_zfs_ioc_obj_to_stats(value handle, value name, value obj)
{
	CAMLparam3 (handle, name, obj);
	CAMLlocal2 (tuple, ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_obj = Int64_val(obj);
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_OBJ_TO_STATS, &zc);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		tuple = caml_alloc_tuple(2);
		Store_field(tuple, 0, caml_copy_string(zc.zc_value));
		Store_field(tuple, 1, make_stat(&zc.zc_stat));
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, tuple);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_space_written(value handle, value name, value snap)
{
	CAMLparam3 (handle, name, snap);
	CAMLlocal2 (tuple, ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	if (strlcpy(zc.zc_value, String_val(snap), sizeof zc.zc_value)
	    >= sizeof zc.zc_value) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_SPACE_WRITTEN, &zc);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		tuple = caml_alloc_tuple(3);
		Store_field(tuple, 0, caml_copy_int64(zc.zc_cookie));
		Store_field(tuple, 1, caml_copy_int64(zc.zc_objset_type));
		Store_field(tuple, 2, caml_copy_int64(zc.zc_perm_action));
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, tuple);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_space_snaps(value handle, value last, value args)
{
	CAMLparam3 (handle, last, args);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(last), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_nvlist_src = (uint64_t)(uintptr_t)Bytes_val(args);
	zc.zc_nvlist_src_size = caml_string_length(args);
	zc.zc_nvlist_dst_size = MAX(2 * zc.zc_nvlist_src_size, 128 * 1024);
	zc.zc_nvlist_dst = (uint64_t)(uintptr_t)malloc(zc.zc_nvlist_dst_size);
	if (zc.zc_nvlist_dst == 0) {
		err = errno;
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
		CAMLreturn (ret);
	}
	caml_release_runtime_system();
	while ((err = zfs_ioctl(fd, ZFS_IOC_SPACE_SNAPS, &zc)) == ENOMEM) {
		void *oldptr = (void *)zc.zc_nvlist_dst;
		void *newptr = realloc(oldptr, zc.zc_nvlist_dst_size);
		if (newptr == NULL) {
			err = errno;
			break;
		}
		zc.zc_nvlist_dst = (uint64_t)(uintptr_t)newptr;
	}
	caml_acquire_runtime_system();
	if (err) {
		void *p = (void *)zc.zc_nvlist_dst;
		free(p);
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		char *p = (char *)zc.zc_nvlist_dst;
		size_t len = (size_t)zc.zc_nvlist_dst_size;
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, caml_alloc_initialized_string(len, p));
		free(p);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_destroy_snaps(value handle, value name, value args)
{
	CAMLparam3 (handle, name, args);
	CAMLlocal3 (bytes, tuple, ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
	    	tuple = caml_alloc_tuple(2);
		Store_field(tuple, 0, Val_none);
		Store_field(tuple, 1, caml_unix_error_of_code(ENAMETOOLONG));
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, tuple);
		CAMLreturn (ret);
	}
	zc.zc_nvlist_src = (uint64_t)(uintptr_t)Bytes_val(args);
	zc.zc_nvlist_src_size = caml_string_length(args);
	zc.zc_nvlist_dst_size = MAX(2 * zc.zc_nvlist_src_size, 128 * 1024);
	zc.zc_nvlist_dst = (uint64_t)(uintptr_t)malloc(zc.zc_nvlist_dst_size);
	if (zc.zc_nvlist_dst == 0) {
		err = errno;
		tuple = caml_alloc_tuple(2);
		Store_field(tuple, 0, Val_none);
		Store_field(tuple, 1, caml_unix_error_of_code(err));
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, tuple);
		CAMLreturn (ret);
	}
	caml_release_runtime_system();
	while ((err = zfs_ioctl(fd, ZFS_IOC_DESTROY_SNAPS, &zc)) == ENOMEM) {
		void *oldptr = (void *)zc.zc_nvlist_dst;
		void *newptr = realloc(oldptr, zc.zc_nvlist_dst_size);
		if (newptr == NULL) {
			err = errno;
			break;
		}
		zc.zc_nvlist_dst = (uint64_t)(uintptr_t)newptr;
	}
	caml_acquire_runtime_system();
	if (err) {
		tuple = caml_alloc_tuple(2);
		if (zc.zc_nvlist_dst_filled && err != ENOMEM) {
			char *p = (char *)zc.zc_nvlist_dst;
			size_t len = (size_t)zc.zc_nvlist_dst_size;
			bytes = caml_alloc_initialized_string(len, p);
			free(p);
			Store_field(tuple, 0, caml_alloc_some(bytes));
		} else {
			void *p = (void *)zc.zc_nvlist_dst;
			free(p);
			Store_field(tuple, 0, Val_none);
		}
		Store_field(tuple, 1, caml_unix_error_of_code(err));
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, tuple);
	} else {
		void *p = (void *)zc.zc_nvlist_dst;
		free(p);
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_pool_reguid(value handle, value name)
{
	CAMLparam2 (handle, name);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_POOL_REGUID, &zc);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_pool_reopen(value handle, value name, value args_opt)
{
	CAMLparam3 (handle, name, args_opt);
	CAMLlocal2 (args, ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	if (Is_some(args_opt)) {
		args = Some_val(args_opt);
		zc.zc_nvlist_src = (uint64_t)(uintptr_t)Bytes_val(args);
		zc.zc_nvlist_src_size = caml_string_length(args);
	}
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_POOL_REOPEN, &zc);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_send_progress(value handle, value name, value desc)
{
	CAMLparam3 (handle, name, desc);
	CAMLlocal2 (tuple, ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_cookie = Int_val(desc);
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_SEND_PROGRESS, &zc);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		tuple = caml_alloc_tuple(2);
		Store_field(tuple, 0, caml_copy_int64(zc.zc_cookie));
		Store_field(tuple, 1, caml_copy_int64(zc.zc_objset_type));
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, tuple);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_log_history(value handle, value args)
{
	CAMLparam2 (handle, args);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	zc.zc_nvlist_src = (uint64_t)(uintptr_t)Bytes_val(args);
	zc.zc_nvlist_src_size = caml_string_length(args);
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_LOG_HISTORY, &zc);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_send_new(value handle, value tosnap, value args)
{
	CAMLparam3 (handle, tosnap, args);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(tosnap), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_nvlist_src = (uint64_t)(uintptr_t)Bytes_val(args);
	zc.zc_nvlist_src_size = caml_string_length(args);
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_SEND_NEW, &zc);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_send_space(value handle, value tosnap, value args)
{
	CAMLparam3 (handle, tosnap, args);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(tosnap), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_nvlist_src = (uint64_t)(uintptr_t)Bytes_val(args);
	zc.zc_nvlist_src_size = caml_string_length(args);
	zc.zc_nvlist_dst_size = MAX(2 * zc.zc_nvlist_src_size, 128 * 1024);
	zc.zc_nvlist_dst = (uint64_t)(uintptr_t)malloc(zc.zc_nvlist_dst_size);
	if (zc.zc_nvlist_dst == 0) {
		err = errno;
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
		CAMLreturn (ret);
	}
	caml_release_runtime_system();
	while ((err = zfs_ioctl(fd, ZFS_IOC_SEND_SPACE, &zc)) == ENOMEM) {
		void *oldptr = (void *)zc.zc_nvlist_dst;
		void *newptr = realloc(oldptr, zc.zc_nvlist_dst_size);
		if (newptr == NULL) {
			err = errno;
			break;
		}
		zc.zc_nvlist_dst = (uint64_t)(uintptr_t)newptr;
	}
	caml_acquire_runtime_system();
	if (err) {
		void *p = (void *)zc.zc_nvlist_dst;
		free(p);
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		char *p = (char *)zc.zc_nvlist_dst;
		size_t len = (size_t)zc.zc_nvlist_dst_size;
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, caml_alloc_initialized_string(len, p));
		free(p);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_clone(value handle, value name, value args)
{
	CAMLparam3 (handle, name, args);
	CAMLlocal3 (bytes, tuple, ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		tuple = caml_alloc_tuple(2);
		Store_field(tuple, 0, Val_none);
		Store_field(tuple, 1, caml_unix_error_of_code(ENAMETOOLONG));
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, tuple);
		CAMLreturn (ret);
	}
	zc.zc_nvlist_src = (uint64_t)(uintptr_t)Bytes_val(args);
	zc.zc_nvlist_src_size = caml_string_length(args);
	zc.zc_nvlist_dst_size = MAX(2 * zc.zc_nvlist_src_size, 128 * 1024);
	zc.zc_nvlist_dst = (uint64_t)(uintptr_t)malloc(zc.zc_nvlist_dst_size);
	if (zc.zc_nvlist_dst == 0) {
		err = errno;
		tuple = caml_alloc_tuple(2);
		Store_field(tuple, 0, Val_none);
		Store_field(tuple, 1, caml_unix_error_of_code(err));
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, tuple);
		CAMLreturn (ret);
	}
	caml_release_runtime_system();
	while ((err = zfs_ioctl(fd, ZFS_IOC_CLONE, &zc)) == ENOMEM) {
		void *oldptr = (void *)zc.zc_nvlist_dst;
		void *newptr = realloc(oldptr, zc.zc_nvlist_dst_size);
		if (newptr == NULL) {
			err = errno;
			break;
		}
		zc.zc_nvlist_dst = (uint64_t)(uintptr_t)newptr;
	}
	caml_acquire_runtime_system();
	if (err) {
		tuple = caml_alloc_tuple(2);
		if (zc.zc_nvlist_dst_filled && err != ENOMEM) {
			char *p = (char *)zc.zc_nvlist_dst;
			size_t len = (size_t)zc.zc_nvlist_dst_size;
			bytes = caml_alloc_initialized_string(len, p);
			free(p);
			Store_field(tuple, 0, caml_alloc_some(bytes));
		} else {
			void *p = (void *)zc.zc_nvlist_dst;
			free(p);
			Store_field(tuple, 0, Val_none);
		}
		Store_field(tuple, 1, caml_unix_error_of_code(err));
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, tuple);
	} else {
		void *p = (void *)zc.zc_nvlist_dst;
		free(p);
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_bookmark(value handle, value name, value args)
{
	CAMLparam3 (handle, name, args);
	CAMLlocal3 (bytes, tuple, ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		tuple = caml_alloc_tuple(2);
		Store_field(tuple, 0, Val_none);
		Store_field(tuple, 1, caml_unix_error_of_code(ENAMETOOLONG));
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, tuple);
		CAMLreturn (ret);
	}
	zc.zc_nvlist_src = (uint64_t)(uintptr_t)Bytes_val(args);
	zc.zc_nvlist_src_size = caml_string_length(args);
	zc.zc_nvlist_dst_size = MAX(2 * zc.zc_nvlist_src_size, 128 * 1024);
	zc.zc_nvlist_dst = (uint64_t)(uintptr_t)malloc(zc.zc_nvlist_dst_size);
	if (zc.zc_nvlist_dst == 0) {
		err = errno;
		tuple = caml_alloc_tuple(2);
		Store_field(tuple, 0, Val_none);
		Store_field(tuple, 1, caml_unix_error_of_code(err));
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, tuple);
		CAMLreturn (ret);
	}
	caml_release_runtime_system();
	while ((err = zfs_ioctl(fd, ZFS_IOC_SNAPSHOT, &zc)) == ENOMEM) {
		void *oldptr = (void *)zc.zc_nvlist_dst;
		void *newptr = realloc(oldptr, zc.zc_nvlist_dst_size);
		if (newptr == NULL) {
			err = errno;
			break;
		}
		zc.zc_nvlist_dst = (uint64_t)(uintptr_t)newptr;
	}
	caml_acquire_runtime_system();
	if (err) {
		tuple = caml_alloc_tuple(2);
		if (zc.zc_nvlist_dst_filled && err != ENOMEM) {
			char *p = (char *)zc.zc_nvlist_dst;
			size_t len = (size_t)zc.zc_nvlist_dst_size;
			bytes = caml_alloc_initialized_string(len, p);
			free(p);
			Store_field(tuple, 0, caml_alloc_some(bytes));
		} else {
			void *p = (void *)zc.zc_nvlist_dst;
			free(p);
			Store_field(tuple, 0, Val_none);
		}
		Store_field(tuple, 1, caml_unix_error_of_code(err));
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, tuple);
	} else {
		void *p = (void *)zc.zc_nvlist_dst;
		free(p);
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_get_bookmarks(value handle, value name, value props_opt)
{
	CAMLparam3 (handle, name, props_opt);
	CAMLlocal2 (props, ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	if (Is_some(props_opt)) {
		props = Some_val(props_opt);
		zc.zc_nvlist_src = (uint64_t)(uintptr_t)Bytes_val(props);
		zc.zc_nvlist_src_size = caml_string_length(props);
	}
	zc.zc_nvlist_dst_size = MAX(2 * zc.zc_nvlist_src_size, 128 * 1024);
	zc.zc_nvlist_dst = (uint64_t)(uintptr_t)malloc(zc.zc_nvlist_dst_size);
	if (zc.zc_nvlist_dst == 0) {
		err = errno;
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
		CAMLreturn (ret);
	}
	caml_release_runtime_system();
	while ((err = zfs_ioctl(fd, ZFS_IOC_GET_BOOKMARKS, &zc)) == ENOMEM) {
		void *oldptr = (void *)zc.zc_nvlist_dst;
		void *newptr = realloc(oldptr, zc.zc_nvlist_dst_size);
		if (newptr == NULL) {
			err = errno;
			break;
		}
		zc.zc_nvlist_dst = (uint64_t)(uintptr_t)newptr;
	}
	caml_acquire_runtime_system();
	if (err) {
		void *p = (void *)zc.zc_nvlist_dst;
		free(p);
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		char *p = (char *)zc.zc_nvlist_dst;
		size_t len = (size_t)zc.zc_nvlist_dst_size;
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, caml_alloc_initialized_string(len, p));
		free(p);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_destroy_bookmarks(value handle, value name, value list)
{
	CAMLparam3 (handle, name, list);
	CAMLlocal3 (bytes, tuple, ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		tuple = caml_alloc_tuple(2);
		Store_field(tuple, 0, Val_none);
		Store_field(tuple, 1, caml_unix_error_of_code(ENAMETOOLONG));
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, tuple);
		CAMLreturn (ret);
	}
	zc.zc_nvlist_src = (uint64_t)(uintptr_t)Bytes_val(list);
	zc.zc_nvlist_src_size = caml_string_length(list);
	zc.zc_nvlist_dst_size = MAX(2 * zc.zc_nvlist_src_size, 128 * 1024);
	zc.zc_nvlist_dst = (uint64_t)(uintptr_t)malloc(zc.zc_nvlist_dst_size);
	if (zc.zc_nvlist_dst == 0) {
		err = errno;
		tuple = caml_alloc_tuple(2);
		Store_field(tuple, 0, Val_none);
		Store_field(tuple, 1, caml_unix_error_of_code(err));
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, tuple);
		CAMLreturn (ret);
	}
	caml_release_runtime_system();
	while ((err = zfs_ioctl(fd, ZFS_IOC_DESTROY_BOOKMARKS, &zc)) == ENOMEM) {
		void *oldptr = (void *)zc.zc_nvlist_dst;
		void *newptr = realloc(oldptr, zc.zc_nvlist_dst_size);
		if (newptr == NULL) {
			err = errno;
			break;
		}
		zc.zc_nvlist_dst = (uint64_t)(uintptr_t)newptr;
	}
	caml_acquire_runtime_system();
	if (err) {
		tuple = caml_alloc_tuple(2);
		if (zc.zc_nvlist_dst_filled && err != ENOMEM) {
			char *p = (char *)zc.zc_nvlist_dst;
			size_t len = (size_t)zc.zc_nvlist_dst_size;
			bytes = caml_alloc_initialized_string(len, p);
			free(p);
			Store_field(tuple, 0, caml_alloc_some(bytes));
		} else {
			void *p = (void *)zc.zc_nvlist_dst;
			free(p);
			Store_field(tuple, 0, Val_none);
		}
		Store_field(tuple, 1, caml_unix_error_of_code(err));
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, tuple);
	} else {
		void *p = (void *)zc.zc_nvlist_dst;
		free(p);
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_recv_new(value handle, value name, value args)
{
	CAMLparam3 (handle, name, args);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_nvlist_src = (uint64_t)(uintptr_t)Bytes_val(args);
	zc.zc_nvlist_src_size = caml_string_length(args);
	zc.zc_nvlist_dst_size = MAX(2 * zc.zc_nvlist_src_size, 128 * 1024);
	zc.zc_nvlist_dst = (uint64_t)(uintptr_t)malloc(zc.zc_nvlist_dst_size);
	if (zc.zc_nvlist_dst == 0) {
		err = errno;
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
		CAMLreturn (ret);
	}
	caml_release_runtime_system();
	while ((err = zfs_ioctl(fd, ZFS_IOC_RECV_NEW, &zc)) == ENOMEM) {
		void *oldptr = (void *)zc.zc_nvlist_dst;
		void *newptr = realloc(oldptr, zc.zc_nvlist_dst_size);
		if (newptr == NULL) {
			err = errno;
			break;
		}
		zc.zc_nvlist_dst = (uint64_t)(uintptr_t)newptr;
	}
	caml_acquire_runtime_system();
	if (err) {
		void *p = (void *)zc.zc_nvlist_dst;
		free(p);
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		char *p = (char *)zc.zc_nvlist_dst;
		size_t len = (size_t)zc.zc_nvlist_dst_size;
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, caml_alloc_initialized_string(len, p));
		free(p);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_pool_sync(value handle, value name, value args)
{
	CAMLparam3 (handle, name, args);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_nvlist_src = (uint64_t)(uintptr_t)Bytes_val(args);
	zc.zc_nvlist_src_size = caml_string_length(args);
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_POOL_SYNC, &zc);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_channel_program(value handle, value name, value args,
    value memlimit)
{
	CAMLparam4 (handle, name, args, memlimit);
	CAMLlocal3 (bytes, tuple, ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		tuple = caml_alloc_tuple(2);
		Store_field(tuple, 0, Val_none);
		Store_field(tuple, 1, caml_unix_error_of_code(ENAMETOOLONG));
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, tuple);
		CAMLreturn (ret);
	}
	zc.zc_nvlist_src = (uint64_t)(uintptr_t)Bytes_val(args);
	zc.zc_nvlist_src_size = caml_string_length(args);
	zc.zc_nvlist_dst_size = Int_val(memlimit);
	zc.zc_nvlist_dst = (uint64_t)(uintptr_t)malloc(zc.zc_nvlist_dst_size);
	if (zc.zc_nvlist_dst == 0) {
		err = errno;
		tuple = caml_alloc_tuple(2);
		Store_field(tuple, 0, Val_none);
		Store_field(tuple, 1, caml_unix_error_of_code(err));
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, tuple);
		CAMLreturn (ret);
	}
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_CHANNEL_PROGRAM, &zc);
	caml_acquire_runtime_system();
	if (err) {
		tuple = caml_alloc_tuple(2);
		if (zc.zc_nvlist_dst_filled && errno != ENOMEM) {
			char *p = (char *)zc.zc_nvlist_dst;
			size_t len = (size_t)zc.zc_nvlist_dst_size;
			bytes = caml_alloc_initialized_string(len, p);
			free(p);
			Store_field(tuple, 0, caml_alloc_some(bytes));
		} else {
			void *p = (void *)zc.zc_nvlist_dst;
			free(p);
			Store_field(tuple, 0, Val_none);
		}
		Store_field(tuple, 1, caml_unix_error_of_code(err));
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, tuple);
	} else {
		char *p = (char *)zc.zc_nvlist_dst;
		size_t len = (size_t)zc.zc_nvlist_dst_size;
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, caml_alloc_initialized_string(len, p));
		free(p);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_load_key(value handle, value name, value args)
{
	CAMLparam3 (handle, name, args);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_nvlist_src = (uint64_t)(uintptr_t)Bytes_val(args);
	zc.zc_nvlist_src_size = caml_string_length(args);
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_LOAD_KEY, &zc);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_unload_key(value handle, value name)
{
	CAMLparam2 (handle, name);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_UNLOAD_KEY, &zc);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_change_key(value handle, value name, value args)
{
	CAMLparam3 (handle, name, args);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_nvlist_src = (uint64_t)(uintptr_t)Bytes_val(args);
	zc.zc_nvlist_src_size = caml_string_length(args);
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_CHANGE_KEY, &zc);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_pool_checkpoint(value handle, value name)
{
	CAMLparam2 (handle, name);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(handle), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_POOL_CHECKPOINT, &zc);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_pool_discard_checkpoint(value handle, value name)
{
	CAMLparam2 (handle, name);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_POOL_DISCARD_CHECKPOINT, &zc);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_pool_initialize(value handle, value name, value args)
{
	CAMLparam3 (handle, name, args);
	CAMLlocal3 (bytes, tuple, ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		tuple = caml_alloc_tuple(2);
		Store_field(tuple, 0, Val_none);
		Store_field(tuple, 1, caml_unix_error_of_code(ENAMETOOLONG));
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, tuple);
		CAMLreturn (ret);
	}
	zc.zc_nvlist_src = (uint64_t)(uintptr_t)Bytes_val(args);
	zc.zc_nvlist_src_size = caml_string_length(args);
	zc.zc_nvlist_dst_size = MAX(2 * zc.zc_nvlist_src_size, 128 * 1024);
	zc.zc_nvlist_dst = (uint64_t)(uintptr_t)malloc(zc.zc_nvlist_dst_size);
	if (zc.zc_nvlist_dst == 0) {
		err = errno;
		tuple = caml_alloc_tuple(2);
		Store_field(tuple, 0, Val_none);
		Store_field(tuple, 1, caml_unix_error_of_code(err));
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, tuple);
		CAMLreturn (ret);
	}
	caml_release_runtime_system();
	while ((err = zfs_ioctl(fd, ZFS_IOC_POOL_INITIALIZE, &zc)) == ENOMEM) {
		void *oldptr = (void *)zc.zc_nvlist_dst;
		void *newptr = realloc(oldptr, zc.zc_nvlist_dst_size);
		if (newptr == NULL) {
			err = errno;
			break;
		}
		zc.zc_nvlist_dst = (uint64_t)(uintptr_t)newptr;
	}
	caml_acquire_runtime_system();
	if (err) {
		tuple = caml_alloc_tuple(2);
		if (zc.zc_nvlist_dst_filled && err != ENOMEM) {
			char *p = (char *)zc.zc_nvlist_dst;
			size_t len = (size_t)zc.zc_nvlist_dst_size;
			bytes = caml_alloc_initialized_string(len, p);
			free(p);
			Store_field(tuple, 0, caml_alloc_some(bytes));
		} else {
			void *p = (void *)zc.zc_nvlist_dst;
			free(p);
			Store_field(tuple, 0, Val_none);
		}
		Store_field(tuple, 1, caml_unix_error_of_code(err));
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, tuple);
	} else {
		void *p = (void *)zc.zc_nvlist_dst;
		free(p);
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_pool_trim(value handle, value name, value args)
{
	CAMLparam3 (handle, name, args);
	CAMLlocal3 (bytes, tuple, ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		tuple = caml_alloc_tuple(2);
		Store_field(tuple, 0, Val_none);
		Store_field(tuple, 1, caml_unix_error_of_code(ENAMETOOLONG));
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, tuple);
		CAMLreturn (ret);
	}
	zc.zc_nvlist_src = (uint64_t)(uintptr_t)Bytes_val(args);
	zc.zc_nvlist_src_size = caml_string_length(args);
	zc.zc_nvlist_dst_size = MAX(2 * zc.zc_nvlist_src_size, 128 * 1024);
	zc.zc_nvlist_dst = (uint64_t)(uintptr_t)malloc(zc.zc_nvlist_dst_size);
	if (zc.zc_nvlist_dst == 0) {
		err = errno;
		tuple = caml_alloc_tuple(2);
		Store_field(tuple, 0, Val_none);
		Store_field(tuple, 1, caml_unix_error_of_code(err));
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, tuple);
		CAMLreturn (ret);
	}
	caml_release_runtime_system();
	while ((err = zfs_ioctl(fd, ZFS_IOC_POOL_TRIM, &zc)) == ENOMEM) {
		void *oldptr = (void *)zc.zc_nvlist_dst;
		void *newptr = realloc(oldptr, zc.zc_nvlist_dst_size);
		if (newptr == NULL) {
			err = errno;
			break;
		}
		zc.zc_nvlist_dst = (uint64_t)(uintptr_t)newptr;
	}
	caml_acquire_runtime_system();
	if (err) {
		tuple = caml_alloc_tuple(2);
		if (zc.zc_nvlist_dst_filled && err != ENOMEM) {
			char *p = (char *)zc.zc_nvlist_dst;
			size_t len = (size_t)zc.zc_nvlist_dst_size;
			bytes = caml_alloc_initialized_string(len, p);
			free(p);
			Store_field(tuple, 0, caml_alloc_some(bytes));
		} else {
			void *p = (void *)zc.zc_nvlist_dst;
			free(p);
			Store_field(tuple, 0, Val_none);
		}
		Store_field(tuple, 1, caml_unix_error_of_code(err));
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, tuple);
	} else {
		void *p = (void *)zc.zc_nvlist_dst;
		free(p);
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_redact(value handle, value name, value args)
{
	CAMLparam3 (handle, name, args);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_nvlist_src = (uint64_t)(uintptr_t)Bytes_val(args);
	zc.zc_nvlist_src_size = caml_string_length(args);
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_REDACT, &zc);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_get_bookmark_props(value handle, value name)
{
	CAMLparam2 (handle, name);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_nvlist_dst_size = 128 * 1024;
	zc.zc_nvlist_dst = (uint64_t)(uintptr_t)malloc(zc.zc_nvlist_dst_size);
	if (zc.zc_nvlist_dst == 0) {
		err = errno;
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
		CAMLreturn (ret);
	}
	caml_release_runtime_system();
	while ((err = zfs_ioctl(fd, ZFS_IOC_GET_BOOKMARK_PROPS, &zc))
	    == ENOMEM) {
		void *oldptr = (void *)zc.zc_nvlist_dst;
		void *newptr = realloc(oldptr, zc.zc_nvlist_dst_size);
		if (newptr == NULL) {
			err = errno;
			break;
		}
		zc.zc_nvlist_dst = (uint64_t)(uintptr_t)newptr;
	}
	caml_acquire_runtime_system();
	if (err) {
		void *p = (void *)zc.zc_nvlist_dst;
		free(p);
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		char *p = (char *)zc.zc_nvlist_dst;
		size_t len = (size_t)zc.zc_nvlist_dst_size;
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, caml_alloc_initialized_string(len, p));
		free(p);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_wait(value handle, value name, value args)
{
	CAMLparam3 (handle, name, args);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_nvlist_src = (uint64_t)(uintptr_t)Bytes_val(args);
	zc.zc_nvlist_src_size = caml_string_length(args);
	zc.zc_nvlist_dst_size = MAX(2 * zc.zc_nvlist_src_size, 128 * 1024);
	zc.zc_nvlist_dst = (uint64_t)(uintptr_t)malloc(zc.zc_nvlist_dst_size);
	if (zc.zc_nvlist_dst == 0) {
		err = errno;
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
		CAMLreturn (ret);
	}
	caml_release_runtime_system();
	while ((err = zfs_ioctl(fd, ZFS_IOC_WAIT, &zc)) == ENOMEM) {
		void *oldptr = (void *)zc.zc_nvlist_dst;
		void *newptr = realloc(oldptr, zc.zc_nvlist_dst_size);
		if (newptr == NULL) {
			err = errno;
			break;
		}
		zc.zc_nvlist_dst = (uint64_t)(uintptr_t)newptr;
	}
	caml_acquire_runtime_system();
	if (err) {
		void *p = (void *)zc.zc_nvlist_dst;
		free(p);
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		char *p = (char *)zc.zc_nvlist_dst;
		size_t len = (size_t)zc.zc_nvlist_dst_size;
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, caml_alloc_initialized_string(len, p));
		free(p);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_wait_fs(value handle, value name, value args)
{
	CAMLparam3 (handle, name, args);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_nvlist_src = (uint64_t)(uintptr_t)Bytes_val(args);
	zc.zc_nvlist_src_size = caml_string_length(args);
	zc.zc_nvlist_dst_size = MAX(2 * zc.zc_nvlist_src_size, 128 * 1024);
	zc.zc_nvlist_dst = (uint64_t)(uintptr_t)malloc(zc.zc_nvlist_dst_size);
	if (zc.zc_nvlist_dst == 0) {
		err = errno;
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
		CAMLreturn (ret);
	}
	caml_release_runtime_system();
	while ((err = zfs_ioctl(fd, ZFS_IOC_WAIT_FS, &zc)) == ENOMEM) {
		void *oldptr = (void *)zc.zc_nvlist_dst;
		void *newptr = realloc(oldptr, zc.zc_nvlist_dst_size);
		if (newptr == NULL) {
			err = errno;
			break;
		}
		zc.zc_nvlist_dst = (uint64_t)(uintptr_t)newptr;
	}
	caml_acquire_runtime_system();
	if (err) {
		void *p = (void *)zc.zc_nvlist_dst;
		free(p);
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		char *p = (char *)zc.zc_nvlist_dst;
		size_t len = (size_t)zc.zc_nvlist_dst_size;
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, caml_alloc_initialized_string(len, p));
		free(p);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_vdev_get_props(value handle, value name, value args)
{
	CAMLparam3 (handle, name, args);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_nvlist_src = (uint64_t)(uintptr_t)Bytes_val(args);
	zc.zc_nvlist_src_size = caml_string_length(args);
	zc.zc_nvlist_dst_size = MAX(2 * zc.zc_nvlist_src_size, 128 * 1024);
	zc.zc_nvlist_dst = (uint64_t)(uintptr_t)malloc(zc.zc_nvlist_dst_size);
	if (zc.zc_nvlist_dst == 0) {
		err = errno;
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
		CAMLreturn (ret);
	}
	caml_release_runtime_system();
	while ((err = zfs_ioctl(fd, ZFS_IOC_VDEV_GET_PROPS, &zc)) == ENOMEM) {
		void *oldptr = (void *)zc.zc_nvlist_dst;
		void *newptr = realloc(oldptr, zc.zc_nvlist_dst_size);
		if (newptr == NULL) {
			err = errno;
			break;
		}
		zc.zc_nvlist_dst = (uint64_t)(uintptr_t)newptr;
	}
	caml_acquire_runtime_system();
	if (err) {
		void *p = (void *)zc.zc_nvlist_dst;
		free(p);
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		char *p = (char *)zc.zc_nvlist_dst;
		size_t len = (size_t)zc.zc_nvlist_dst_size;
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, caml_alloc_initialized_string(len, p));
		free(p);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_vdev_set_props(value handle, value name, value args)
{
	CAMLparam3 (handle, name, args);
	CAMLlocal3 (bytes, tuple, ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		tuple = caml_alloc_tuple(2);
		Store_field(tuple, 0, Val_none);
		Store_field(tuple, 1, caml_unix_error_of_code(ENAMETOOLONG));
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, tuple);
		CAMLreturn (ret);
	}
	zc.zc_nvlist_src = (uint64_t)(uintptr_t)Bytes_val(args);
	zc.zc_nvlist_src_size = caml_string_length(args);
	zc.zc_nvlist_dst_size = MAX(2 * zc.zc_nvlist_src_size, 128 * 1024);
	zc.zc_nvlist_dst = (uint64_t)(uintptr_t)malloc(zc.zc_nvlist_dst_size);
	if (zc.zc_nvlist_dst == 0) {
		err = errno;
		tuple = caml_alloc_tuple(2);
		Store_field(tuple, 0, Val_none);
		Store_field(tuple, 1, caml_unix_error_of_code(err));
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, tuple);
		CAMLreturn (ret);
	}
	caml_release_runtime_system();
	while ((err = zfs_ioctl(fd, ZFS_IOC_VDEV_SET_PROPS, &zc)) == ENOMEM) {
		void *oldptr = (void *)zc.zc_nvlist_dst;
		void *newptr = realloc(oldptr, zc.zc_nvlist_dst_size);
		if (newptr == NULL) {
			err = errno;
			break;
		}
		zc.zc_nvlist_dst = (uint64_t)(uintptr_t)newptr;
	}
	caml_acquire_runtime_system();
	if (err) {
		tuple = caml_alloc_tuple(2);
		if (zc.zc_nvlist_dst_filled && err != ENOMEM) {
			char *p = (char *)zc.zc_nvlist_dst;
			size_t len = (size_t)zc.zc_nvlist_dst_size;
			bytes = caml_alloc_initialized_string(len, p);
			free(p);
			Store_field(tuple, 0, caml_alloc_some(bytes));
		} else {
			void *p = (void *)zc.zc_nvlist_dst;
			free(p);
			Store_field(tuple, 0, Val_none);
		}
		Store_field(tuple, 1, caml_unix_error_of_code(err));
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, tuple);
	} else {
		void *p = (void *)zc.zc_nvlist_dst;
		free(p);
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_pool_scrub(value handle, value name, value args)
{
	CAMLparam3 (handle, name, args);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_nvlist_src = (uint64_t)(uintptr_t)Bytes_val(args);
	zc.zc_nvlist_src_size = caml_string_length(args);
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_POOL_SCRUB, &zc);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_nextboot(value handle, value args)
{
	CAMLparam2 (handle, args);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	zc.zc_nvlist_src = (uint64_t)(uintptr_t)Bytes_val(args);
	zc.zc_nvlist_src_size = caml_string_length(args);
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_NEXTBOOT, &zc);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_jail(value handle, value name, value jid)
{
	CAMLparam3 (handle, name, jid);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_zoneid = Int_val(jid);
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_JAIL, &zc);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_unjail(value handle, value name, value jid)
{
	CAMLparam3 (handle, name, jid);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_zoneid = Int_val(jid);
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_UNJAIL, &zc);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_set_bootenv(value handle, value name, value args)
{
	CAMLparam3 (handle, name, args);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_nvlist_src = (uint64_t)(uintptr_t)Bytes_val(args);
	zc.zc_nvlist_src_size = caml_string_length(args);
	caml_release_runtime_system();
	err = zfs_ioctl(fd, ZFS_IOC_SET_BOOTENV, &zc);
	caml_acquire_runtime_system();
	if (err) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, Val_unit);
	}
	CAMLreturn (ret);
}

CAMLprim value
caml_zfs_ioc_get_bootenv(value handle, value name)
{
	CAMLparam2 (handle, name);
	CAMLlocal1 (ret);
	zfs_cmd_t zc = {"\0"};
	int fd, err;

	fd = Devzfs_val(handle);
	if (strlcpy(zc.zc_name, String_val(name), sizeof zc.zc_name)
	    >= sizeof zc.zc_name) {
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(ENAMETOOLONG));
		CAMLreturn (ret);
	}
	zc.zc_nvlist_dst_size = 128 * 1024;
	zc.zc_nvlist_dst = (uint64_t)(uintptr_t)malloc(zc.zc_nvlist_dst_size);
	if (zc.zc_nvlist_dst == 0) {
		err = errno;
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
		CAMLreturn (ret);
	}
	caml_release_runtime_system();
	while ((err = zfs_ioctl(fd, ZFS_IOC_GET_BOOTENV, &zc)) == ENOMEM) {
		void *oldptr = (void *)zc.zc_nvlist_dst;
		void *newptr = realloc(oldptr, zc.zc_nvlist_dst_size);
		if (newptr == NULL) {
			err = errno;
			break;
		}
		zc.zc_nvlist_dst = (uint64_t)(uintptr_t)newptr;
	}
	caml_acquire_runtime_system();
	if (err) {
		void *p = (void *)zc.zc_nvlist_dst;
		free(p);
		ret = caml_alloc(1, 1);
		Store_field(ret, 0, caml_unix_error_of_code(err));
	} else {
		char *p = (char *)zc.zc_nvlist_dst;
		size_t len = (size_t)zc.zc_nvlist_dst_size;
		ret = caml_alloc(1, 0);
		Store_field(ret, 0, caml_alloc_initialized_string(len, p));
		free(p);
	}
	CAMLreturn (ret);
}
