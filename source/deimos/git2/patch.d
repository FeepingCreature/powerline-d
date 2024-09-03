module deimos.git2.patch;

import deimos.git2.common;
import deimos.git2.types;
import deimos.git2.oid;
import deimos.git2.diff;

struct git_patch {
	@disable this();
	@disable this(this);
}

int git_patch_from_diff(
	git_patch **out_, git_diff *diff, size_t idx);
int git_patch_from_blobs(
	git_patch **out_,
	const(git_blob)* old_blob,
	const(char)* old_as_path,
	const(git_blob)* new_blob,
	const(char)* new_as_path,
	const(git_diff_options)* opts);
int git_patch_from_blob_and_buffer(
	git_patch **out_,
	const(git_blob)* old_blob,
	const(char)* old_as_path,
	const(char)* buffer,
	size_t buffer_len,
	const(char)* buffer_as_path,
	const(git_diff_options)* opts);
void git_patch_free(git_patch *patch);
const(git_diff_delta)* git_patch_get_delta(git_patch *patch);
size_t git_patch_num_hunks(git_patch *patch);
int git_patch_line_stats(
	size_t *total_context,
	size_t *total_additions,
	size_t *total_deletions,
	const(git_patch)* patch);
int git_patch_get_hunk(
	const(git_diff_hunk)** out_,
	size_t *lines_in_hunk,
	git_patch *patch,
	size_t hunk_idx);
int git_patch_num_lines_in_hunk(
	git_patch *patch,
	size_t hunk_idx);
int git_patch_get_line_in_hunk(
	const(git_diff_line)** out_,
	git_patch *patch,
	size_t hunk_idx,
	size_t line_of_hunk);
size_t git_patch_size(
	git_patch *patch,
	int include_context,
	int include_hunk_headers,
	int include_file_headers);
int git_patch_print(
	git_patch *patch,
	git_diff_line_cb print_cb,
	void *payload);
int git_patch_to_str(
	char **string,
	git_patch *patch);
