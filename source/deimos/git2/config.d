module deimos.git2.config;

import deimos.git2.common;
import deimos.git2.types;
import deimos.git2.util;

extern (C):

struct git_config_entry {
	const(char)* name;
	const(char)* value;
	git_config_level_t level;
}

enum git_config_level_t {
	GIT_CONFIG_LEVEL_SYSTEM = 1,
	GIT_CONFIG_LEVEL_XDG = 2,
	GIT_CONFIG_LEVEL_GLOBAL = 3,
	GIT_CONFIG_LEVEL_LOCAL = 4,
	GIT_CONFIG_LEVEL_APP = 5,
	GIT_CONFIG_HIGHEST_LEVEL = -1,
}
mixin _ExportEnumMembers!git_config_level_t;

struct git_config_iterator {
	git_config_backend *backend;
	uint flags;
	int function(git_config_entry **entry, git_config_iterator *iter) next;
	void function(git_config_iterator *iter) free;
}

struct git_config_backend {
	uint version_ = GIT_CONFIG_BACKEND_VERSION;
	git_config *cfg;

	int function(git_config_backend *, git_config_level_t level) open;
	int function(const(git_config_backend)*, const(char)* key, const(git_config_entry)** entry) get;
	int function(git_config_backend *, const(char)* key, const(char)* value) set;
	int function(git_config_backend *cfg, const(char)* name, const(char)* regexp, const(char)* value) set_multivar;
	int function(git_config_backend *, const(char)* key) del;
	int function(git_config_backend *, const(char)* key, const(char)* regexp) del_multivar;
	int function(git_config_iterator **, git_config_backend *) iterator;
	int function(git_config_backend *) refresh;
	void function(git_config_backend *) free;
}

enum GIT_CONFIG_BACKEND_VERSION = 1;
enum git_config_backend GIT_CONFIG_BACKEND_INIT = { GIT_CONFIG_BACKEND_VERSION };

int git_config_add_backend(
	git_config *cfg,
	git_config_backend *file,
	git_config_level_t level,
	int force);

alias git_config_foreach_cb = int function(const(git_config_entry)*, void *);

enum git_cvar_t {
	GIT_CVAR_FALSE = 0,
	GIT_CVAR_TRUE = 1,
	GIT_CVAR_INT32,
	GIT_CVAR_STRING
}
mixin _ExportEnumMembers!git_cvar_t;

struct git_cvar_map {
	git_cvar_t cvar_type;
	const(char)* str_match;
	int map_value;
}

int git_config_find_global(char *out_, size_t length);
int git_config_find_xdg(char *out_, size_t length);
int git_config_find_system(char *out_, size_t length);
int git_config_open_default(git_config **out_);
int git_config_new(git_config **out_);
int git_config_add_file_ondisk(
	git_config *cfg,
	const(char)* path,
	git_config_level_t level,
	int force);
int git_config_open_ondisk(git_config **out_, const(char)* path);
int git_config_open_level(
	git_config **out_,
	const(git_config)* parent,
	git_config_level_t level);
int git_config_open_global(git_config **out_, git_config *config);
int git_config_refresh(git_config *cfg);
void git_config_free(git_config *cfg);
int git_config_get_entry(
	const(git_config_entry)** out_,
	const(git_config)* cfg,
	const(char)* name);
int git_config_get_int32(int32_t *out_, const(git_config)* cfg, const(char)* name);
int git_config_get_int64(int64_t *out_, const(git_config)* cfg, const(char)* name);
int git_config_get_bool(int *out_, const(git_config)* cfg, const(char)* name);
int git_config_get_string(const(char)** out_, const(git_config)* cfg, const(char)* name);
int git_config_get_multivar_foreach(const(git_config)* cfg, const(char)* name, const(char)* regexp, git_config_foreach_cb callback, void *payload);
int git_config_multivar_iterator_new(git_config_iterator** out_, const(git_config)* cfg, const(char)* name, const(char)* regexp);
int git_config_next(git_config_entry** entry, git_config_iterator *iter);
void git_config_iterator_free(git_config_iterator *iter);
int git_config_set_int32(git_config *cfg, const(char)* name, int32_t value);
int git_config_set_int64(git_config *cfg, const(char)* name, int64_t value);
int git_config_set_bool(git_config *cfg, const(char)* name, int value);
int git_config_set_string(git_config *cfg, const(char)* name, const(char)* value);
int git_config_set_multivar(git_config *cfg, const(char)* name, const(char)* regexp, const(char)* value);
int git_config_delete_entry(git_config *cfg, const(char)* name);
int git_config_delete_multivar(git_config *cfg, const(char)* name, const(char)* regexp);
int git_config_foreach(
	const(git_config)* cfg,
	git_config_foreach_cb callback,
	void *payload);
int git_config_iterator_new(git_config_iterator** out_, const(git_config)* cfg);
int git_config_iterator_glob_new(git_config_iterator** out_, const(git_config)* cfg, const(char)* regexp);
int git_config_foreach_match(
	const(git_config)* cfg,
	const(char)* regexp,
	git_config_foreach_cb callback,
	void *payload);
int git_config_get_mapped(
	int *out_,
	const(git_config)* cfg,
	const(char)* name,
	const(git_cvar_map)* maps,
	size_t map_n);
int git_config_lookup_map_value(
	int *out_,
	const(git_cvar_map)* maps,
	size_t map_n,
	const(char)* value);
int git_config_parse_bool(int *out_, const(char)* value);
int git_config_parse_int32(int32_t *out_, const(char)* value);
int git_config_parse_int64(int64_t *out_, const(char)* value);
int git_config_backend_foreach_match(
	git_config_backend *backend,
	const(char)* regexp,
	int function(const(git_config_entry)*, void*) fn,
	void *data);
