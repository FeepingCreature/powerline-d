module deimos.git2.branch;

import deimos.git2.buffer;
import deimos.git2.common;
import deimos.git2.oid;
import deimos.git2.types;

extern (C):

int git_branch_create(
	git_reference **out_,
	git_repository *repo,
	const(char)* branch_name,
	const(git_commit)* target,
	int force);

int git_branch_create_from_annotated(
    git_reference **ref_out,
    git_repository* repository,
    const(char)* branch_name,
    const(git_annotated_commit)* commit,
    int force);

int git_branch_delete(git_reference *branch);

struct git_branch_iterator {
	@disable this();
	@disable this(this);
}

int git_branch_iterator_new(git_branch_iterator **out_, git_repository *repo, git_branch_t list_flags);
int git_branch_next(git_reference **out_, git_branch_t *out_type, git_branch_iterator *iter);
void git_branch_iterator_free(git_branch_iterator *iter);
int git_branch_move(
	git_reference **out_,
	git_reference *branch,
	const(char)* new_branch_name,
	int force);
int git_branch_lookup(
	git_reference **out_,
	git_repository *repo,
	const(char)* branch_name,
	git_branch_t branch_type);
int git_branch_name(
    const(char)** out_,
    const(git_reference)* ref_);
int git_branch_upstream(
	git_reference **out_,
	const(git_reference)* branch);
int git_branch_set_upstream(git_reference *branch, const(char)* upstream_name);
int git_branch_upstream_name(
	git_buf* out_,
	git_repository *repo,
	const(char)* refname);
int git_branch_is_head(
	const(git_reference)* branch);
int git_branch_remote_name(
	git_buf* out_,
	git_repository *repo,
	const(char)* canonical_branch_name);
int git_branch_upstream_remote(git_buf* buf, git_repository* repo, const(char)* refname);
