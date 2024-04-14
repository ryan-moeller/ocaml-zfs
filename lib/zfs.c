#include <sys/param.h>
#include <errno.h>
#include <string.h>
#include <libnvpair.h>
#include <libzfs_core.h>
#include <libzfs.h>
#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/memory.h>
#include <caml/fail.h>
#include <caml/threads.h>
#include <caml/unixsupport.h>
#include <caml/custom.h>
#include "caml_nvpair.h"

/*
 * Libzfs submodule
 */

static void custom_finalize_handle(value v);

static const struct custom_operations handle_ops = {
	"org.openzfs.libzfs_handle",
	custom_finalize_handle,
	custom_compare_default,
	custom_hash_default,
	custom_serialize_default,
	custom_deserialize_default,
	custom_compare_ext_default,
	custom_fixed_length_default
};

/* Accessing the libzfs_handle_t * part of an OCaml custom block */
#define Handle_val(v) (*((libzfs_handle_t **) Data_custom_val(v)))

static value
handle_alloc_custom(libzfs_handle_t *hdl)
{
	value v = caml_alloc_custom(&handle_ops, sizeof (libzfs_handle_t *), 0, 1);
	Handle_val(v) = hdl;
	return v;
}

static void
custom_finalize_handle(value hdl_custom)
{
	libzfs_fini(Handle_val(hdl_custom));
}

CAMLprim value
caml_libzfs_init(value unit)
{
	CAMLparam1 (unit);
	libzfs_handle_t *hdl;

	caml_release_runtime_system();
	hdl = libzfs_init();
	caml_acquire_runtime_system();
	if (hdl == NULL) {
		caml_failwith("libzfs_init");
	}
	CAMLreturn (handle_alloc_custom(hdl));
}

/*
 * Zpool submodlue
 */

static void custom_finalize_zpool_handle(value v);

static const struct custom_operations zpool_handle_ops = {
	"org.openzfs.zpool_handle",
	custom_finalize_zpool_handle,
	custom_compare_default,
	custom_hash_default,
	custom_serialize_default,
	custom_deserialize_default,
	custom_compare_ext_default,
	custom_fixed_length_default
};

/* Accessing the zpool_handle_t * part of an OCaml custom block */
#define Zpool_val(v) (*((zpool_handle_t **) Data_custom_val(v)))

static value
zpool_handle_alloc_custom(zpool_handle_t *zhp)
{
	value v = caml_alloc_custom(&zpool_handle_ops, sizeof (zpool_handle_t *), 0, 1);
	Zpool_val(v) = zhp;
	return v;
}

static void
custom_finalize_zpool_handle(value zhp_custom)
{
	zpool_close(Zpool_val(zhp_custom));
}

CAMLprim value
caml_zpool_open(value hdl_custom, value name)
{
	CAMLparam2 (hdl_custom, name);
	libzfs_handle_t *hdl;
	zpool_handle_t *zhp;
	const char *n;

	hdl = Handle_val(hdl_custom);
	n = String_val(name);
	caml_release_runtime_system();
	zhp = zpool_open(hdl, n);
	caml_acquire_runtime_system();
	if (zhp == NULL) {
		CAMLreturn (Val_none);
	}
	CAMLreturn (caml_alloc_some(zpool_handle_alloc_custom(zhp)));
}

CAMLprim value
caml_zpool_get_name(value zhp_custom)
{
	CAMLparam1 (zhp_custom);
	zpool_handle_t *zhp;
	const char *name;

	zhp = Zpool_val(zhp_custom);
	name = zpool_get_name(zhp);
	CAMLreturn (caml_copy_string(name));
}

value
zprop_source_to_sources(zprop_source_t source)
{
	static const zprop_source_t sources[] = {
		ZPROP_SRC_NONE,
		ZPROP_SRC_DEFAULT,
		ZPROP_SRC_TEMPORARY,
		ZPROP_SRC_LOCAL,
		ZPROP_SRC_INHERITED,
		ZPROP_SRC_RECEIVED
	};
	value srcs = caml_alloc(__bitcountl(source), 0);

	for (uint_t i = 0, j = 0; i < nitems(sources); i++) {
		zprop_source_t src = sources[i];
		if (source & src) {
			Store_field(srcs, j++, Val_int(src));
		}
	}
	return srcs;
}
	
CAMLprim value
caml_zpool_get_prop(value zhp_custom, value prop)
{
	CAMLparam2 (zhp_custom, prop);
	CAMLlocal1 (pair);
	char v[ZPOOL_MAXPROPLEN];
	zpool_handle_t *zhp;
	zpool_prop_t property;
	zprop_source_t src;
	int err;

	zhp = Zpool_val(zhp_custom);
	property = Int_val(prop);
	caml_release_runtime_system();
	err = zpool_get_prop(zhp, property, v, sizeof v, &src, B_TRUE);
	caml_acquire_runtime_system();
	if (err) {
		caml_failwith("zpool_get_prop");
	}
	if (strcmp(v, "-") == 0) {
		CAMLreturn (Val_none);
	}
	pair = caml_alloc_tuple(2);
	Store_field(pair, 0, caml_copy_string(v));
	Store_field(pair, 1, zprop_source_to_sources(src));
	CAMLreturn (caml_alloc_some(pair));
}

CAMLprim value
caml_zpool_get_userprop(value zhp_custom, value userprop)
{
	CAMLparam2 (zhp_custom, userprop);
	CAMLlocal1 (pair);
	char v[ZPOOL_MAXPROPLEN];
	zpool_handle_t *zhp;
	const char *property;
	zprop_source_t src;
	int err;

	zhp = Zpool_val(zhp_custom);
	property = String_val(userprop);
	caml_release_runtime_system();
	err = zpool_get_userprop(zhp, property, v, sizeof v, &src);
	caml_acquire_runtime_system();
	if (err) {
		caml_failwith("zpool_get_userprop");
	}
	if (strcmp(v, "-") == 0) {
		CAMLreturn (Val_none);
	}
	pair = caml_alloc_tuple(2);
	Store_field(pair, 0, caml_copy_string(v));
	Store_field(pair, 1, zprop_source_to_sources(src));
	CAMLreturn (caml_alloc_some(pair));
}

/*
 * Zfs submodule
 */

static void custom_finalize_zfs_handle(value v);

static const struct custom_operations zfs_handle_ops = {
	"org.openzfs.zfs_handle",
	custom_finalize_zfs_handle,
	custom_compare_default,
	custom_hash_default,
	custom_serialize_default,
	custom_deserialize_default,
	custom_compare_ext_default,
	custom_fixed_length_default
};

/* Accessing the zfs_handle_t * part of an OCaml custom block */
#define Zfs_val(v) (*((zfs_handle_t **) Data_custom_val(v)))

static value
zfs_handle_alloc_custom(zfs_handle_t *zhp)
{
	value v = caml_alloc_custom(&zfs_handle_ops, sizeof (zfs_handle_t *), 0, 1);
	Zfs_val(v) = zhp;
	return v;
}

static void
custom_finalize_zfs_handle(value zhp_custom)
{
	zfs_close(Zfs_val(zhp_custom));
}

CAMLprim value
caml_zfs_open(value hdl_custom, value name, value types)
{
	CAMLparam3 (hdl_custom, name, types);
	libzfs_handle_t *hdl;
	zfs_handle_t *zhp;
	const char *n;
	int ts;
	uint_t nts;

	ts = 0;
	nts = Wosize_val(types);
	for (uint_t i = 0; i < nts; i++) {
		ts |= Int_val(Field(types, i));
	}
	hdl = Handle_val(hdl_custom);
	n = String_val(name);
	caml_release_runtime_system();
	zhp = zfs_open(hdl, n, ts);
	caml_acquire_runtime_system();
	if (zhp == NULL) {
		CAMLreturn (Val_none);
	}
	CAMLreturn (caml_alloc_some(zfs_handle_alloc_custom(zhp)));
}

CAMLprim value
caml_zfs_get_name(value zhp_custom)
{
	CAMLparam1 (zhp_custom);
	zfs_handle_t *zhp;
	const char *name;

	zhp = Zfs_val(zhp_custom);
	name = zfs_get_name(zhp);
	CAMLreturn (caml_copy_string(name));
}

CAMLprim value
caml_zfs_get_pool_name(value zhp_custom)
{
	CAMLparam1 (zhp_custom);
	zfs_handle_t *zhp;
	const char *pool_name;

	zhp = Zfs_val(zhp_custom);
	pool_name = zfs_get_name(zhp);
	CAMLreturn (caml_copy_string(pool_name));
}

CAMLprim value
caml_zfs_get_type(value zhp_custom)
{
	CAMLparam1 (zhp_custom);
	zfs_handle_t *zhp;
	zfs_type_t zfs_type;

	zhp = Zfs_val(zhp_custom);
	zfs_type = zfs_get_type(zhp);
	CAMLreturn (Val_int(zfs_type));
}

CAMLprim value
caml_zfs_get_underlying_type(value zhp_custom)
{
	CAMLparam1 (zhp_custom);
	zfs_handle_t *zhp;
	zfs_type_t zfs_type;

	zhp = Zfs_val(zhp_custom);
	zfs_type = zfs_get_underlying_type(zhp);
	CAMLreturn (Val_int(zfs_type));
}

CAMLprim value
caml_zfs_bookmark_exists(value path)
{
	CAMLparam1 (path);
	const char *p;
	boolean_t exists;

	p = String_val(path);
	caml_release_runtime_system();
	exists = zfs_bookmark_exists(p);
	caml_acquire_runtime_system();
	CAMLreturn (exists == B_TRUE ? Val_true : Val_false);
}

CAMLprim value
caml_zfs_get_prop(value zhp_custom, value prop)
{
	CAMLparam2 (zhp_custom, prop);
	CAMLlocal1 (tuple);
	char v[ZFS_MAXPROPLEN];
	char source[ZFS_MAX_DATASET_NAME_LEN];
	zfs_handle_t *zhp;
	zfs_prop_t property;
	zprop_source_t src;
	int err;

	source[0] = '\0';
	zhp = Zfs_val(zhp_custom);
	property = Int_val(prop);
	caml_release_runtime_system();
	err = zfs_prop_get(zhp, property, v, sizeof v, &src, source, sizeof source, B_TRUE);
	caml_acquire_runtime_system();
	if (err) {
		caml_failwith("zfs_prop_get");
	}
	if (strcmp(v, "-") == 0) {
		CAMLreturn (Val_none);
	}
	tuple = caml_alloc_tuple(3);
	Store_field(tuple, 0, caml_copy_string(v));
	if (source[0] == '\0') {
		Store_field(tuple, 1, Val_none);
	} else {
		Store_field(tuple, 1, caml_alloc_some(caml_copy_string(source)));
	}
	Store_field(tuple, 2, zprop_source_to_sources(src));
	CAMLreturn (caml_alloc_some(tuple));
}
