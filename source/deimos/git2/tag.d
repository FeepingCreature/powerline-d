module deimos.git2.tag;

import deimos.git2.common;
import deimos.git2.object_;
import deimos.git2.oid;
import deimos.git2.strarray;
import deimos.git2.types;

extern (C):

int git_tag_lookup(
	git_tag **out_, git_repository *repo, const(git_oid)* id);
int git_tag_lookup_prefix(
	git_tag **out_, git_repository *repo, const(git_oid)* id, size_t len);
void git_tag_free(git_tag *tag);
const(git_oid)*  git_tag_id(const(git_tag)* tag);
git_repository * git_tag_owner(const(git_tag)* tag);
int git_tag_target(git_object **target_out, const(git_tag)* tag);
const(git_oid)*  git_tag_target_id(const(git_tag)* tag);
git_otype git_tag_target_type(const(git_tag)* tag);
const(char)*  git_tag_name(const(git_tag)* tag);
const(git_signature)*  git_tag_tagger(const(git_tag)* tag);
const(char)*  git_tag_message(const(git_tag)* tag);
int git_tag_create(
	git_oid *oid,
	git_repository *repo,
	const(char)* tag_name,
	const(git_object)* target,
	const(git_signature)* tagger,
	const(char)* message,
	int force);
int git_tag_annotation_create(
	git_oid *oid,
	git_repository *repo,
	const(char)* tag_name,
	const(git_object)* target,
	const(git_signature)* tagger,
	const(char)* message);
int git_tag_create_frombuffer(
	git_oid *oid,
	git_repository *repo,
	const(char)* buffer,
	int force);
int git_tag_create_lightweight(
	git_oid *oid,
	git_repository *repo,
	const(char)* tag_name,
	const(git_object)* target,
	int force);
int git_tag_delete(
	git_repository *repo,
	const(char)* tag_name);
int git_tag_list(
	git_strarray *tag_names,
	git_repository *repo);
int git_tag_list_match(
	git_strarray *tag_names,
	const(char)* pattern,
	git_repository *repo);

alias git_tag_foreach_cb = int function(const(char)* name, git_oid *oid, void *payload);

int git_tag_foreach(
	git_repository *repo,
	git_tag_foreach_cb callback,
	void *payload);
int git_tag_peel(
	git_object **tag_target_out,
	const(git_tag)* tag);
