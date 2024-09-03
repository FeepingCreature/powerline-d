module deimos.git2.attr;

import deimos.git2.common;
import deimos.git2.types;
import deimos.git2.util;

extern (C):

bool GIT_ATTR_TRUE(T)(T attr) { return git_attr_value(attr) == git_attr_t.GIT_ATTR_TRUE_T; }
bool GIT_ATTR_FALSE(T)(T attr) { return git_attr_value(attr) == git_attr_t.GIT_ATTR_FALSE_T; }
bool GIT_ATTR_UNSPECIFIED(T)(T attr) { return git_attr_value(attr) == git_attr_t.GIT_ATTR_UNSPECIFIED_T; }
bool GIT_ATTR_HAS_VALUE(T)(T attr) { return git_attr_value(attr) == git_attr_t.GIT_ATTR_VALUE_T; }

enum git_attr_t
{
    GIT_ATTR_UNSPECIFIED_T = 0,
    GIT_ATTR_TRUE_T,
    GIT_ATTR_FALSE_T,
    GIT_ATTR_VALUE_T,
}
mixin _ExportEnumMembers!git_attr_t;

git_attr_t git_attr_value(const(char)* attr);

enum GIT_ATTR_CHECK_FILE_THEN_INDEX	= 0;
enum GIT_ATTR_CHECK_INDEX_THEN_FILE	= 1;
enum GIT_ATTR_CHECK_INDEX_ONLY      = 2;
enum GIT_ATTR_CHECK_NO_SYSTEM = 1 << 2;

int git_attr_get(
	const(char)** value_out,
	git_repository *repo,
	uint32_t flags,
	const(char)* path,
	const(char)* name);
int git_attr_get_many(
	const(char)** values_out,
	git_repository *repo,
	uint32_t flags,
	const(char)* path,
	size_t num_attr,
	const(char)** names);

alias git_attr_foreach_cb = int function(const(char)* name, const(char)* value, void *payload);

int git_attr_foreach(
	git_repository *repo,
	uint32_t flags,
	const(char)* path,
	git_attr_foreach_cb callback,
	void *payload);
void git_attr_cache_flush(
	git_repository *repo);
int git_attr_add_macro(
	git_repository *repo,
	const(char)* name,
	const(char)* values);
