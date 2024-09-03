module deimos.git2.odb_backend;

import deimos.git2.common;
import deimos.git2.oid;
import deimos.git2.util;
import deimos.git2.types;

extern (C):

alias git_odb_foreach_cb = int function(const(git_oid)* id, void *payload);

struct git_odb_backend {
	uint version_ = GIT_ODB_BACKEND_VERSION;
	git_odb *odb;
	int function(
		void **, size_t *, git_otype *, git_odb_backend *, const(git_oid)* ) read;
	int function(
		git_oid *, void **, size_t *, git_otype *,
		git_odb_backend *, const(git_oid)* , size_t) read_prefix;
	int function(
		size_t *, git_otype *, git_odb_backend *, const(git_oid)* ) read_header;
	int function(
		git_odb_backend *, const git_oid *, const void *, size_t, git_otype) write;
	int function(
		git_odb_stream **, git_odb_backend *, size_t, git_otype) writestream;
	int function(
		git_odb_stream **, git_odb_backend *, const(git_oid)* ) readstream;
	int function(
		git_odb_backend *, const(git_oid)* ) exists;
	int function(git_odb_backend *) refresh;
	int function(
		git_odb_backend *, git_odb_foreach_cb cb, void *payload) foreach_;
	int function(
		git_odb_writepack **, git_odb_backend *, git_odb *odb,
		git_transfer_progress_cb progress_cb, void *progress_payload) writepack;
	void function(git_odb_backend *) free;
}

enum GIT_ODB_BACKEND_VERSION = 1;
enum git_odb_backend GIT_ODB_BACKEND_INIT = { GIT_ODB_BACKEND_VERSION };

void * git_odb_backend_malloc(git_odb_backend *backend, size_t len);

int git_odb_backend_pack(git_odb_backend **out_, const(char)* objects_dir);
int git_odb_backend_loose(
	git_odb_backend **out_,
	const(char)* objects_dir,
	int compression_level,
	int do_fsync,
	uint dir_mode,
	uint file_mode);
int git_odb_backend_one_pack(git_odb_backend **out_, const(char)* index_file);

enum git_odb_stream_t {
	GIT_STREAM_RDONLY = (1 << 1),
	GIT_STREAM_WRONLY = (1 << 2),
	GIT_STREAM_RW = (GIT_STREAM_RDONLY | GIT_STREAM_WRONLY),
}
mixin _ExportEnumMembers!git_odb_stream_t;

struct git_odb_stream {
	git_odb_backend *backend;
	uint mode;
	void *hash_ctx;

	size_t declared_size;
	size_t received_bytes;

	int function(git_odb_stream *stream, char *buffer, size_t len) read;
	int function(git_odb_stream *stream, const(char)* buffer, size_t len) write;
	int function(git_odb_stream *stream, const(git_oid)* oid) finalize_write;
	void function(git_odb_stream *stream) free;
}

struct git_odb_writepack
{
	git_odb_backend *backend;

	int  function(git_odb_writepack *writepack, const(void)* data, size_t size, git_transfer_progress *stats) append;
	int  function(git_odb_writepack *writepack, git_transfer_progress *stats) commit;
	void function(git_odb_writepack *writepack) free;
}
