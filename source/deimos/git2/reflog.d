module deimos.git2.reflog;

import deimos.git2.common;
import deimos.git2.oid;
import deimos.git2.types;

extern (C):

int git_reflog_read(git_reflog **out_, git_repository *repo,  const(char)* name);
int git_reflog_write(git_reflog *reflog);
int git_reflog_append(git_reflog *reflog, const(git_oid)* id, const(git_signature)* committer, const(char)* msg);
int git_reflog_rename(git_repository *repo, const(char)* old_name, const(char)* name);
int git_reflog_delete(git_repository *repo, const(char)* name);
size_t git_reflog_entrycount(git_reflog *reflog);
const(git_reflog_entry)* git_reflog_entry_byindex(const(git_reflog)* reflog, size_t idx);
int git_reflog_drop(
	git_reflog *reflog,
	size_t idx,
	int rewrite_previous_entry);
const(git_oid)*  git_reflog_entry_id_old(const(git_reflog_entry)* entry);
const(git_oid)*  git_reflog_entry_id_new(const(git_reflog_entry)* entry);
const(git_signature)*  git_reflog_entry_committer(const(git_reflog_entry)* entry);
const(char)*  git_reflog_entry_message(const(git_reflog_entry)* entry);
void git_reflog_free(git_reflog *reflog);