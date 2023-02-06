# Copyright (c) Meta Platforms, Inc. and affiliates.
#
# This software may be used and distributed according to the terms of the
# GNU General Public License found in the LICENSE file in the root
# directory of this source tree.

  $ . "${TEST_FIXTURES}/library.sh"

setup configuration
  $ setup_mononoke_config
  $ cd "$TESTTMP/mononoke-config"
  $ cat >> repos/repo/server.toml <<CONFIG
  > [[bookmarks]]
  > name="main"
  > [[bookmarks]]
  > regex=".*"
  > hooks_skip_ancestors_of=["main"]
  > CONFIG

  $ register_hook_limit_filesize_global_limit 10 'bypass_pushvar="ALLOW_LARGE_FILES=true"'

  $ merge_tunables <<EOF
  > {
  >   "killswitches": {
  >     "run_hooks_on_additional_changesets": true
  >   }
  > }
  > EOF

  $ setup_common_hg_configs
  $ cd $TESTTMP

  $ configure dummyssh
  $ enable amend

setup repo
  $ hg init repo-hg
  $ cd repo-hg
  $ setup_hg_server
  $ drawdag <<EOF
  > D F           # C/large = file_too_large
  > | |           # E/large = file_too_large
  > C E    Z      # Y/large = file_too_large
  > |/     |
  > B      Y
  > |      |
  > A      X
  > EOF

  $ hg bookmark main -r $A
  $ hg bookmark head_d -r $D
  $ hg bookmark head_f -r $F
  $ hg bookmark head_z -r $Z

blobimport
  $ cd ..
  $ blobimport repo-hg/.hg repo

start mononoke
  $ start_and_wait_for_mononoke_server
clone
  $ hgclone_treemanifest ssh://user@dummy/repo-hg repo2 --noupdate --config extensions.remotenames= -q
  $ cd repo2
  $ setup_hg_client
  $ enable pushrebase remotenames

fast-forward the bookmark
  $ hg up -q $B
  $ hgmn push -r . --to main
  pushing rev 112478962961 to destination mononoke://$LOCALIP:$LOCAL_PORT/repo bookmark main
  searching for changes
  no changes found
  updating bookmark main

fast-forward the bookmark over a commit that fails the hook
  $ hg up -q $D
  $ hgmn push -r . --to main
  pushing rev 7ff4b7c298ec to destination mononoke://$LOCALIP:$LOCAL_PORT/repo bookmark main
  searching for changes
  no changes found
  remote: Command failed
  remote:   Error:
  remote:     hooks failed:
  remote:     limit_filesize for 5e6585e50f1bf5a236028609e131851379bb311a: File size limit is 10 bytes. You tried to push file large that is over the limit (14 bytes). This limit is enforced for files matching the following regex: ".*". See https://fburl.com/landing_big_diffs for instructions.
  remote: 
  remote:   Root cause:
  remote:     hooks failed:
  remote:     limit_filesize for 5e6585e50f1bf5a236028609e131851379bb311a: File size limit is 10 bytes. You tried to push file large that is over the limit (14 bytes). This limit is enforced for files matching the following regex: ".*". See https://fburl.com/landing_big_diffs for instructions.
  remote: 
  remote:   Debug context:
  remote:     "hooks failed:\nlimit_filesize for 5e6585e50f1bf5a236028609e131851379bb311a: File size limit is 10 bytes. You tried to push file large that is over the limit (14 bytes). This limit is enforced for files matching the following regex: \".*\". See https://fburl.com/landing_big_diffs for instructions."
  abort: unexpected EOL, expected netstring digit
  [255]

bypass the hook, the push will now work
  $ hgmn push -r . --to main --pushvar ALLOW_LARGE_FILES=true
  pushing rev 7ff4b7c298ec to destination mononoke://$LOCALIP:$LOCAL_PORT/repo bookmark main
  searching for changes
  no changes found
  updating bookmark main

attempt a non-fast-forward move, it should fail
  $ hg up -q $F
  $ hgmn push -r . --to main
  pushing rev af09fbbc2f05 to destination mononoke://$LOCALIP:$LOCAL_PORT/repo bookmark main
  searching for changes
  no changes found
  remote: Command failed
  remote:   Error:
  remote:     While doing a bookmark-only pushrebase
  remote: 
  remote:   Root cause:
  remote:     Non fast-forward bookmark move of 'main' from cbe5624248da659ef8f938baaf65796e68252a0a735e885a814b94f38b901d5b to 2b7843b3fb41a99743420b26286cc5e7bc94ebf7576eaf1bbceb70cd36ffe8b0
  remote: 
  remote:   Caused by:
  remote:     Failed to fast-forward bookmark (set pushvar NON_FAST_FORWARD=true for a non-fast-forward move)
  remote:   Caused by:
  remote:     Non fast-forward bookmark move of 'main' from cbe5624248da659ef8f938baaf65796e68252a0a735e885a814b94f38b901d5b to 2b7843b3fb41a99743420b26286cc5e7bc94ebf7576eaf1bbceb70cd36ffe8b0
  remote: 
  remote:   Debug context:
  remote:     Error {
  remote:         context: "While doing a bookmark-only pushrebase",
  remote:         source: Error {
  remote:             context: "Failed to fast-forward bookmark (set pushvar NON_FAST_FORWARD=true for a non-fast-forward move)",
  remote:             source: NonFastForwardMove {
  remote:                 bookmark: BookmarkName {
  remote:                     bookmark: "main",
  remote:                 },
  remote:                 from: ChangesetId(
  remote:                     Blake2(cbe5624248da659ef8f938baaf65796e68252a0a735e885a814b94f38b901d5b),
  remote:                 ),
  remote:                 to: ChangesetId(
  remote:                     Blake2(2b7843b3fb41a99743420b26286cc5e7bc94ebf7576eaf1bbceb70cd36ffe8b0),
  remote:                 ),
  remote:             },
  remote:         },
  remote:     }
  abort: unexpected EOL, expected netstring digit
  [255]

specify the pushvar to allow the non-fast-forward move.
  $ hgmn push -r . --to main --pushvar NON_FAST_FORWARD=true
  pushing rev af09fbbc2f05 to destination mononoke://$LOCALIP:$LOCAL_PORT/repo bookmark main
  searching for changes
  no changes found
  remote: Command failed
  remote:   Error:
  remote:     hooks failed:
  remote:     limit_filesize for 18c1f749e0296aca8bbb023822506c1eff9bc8a9: File size limit is 10 bytes. You tried to push file large that is over the limit (14 bytes). This limit is enforced for files matching the following regex: ".*". See https://fburl.com/landing_big_diffs for instructions.
  remote: 
  remote:   Root cause:
  remote:     hooks failed:
  remote:     limit_filesize for 18c1f749e0296aca8bbb023822506c1eff9bc8a9: File size limit is 10 bytes. You tried to push file large that is over the limit (14 bytes). This limit is enforced for files matching the following regex: ".*". See https://fburl.com/landing_big_diffs for instructions.
  remote: 
  remote:   Debug context:
  remote:     "hooks failed:\nlimit_filesize for 18c1f749e0296aca8bbb023822506c1eff9bc8a9: File size limit is 10 bytes. You tried to push file large that is over the limit (14 bytes). This limit is enforced for files matching the following regex: \".*\". See https://fburl.com/landing_big_diffs for instructions."
  abort: unexpected EOL, expected netstring digit
  [255]

bypass the hook too, and it should work
  $ hgmn push -r . --to main --pushvar NON_FAST_FORWARD=true --pushvar ALLOW_LARGE_FILES=true
  pushing rev af09fbbc2f05 to destination mononoke://$LOCALIP:$LOCAL_PORT/repo bookmark main
  searching for changes
  no changes found
  updating bookmark main

attempt a move to a completely unrelated commit (no common ancestor), with an ancestor that
fails the hook
  $ hg up -q $Z
  $ hgmn push -r . --to main --pushvar NON_FAST_FORWARD=true
  pushing rev e3295448b1ef to destination mononoke://$LOCALIP:$LOCAL_PORT/repo bookmark main
  searching for changes
  no changes found
  remote: Command failed
  remote:   Error:
  remote:     hooks failed:
  remote:     limit_filesize for 1cb9b9c4b7dd2e82083766050d166fffe209df6a: File size limit is 10 bytes. You tried to push file large that is over the limit (14 bytes). This limit is enforced for files matching the following regex: ".*". See https://fburl.com/landing_big_diffs for instructions.
  remote: 
  remote:   Root cause:
  remote:     hooks failed:
  remote:     limit_filesize for 1cb9b9c4b7dd2e82083766050d166fffe209df6a: File size limit is 10 bytes. You tried to push file large that is over the limit (14 bytes). This limit is enforced for files matching the following regex: ".*". See https://fburl.com/landing_big_diffs for instructions.
  remote: 
  remote:   Debug context:
  remote:     "hooks failed:\nlimit_filesize for 1cb9b9c4b7dd2e82083766050d166fffe209df6a: File size limit is 10 bytes. You tried to push file large that is over the limit (14 bytes). This limit is enforced for files matching the following regex: \".*\". See https://fburl.com/landing_big_diffs for instructions."
  abort: unexpected EOL, expected netstring digit
  [255]

bypass the hook, and it should work
  $ hgmn push -r . --to main --pushvar NON_FAST_FORWARD=true --pushvar ALLOW_LARGE_FILES=true
  pushing rev e3295448b1ef to destination mononoke://$LOCALIP:$LOCAL_PORT/repo bookmark main
  searching for changes
  no changes found
  updating bookmark main

pushing another bookmark to the same commit shouldn't require running that hook
  $ hg up -q $X
  $ hgmn push -r . --to other --create
  pushing rev ba2b7fa7166d to destination mononoke://$LOCALIP:$LOCAL_PORT/repo bookmark other
  searching for changes
  no changes found
  exporting bookmark other
  $ hg up -q $Z
  $ hgmn push -r . --to other
  pushing rev e3295448b1ef to destination mononoke://$LOCALIP:$LOCAL_PORT/repo bookmark other
  searching for changes
  no changes found
  updating bookmark other

but pushing to another commit will run the hook
  $ hg up -q $C
  $ hgmn push -r . --to other --pushvar NON_FAST_FORWARD=true
  pushing rev 5e6585e50f1b to destination mononoke://$LOCALIP:$LOCAL_PORT/repo bookmark other
  searching for changes
  no changes found
  remote: Command failed
  remote:   Error:
  remote:     hooks failed:
  remote:     limit_filesize for 5e6585e50f1bf5a236028609e131851379bb311a: File size limit is 10 bytes. You tried to push file large that is over the limit (14 bytes). This limit is enforced for files matching the following regex: ".*". See https://fburl.com/landing_big_diffs for instructions.
  remote: 
  remote:   Root cause:
  remote:     hooks failed:
  remote:     limit_filesize for 5e6585e50f1bf5a236028609e131851379bb311a: File size limit is 10 bytes. You tried to push file large that is over the limit (14 bytes). This limit is enforced for files matching the following regex: ".*". See https://fburl.com/landing_big_diffs for instructions.
  remote: 
  remote:   Debug context:
  remote:     "hooks failed:\nlimit_filesize for 5e6585e50f1bf5a236028609e131851379bb311a: File size limit is 10 bytes. You tried to push file large that is over the limit (14 bytes). This limit is enforced for files matching the following regex: \".*\". See https://fburl.com/landing_big_diffs for instructions."
  abort: unexpected EOL, expected netstring digit
  [255]

bypassing that also works
  $ hgmn push -r . --to other --pushvar NON_FAST_FORWARD=true --pushvar ALLOW_LARGE_FILES=true
  pushing rev 5e6585e50f1b to destination mononoke://$LOCALIP:$LOCAL_PORT/repo bookmark other
  searching for changes
  no changes found
  updating bookmark other

we can now extend that bookmark further without a bypass needed
  $ hg up -q $D
  $ hgmn push -r . --to other
  pushing rev 7ff4b7c298ec to destination mononoke://$LOCALIP:$LOCAL_PORT/repo bookmark other
  searching for changes
  no changes found
  updating bookmark other

create a new bookmark at this location - it should fail because of the hook
  $ hgmn push -r . --to created --create
  pushing rev 7ff4b7c298ec to destination mononoke://$LOCALIP:$LOCAL_PORT/repo bookmark created
  searching for changes
  no changes found
  remote: Command failed
  remote:   Error:
  remote:     hooks failed:
  remote:     limit_filesize for 5e6585e50f1bf5a236028609e131851379bb311a: File size limit is 10 bytes. You tried to push file large that is over the limit (14 bytes). This limit is enforced for files matching the following regex: ".*". See https://fburl.com/landing_big_diffs for instructions.
  remote: 
  remote:   Root cause:
  remote:     hooks failed:
  remote:     limit_filesize for 5e6585e50f1bf5a236028609e131851379bb311a: File size limit is 10 bytes. You tried to push file large that is over the limit (14 bytes). This limit is enforced for files matching the following regex: ".*". See https://fburl.com/landing_big_diffs for instructions.
  remote: 
  remote:   Debug context:
  remote:     "hooks failed:\nlimit_filesize for 5e6585e50f1bf5a236028609e131851379bb311a: File size limit is 10 bytes. You tried to push file large that is over the limit (14 bytes). This limit is enforced for files matching the following regex: \".*\". See https://fburl.com/landing_big_diffs for instructions."
  abort: unexpected EOL, expected netstring digit
  [255]

bypass the hook to allow the creation
  $ hgmn push -r . --to created --create --pushvar ALLOW_LARGE_FILES=true
  pushing rev 7ff4b7c298ec to destination mononoke://$LOCALIP:$LOCAL_PORT/repo bookmark created
  searching for changes
  no changes found
  exporting bookmark created

we can, however, create a bookmark at the same location as main
  $ hgmn push -r $Z --to main-copy --create
  pushing rev e3295448b1ef to destination mononoke://$LOCALIP:$LOCAL_PORT/repo bookmark main-copy
  searching for changes
  no changes found
  exporting bookmark main-copy
