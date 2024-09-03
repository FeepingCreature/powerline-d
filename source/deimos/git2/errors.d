module deimos.git2.errors;

import deimos.git2.common;
import deimos.git2.buffer;
import deimos.git2.util;

extern (C):

enum git_error_code {
	GIT_OK = 0,
	GIT_ERROR = -1,
	GIT_ENOTFOUND = -3,
	GIT_EEXISTS = -4,
	GIT_EAMBIGUOUS = -5,
	GIT_EBUFS = -6,
	GIT_EUSER = -7,
	GIT_EBAREREPO = -8,
	GIT_EUNBORNBRANCH = -9,
	GIT_EUNMERGED = -10,
	GIT_ENONFASTFORWARD = -11,
	GIT_EINVALIDSPEC = -12,
	GIT_EMERGECONFLICT = -13,
	GIT_ELOCKED = -14,
    GIT_ECERTIFICATE = -17,

	GIT_PASSTHROUGH = -30,
	GIT_ITEROVER = -31,
}
mixin _ExportEnumMembers!git_error_code;

struct git_error {
	char *message;
	int klass;
}

enum git_error_t {
	GITERR_NONE = 0,
	GITERR_NOMEMORY,
	GITERR_OS,
	GITERR_INVALID,
	GITERR_REFERENCE,
	GITERR_ZLIB,
	GITERR_REPOSITORY,
	GITERR_CONFIG,
	GITERR_REGEX,
	GITERR_ODB,
	GITERR_INDEX,
	GITERR_OBJECT,
	GITERR_NET,
	GITERR_TAG,
	GITERR_TREE,
	GITERR_INDEXER,
	GITERR_SSL,
	GITERR_SUBMODULE,
	GITERR_THREAD,
	GITERR_STASH,
	GITERR_CHECKOUT,
	GITERR_FETCHHEAD,
	GITERR_MERGE,
	GITERR_SSH,
	GITERR_FILTER,
}
mixin _ExportEnumMembers!git_error_t;

const(git_error)*  giterr_last();
void giterr_clear();
int giterr_detach(git_error *cpy);
void giterr_set_str(int error_class, const(char)* string);
void giterr_set_oom();
