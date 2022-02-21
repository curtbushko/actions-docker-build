#!/usr/bin/env bats

load assertions

setup() {
	set_all_env_vars

	SCRIPT_ROOT="$PWD"
	TEST_ROOT="testdata/input"

	# Get test relative paths to tarballs, needed for assertions,
	# and remove them now so tests don't read stale tarballs.
	export TARBALL_PATH="$TEST_ROOT/$TARBALL_NAME"
	export DEV_TARBALL_PATH="$TEST_ROOT/$DEV_TARBALL_NAME"
	rm -rf "$DEV_TARBALL_PATH"
	rm -rf "$TARBALL_PATH"
}

set_all_required_env_vars() {
	export BIN_NAME=test_bin
	export VERSION=1.2.3
	export REVISION=cabba9e
	export DOCKERFILE=Dockerfile
	export TARGET=default
	export TARBALL_NAME=blahblah.docker.tar
	export PLATFORM="linux/amd64"
	export AUTO_TAG="some/auto/tag:1.2.3-deadbeef"
	export TAGS=""
}

set_all_optional_env_vars() {
	export WORKDIR=""
	export DEV_TARBALL_NAME=blahblah.docker.dev.tar
	export DEV_TAGS=""
}

set_all_env_vars() {
	set_all_required_env_vars
	set_all_optional_env_vars
}


set_test_prod_tags() {
	PROD_TAG1=dadgarcorp/repo1:1.2.3
	PROD_TAG2=public.ecr.aws/dadgarcorp/repo1:1.2.3

	export TAGS="
		$PROD_TAG1
		$PROD_TAG2
	"
}

set_test_dev_tags() {
	DEV_TAG1=dadgarcorp/repo1:1.2.3-dev
	DEV_TAG2=dadgarcorp/repo1/dev:1

	export DEV_TAGS="
		$DEV_TAG1
		$DEV_TAG2
	"
}

@test "only prod tags set - all prod and staging tags built" {

	set_test_prod_tags
	
	# Execute the script under test: docker_build
	(
		cd "$TEST_ROOT"
		"$SCRIPT_ROOT/docker_build"
	)

	assert_tarball_contains_tags "$TARBALL_PATH" "$PROD_TAG1" "$PROD_TAG2" "$AUTO_TAG"
}

PROD_DEV="prod and dev tags provided"

build_prod_and_dev_tags() {

	set_test_prod_tags
	set_test_dev_tags
	
	# Execute the script under test: docker_build
	(
		cd "$TEST_ROOT"
		"$SCRIPT_ROOT/docker_build"
	)
}

@test "$PROD_DEV / prod tarball contains prod tags and the auto tag" {
	build_prod_and_dev_tags
	assert_tarball_contains_tags "$TARBALL_PATH" "$PROD_TAG1" "$PROD_TAG2" "$AUTO_TAG"
}

@test "$PROD_DEV / dev tarball contains dev tags and the auto tag" {
	build_prod_and_dev_tags
	assert_tarball_contains_tags "$DEV_TARBALL_PATH" "$DEV_TAG1" "$DEV_TAG2" "$AUTO_TAG"	
}

@test "$PROD_DEV / dev tarball does not contain prod tags" {
	build_prod_and_dev_tags
	assert_tarball_not_contains_tags "$DEV_TARBALL_PATH" "$PROD_TAG1" "$PROD_TAG2"
}

@test "$PROD_DEV / prod tarball does not contain dev tags" {
	build_prod_and_dev_tags
	assert_tarball_not_contains_tags "$TARBALL_PATH" "$DEV_TAG1" "$DEV_TAG2"
}