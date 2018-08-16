
  $ cat >> $HGRCPATH <<EOF
  > [extensions]
  > rebase=
  > strip=
  > 
  > [phases]
  > publish=False
  > EOF

Create repo a:

  $ hg init a
  $ cd a
  $ hg unbundle "$TESTDIR/bundles/rebase.hg"
  adding changesets
  adding manifests
  adding file changes
  added 8 changesets with 7 changes to 7 files (+2 heads)
  new changesets cd010b8cd998:02de42196ebe
  (run 'hg heads' to see heads, 'hg merge' to merge)
  $ hg up tip
  3 files updated, 0 files merged, 0 files removed, 0 files unresolved

  $ tglog
  @  7: 02de42196ebe 'H'
  |
  | o  6: eea13746799a 'G'
  |/|
  o |  5: 24b6387c8c8c 'F'
  | |
  | o  4: 9520eea781bc 'E'
  |/
  | o  3: 32af7686d403 'D'
  | |
  | o  2: 5fddd98957c8 'C'
  | |
  | o  1: 42ccdea3bb16 'B'
  |/
  o  0: cd010b8cd998 'A'
  
  $ cd ..


Rebasing B onto H and collapsing changesets with different phases:


  $ hg clone -q -u 3 a a1
  $ cd a1

  $ hg phase --force --secret 3

  $ cat > $TESTTMP/editor.sh <<EOF
  > echo "==== before editing"
  > cat \$1
  > echo "===="
  > echo "edited manually" >> \$1
  > EOF
  $ HGEDITOR="sh $TESTTMP/editor.sh" hg rebase --collapse --keepbranches -e --dest 7
  rebasing 1:42ccdea3bb16 "B"
  rebasing 2:5fddd98957c8 "C"
  rebasing 3:32af7686d403 "D"
  ==== before editing
  Collapsed revision
  * B
  * C
  * D
  
  
  HG: Enter commit message.  Lines beginning with 'HG:' are removed.
  HG: Leave message empty to abort commit.
  HG: --
  HG: user: Nicolas Dumazet <nicdumz.commits@gmail.com>
  HG: branch 'default'
  HG: added B
  HG: added C
  HG: added D
  ====
  saved backup bundle to $TESTTMP/a1/.hg/strip-backup/42ccdea3bb16-3cb021d3-rebase.hg

  $ tglogp
  @  5: 30882080ba93 secret 'Collapsed revision
  |  * B
  |  * C
  |  * D
  |
  |
  |  edited manually'
  o  4: 02de42196ebe draft 'H'
  |
  | o  3: eea13746799a draft 'G'
  |/|
  o |  2: 24b6387c8c8c draft 'F'
  | |
  | o  1: 9520eea781bc draft 'E'
  |/
  o  0: cd010b8cd998 draft 'A'
  
  $ hg manifest --rev tip
  A
  B
  C
  D
  F
  H

  $ cd ..


Rebasing E onto H:

  $ hg clone -q -u . a a2
  $ cd a2

  $ hg phase --force --secret 6
  $ hg rebase --source 4 --collapse --dest 7
  rebasing 4:9520eea781bc "E"
  rebasing 6:eea13746799a "G"
  saved backup bundle to $TESTTMP/a2/.hg/strip-backup/9520eea781bc-fcd8edd4-rebase.hg

  $ tglog
  o  6: 7dd333a2d1e4 'Collapsed revision
  |  * E
  |  * G'
  @  5: 02de42196ebe 'H'
  |
  o  4: 24b6387c8c8c 'F'
  |
  | o  3: 32af7686d403 'D'
  | |
  | o  2: 5fddd98957c8 'C'
  | |
  | o  1: 42ccdea3bb16 'B'
  |/
  o  0: cd010b8cd998 'A'
  
  $ hg manifest --rev tip
  A
  E
  F
  H

  $ cd ..

Rebasing G onto H with custom message:

  $ hg clone -q -u . a a3
  $ cd a3

  $ hg rebase --base 6 -m 'custom message'
  abort: message can only be specified with collapse
  [255]

  $ cat > $TESTTMP/checkeditform.sh <<EOF
  > env | grep HGEDITFORM
  > true
  > EOF
  $ HGEDITOR="sh $TESTTMP/checkeditform.sh" hg rebase --source 4 --collapse -m 'custom message' -e --dest 7
  rebasing 4:9520eea781bc "E"
  rebasing 6:eea13746799a "G"
  HGEDITFORM=rebase.collapse
  saved backup bundle to $TESTTMP/a3/.hg/strip-backup/9520eea781bc-fcd8edd4-rebase.hg

  $ tglog
  o  6: 38ed6a6b026b 'custom message'
  |
  @  5: 02de42196ebe 'H'
  |
  o  4: 24b6387c8c8c 'F'
  |
  | o  3: 32af7686d403 'D'
  | |
  | o  2: 5fddd98957c8 'C'
  | |
  | o  1: 42ccdea3bb16 'B'
  |/
  o  0: cd010b8cd998 'A'
  
  $ hg manifest --rev tip
  A
  E
  F
  H

  $ cd ..

Create repo b:

  $ hg init b
  $ cd b

  $ echo A > A
  $ hg ci -Am A
  adding A
  $ echo B > B
  $ hg ci -Am B
  adding B

  $ hg up -q 0

  $ echo C > C
  $ hg ci -Am C
  adding C

  $ hg merge
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  (branch merge, don't forget to commit)

  $ echo D > D
  $ hg ci -Am D
  adding D

  $ hg up -q 1

  $ echo E > E
  $ hg ci -Am E
  adding E

  $ echo F > F
  $ hg ci -Am F
  adding F

  $ hg merge
  2 files updated, 0 files merged, 0 files removed, 0 files unresolved
  (branch merge, don't forget to commit)
  $ hg ci -m G

  $ hg up -q 0

  $ echo H > H
  $ hg ci -Am H
  adding H

  $ tglog
  @  7: c65502d41787 'H'
  |
  | o    6: c772a8b2dc17 'G'
  | |\
  | | o  5: 7f219660301f 'F'
  | | |
  | | o  4: 8a5212ebc852 'E'
  | | |
  | o |  3: 2870ad076e54 'D'
  | |\|
  | o |  2: c5cefa58fd55 'C'
  |/ /
  | o  1: 27547f69f254 'B'
  |/
  o  0: 4a2df7238c3b 'A'
  
  $ cd ..


Rebase and collapse - more than one external (fail):

  $ hg clone -q -u . b b1
  $ cd b1

  $ hg rebase -s 2 --dest 7 --collapse
  abort: unable to collapse on top of 7, there is more than one external parent: 1, 5
  [255]

Rebase and collapse - E onto H:

  $ hg rebase -s 4 --dest 7 --collapse # root (4) is not a merge
  rebasing 4:8a5212ebc852 "E"
  rebasing 5:7f219660301f "F"
  rebasing 6:c772a8b2dc17 "G"
  saved backup bundle to $TESTTMP/b1/.hg/strip-backup/8a5212ebc852-75046b61-rebase.hg

  $ tglog
  o    5: f97c4725bd99 'Collapsed revision
  |\   * E
  | |  * F
  | |  * G'
  | @  4: c65502d41787 'H'
  | |
  o |    3: 2870ad076e54 'D'
  |\ \
  | o |  2: c5cefa58fd55 'C'
  | |/
  o /  1: 27547f69f254 'B'
  |/
  o  0: 4a2df7238c3b 'A'
  
  $ hg manifest --rev tip
  A
  C
  D
  E
  F
  H

  $ cd ..




Test that branchheads cache is updated correctly when doing a strip in which
the parent of the ancestor node to be stripped does not become a head and also,
the parent of a node that is a child of the node stripped becomes a head (node
3). The code is now much simpler and we could just test a simpler scenario
We keep it the test this way in case new complexity is injected.

  $ hg clone -q -u . b b2
  $ cd b2

  $ hg heads --template="{rev}:{node} {branch}\n"
  7:c65502d4178782309ce0574c5ae6ee9485a9bafa default
  6:c772a8b2dc17629cec88a19d09c926c4814b12c7 default

  $ cat $TESTTMP/b2/.hg/cache/branch2-served
  c65502d4178782309ce0574c5ae6ee9485a9bafa 7
  c772a8b2dc17629cec88a19d09c926c4814b12c7 o default
  c65502d4178782309ce0574c5ae6ee9485a9bafa o default

  $ hg strip 4
  saved backup bundle to $TESTTMP/b2/.hg/strip-backup/8a5212ebc852-75046b61-backup.hg

  $ cat $TESTTMP/b2/.hg/cache/branch2-served
  c65502d4178782309ce0574c5ae6ee9485a9bafa 4
  2870ad076e541e714f3c2bc32826b5c6a6e5b040 o default
  c65502d4178782309ce0574c5ae6ee9485a9bafa o default

  $ hg heads --template="{rev}:{node} {branch}\n"
  4:c65502d4178782309ce0574c5ae6ee9485a9bafa default
  3:2870ad076e541e714f3c2bc32826b5c6a6e5b040 default

  $ cd ..






Create repo c:

  $ hg init c
  $ cd c

  $ echo A > A
  $ hg ci -Am A
  adding A
  $ echo B > B
  $ hg ci -Am B
  adding B

  $ hg up -q 0

  $ echo C > C
  $ hg ci -Am C
  adding C

  $ hg merge
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  (branch merge, don't forget to commit)

  $ echo D > D
  $ hg ci -Am D
  adding D

  $ hg up -q 1

  $ echo E > E
  $ hg ci -Am E
  adding E
  $ echo F > E
  $ hg ci -m 'F'

  $ echo G > G
  $ hg ci -Am G
  adding G

  $ hg merge
  2 files updated, 0 files merged, 0 files removed, 0 files unresolved
  (branch merge, don't forget to commit)

  $ hg ci -m H

  $ hg up -q 0

  $ echo I > I
  $ hg ci -Am I
  adding I

  $ tglog
  @  8: 46d6f0e29c20 'I'
  |
  | o    7: 417d3b648079 'H'
  | |\
  | | o  6: 55a44ad28289 'G'
  | | |
  | | o  5: dca5924bb570 'F'
  | | |
  | | o  4: 8a5212ebc852 'E'
  | | |
  | o |  3: 2870ad076e54 'D'
  | |\|
  | o |  2: c5cefa58fd55 'C'
  |/ /
  | o  1: 27547f69f254 'B'
  |/
  o  0: 4a2df7238c3b 'A'
  
  $ cd ..


Rebase and collapse - E onto I:

  $ hg clone -q -u . c c1
  $ cd c1

  $ hg rebase -s 4 --dest 8 --collapse # root (4) is not a merge
  rebasing 4:8a5212ebc852 "E"
  rebasing 5:dca5924bb570 "F"
  merging E
  rebasing 6:55a44ad28289 "G"
  rebasing 7:417d3b648079 "H"
  saved backup bundle to $TESTTMP/c1/.hg/strip-backup/8a5212ebc852-f95d0879-rebase.hg

  $ tglog
  o    5: 340b34a63b39 'Collapsed revision
  |\   * E
  | |  * F
  | |  * G
  | |  * H'
  | @  4: 46d6f0e29c20 'I'
  | |
  o |    3: 2870ad076e54 'D'
  |\ \
  | o |  2: c5cefa58fd55 'C'
  | |/
  o /  1: 27547f69f254 'B'
  |/
  o  0: 4a2df7238c3b 'A'
  
  $ hg manifest --rev tip
  A
  C
  D
  E
  G
  I

  $ hg up tip -q
  $ cat E
  F

  $ cd ..


Create repo d:

  $ hg init d
  $ cd d

  $ echo A > A
  $ hg ci -Am A
  adding A
  $ echo B > B
  $ hg ci -Am B
  adding B
  $ echo C > C
  $ hg ci -Am C
  adding C

  $ hg up -q 1

  $ echo D > D
  $ hg ci -Am D
  adding D
  $ hg merge
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  (branch merge, don't forget to commit)

  $ hg ci -m E

  $ hg up -q 0

  $ echo F > F
  $ hg ci -Am F
  adding F

  $ tglog
  @  5: c137c2b8081f 'F'
  |
  | o    4: 0a42590ed746 'E'
  | |\
  | | o  3: 7bbcd6078bcc 'D'
  | | |
  | o |  2: f838bfaca5c7 'C'
  | |/
  | o  1: 27547f69f254 'B'
  |/
  o  0: 4a2df7238c3b 'A'
  
  $ cd ..


Rebase and collapse - B onto F:

  $ hg clone -q -u . d d1
  $ cd d1

  $ hg rebase -s 1 --collapse --dest 5
  rebasing 1:27547f69f254 "B"
  rebasing 2:f838bfaca5c7 "C"
  rebasing 3:7bbcd6078bcc "D"
  rebasing 4:0a42590ed746 "E"
  saved backup bundle to $TESTTMP/d1/.hg/strip-backup/27547f69f254-9a3f7d92-rebase.hg

  $ tglog
  o  2: b72eaccb283f 'Collapsed revision
  |  * B
  |  * C
  |  * D
  |  * E'
  @  1: c137c2b8081f 'F'
  |
  o  0: 4a2df7238c3b 'A'
  
  $ hg manifest --rev tip
  A
  B
  C
  D
  F

Interactions between collapse and keepbranches
  $ cd ..
  $ hg init e
  $ cd e
  $ echo 'a' > a
  $ hg ci -Am 'A'
  adding a

  $ hg branch 'one'
  marked working directory as branch one
  (branches are permanent and global, did you want a bookmark?)
  $ echo 'b' > b
  $ hg ci -Am 'B'
  adding b

  $ hg branch 'two'
  marked working directory as branch two
  $ echo 'c' > c
  $ hg ci -Am 'C'
  adding c

  $ hg up -q 0
  $ echo 'd' > d
  $ hg ci -Am 'D'
  adding d

  $ tglog
  @  3: 41acb9dca9eb 'D'
  |
  | o  2: 8ac4a08debf1 'C'  two
  | |
  | o  1: 1ba175478953 'B'  one
  |/
  o  0: 1994f17a630e 'A'
  
  $ hg rebase --keepbranches --collapse -s 1 -d 3
  abort: cannot collapse multiple named branches
  [255]

  $ repeatchange() {
  >   hg checkout $1
  >   hg cp d z
  >   echo blah >> z
  >   hg commit -Am "$2" --user "$3"
  > }
  $ repeatchange 3 "E" "user1"
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ repeatchange 3 "E" "user2"
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ tglog
  @  5: fbfb97b1089a 'E'
  |
  | o  4: f338eb3c2c7c 'E'
  |/
  o  3: 41acb9dca9eb 'D'
  |
  | o  2: 8ac4a08debf1 'C'  two
  | |
  | o  1: 1ba175478953 'B'  one
  |/
  o  0: 1994f17a630e 'A'
  
  $ hg rebase -s 5 -d 4
  rebasing 5:fbfb97b1089a "E" (tip)
  note: rebase of 5:fbfb97b1089a created no changes to commit
  saved backup bundle to $TESTTMP/e/.hg/strip-backup/fbfb97b1089a-553e1d85-rebase.hg
  $ tglog
  @  4: f338eb3c2c7c 'E'
  |
  o  3: 41acb9dca9eb 'D'
  |
  | o  2: 8ac4a08debf1 'C'  two
  | |
  | o  1: 1ba175478953 'B'  one
  |/
  o  0: 1994f17a630e 'A'
  
  $ hg export tip
  # HG changeset patch
  # User user1
  # Date 0 0
  #      Thu Jan 01 00:00:00 1970 +0000
  # Node ID f338eb3c2c7cc5b5915676a2376ba7ac558c5213
  # Parent  41acb9dca9eb976e84cd21fcb756b4afa5a35c09
  E
  
  diff -r 41acb9dca9eb -r f338eb3c2c7c z
  --- /dev/null	Thu Jan 01 00:00:00 1970 +0000
  +++ b/z	Thu Jan 01 00:00:00 1970 +0000
  @@ -0,0 +1,2 @@
  +d
  +blah

  $ cd ..

Rebase, collapse and copies

  $ hg init copies
  $ cd copies
  $ hg unbundle "$TESTDIR/bundles/renames.hg"
  adding changesets
  adding manifests
  adding file changes
  added 4 changesets with 11 changes to 7 files (+1 heads)
  new changesets f447d5abf5ea:338e84e2e558
  (run 'hg heads' to see heads, 'hg merge' to merge)
  $ hg up -q tip
  $ tglog
  @  3: 338e84e2e558 'move2'
  |
  o  2: 6e7340ee38c0 'move1'
  |
  | o  1: 1352765a01d4 'change'
  |/
  o  0: f447d5abf5ea 'add'
  
  $ hg rebase --collapse -d 1
  rebasing 2:6e7340ee38c0 "move1"
  merging a and d to d
  merging b and e to e
  merging c and f to f
  rebasing 3:338e84e2e558 "move2" (tip)
  merging f and c to c
  merging e and g to g
  saved backup bundle to $TESTTMP/copies/.hg/strip-backup/6e7340ee38c0-ef8ef003-rebase.hg
  $ hg st
  $ hg st --copies --change tip
  A d
    a
  A g
    b
  R b
  $ hg up tip -q
  $ cat c
  c
  c
  $ cat d
  a
  a
  $ cat g
  b
  b
  $ hg log -r . --template "{file_copies}\n"
  d (a)g (b)

Test collapsing a middle revision in-place

  $ tglog
  @  2: 64b456429f67 'Collapsed revision
  |  * move1
  |  * move2'
  o  1: 1352765a01d4 'change'
  |
  o  0: f447d5abf5ea 'add'
  
  $ hg rebase --collapse -r 1 -d 0
  abort: can't remove original changesets with unrebased descendants
  (use --keep to keep original changesets)
  [255]

Test collapsing in place

  $ hg rebase --collapse -b . -d 0
  rebasing 1:1352765a01d4 "change"
  rebasing 2:64b456429f67 "Collapsed revision" (tip)
  saved backup bundle to $TESTTMP/copies/.hg/strip-backup/1352765a01d4-45a352ea-rebase.hg
  $ hg st --change tip --copies
  M a
  M c
  A d
    a
  A g
    b
  R b
  $ hg up tip -q
  $ cat a
  a
  a
  $ cat c
  c
  c
  $ cat d
  a
  a
  $ cat g
  b
  b
  $ cd ..


Test stripping a revision with another child

  $ hg init f
  $ cd f

  $ echo A > A
  $ hg ci -Am A
  adding A
  $ echo B > B
  $ hg ci -Am B
  adding B

  $ hg up -q 0

  $ echo C > C
  $ hg ci -Am C
  adding C

  $ tglog
  @  2: c5cefa58fd55 'C'
  |
  | o  1: 27547f69f254 'B'
  |/
  o  0: 4a2df7238c3b 'A'
  


  $ hg heads --template="{rev}:{node} {branch}: {desc}\n"
  2:c5cefa58fd557f84b72b87f970135984337acbc5 default: C
  1:27547f69f25460a52fff66ad004e58da7ad3fb56 default: B

  $ hg strip 2
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  saved backup bundle to $TESTTMP/f/.hg/strip-backup/c5cefa58fd55-629429f4-backup.hg

  $ tglog
  o  1: 27547f69f254 'B'
  |
  @  0: 4a2df7238c3b 'A'
  


  $ hg heads --template="{rev}:{node} {branch}: {desc}\n"
  1:27547f69f25460a52fff66ad004e58da7ad3fb56 default: B

  $ cd ..

Test collapsing changes that add then remove a file

  $ hg init collapseaddremove
  $ cd collapseaddremove

  $ touch base
  $ hg commit -Am base
  adding base
  $ touch a
  $ hg commit -Am a
  adding a
  $ hg rm a
  $ touch b
  $ hg commit -Am b
  adding b
  $ hg book foo
  $ hg rebase -d 0 -r "1::2" --collapse -m collapsed
  rebasing 1:6d8d9f24eec3 "a"
  rebasing 2:1cc73eca5ecc "b" (foo tip)
  saved backup bundle to $TESTTMP/collapseaddremove/.hg/strip-backup/6d8d9f24eec3-77d3b6e2-rebase.hg
  $ hg log -G --template "{rev}: '{desc}' {bookmarks}"
  @  1: 'collapsed' foo
  |
  o  0: 'base'
  
  $ hg manifest --rev tip
  b
  base

  $ cd ..

Test that rebase --collapse will remember message after
running into merge conflict and invoking rebase --continue.

  $ hg init collapse_remember_message
  $ cd collapse_remember_message
  $ touch a
  $ hg add a
  $ hg commit -m "a"
  $ echo "a-default" > a
  $ hg commit -m "a-default"
  $ hg update -r 0
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg branch dev
  marked working directory as branch dev
  (branches are permanent and global, did you want a bookmark?)
  $ echo "a-dev" > a
  $ hg commit -m "a-dev"
  $ hg rebase --collapse -m "a-default-dev" -d 1
  rebasing 2:b8d8db2b242d "a-dev" (tip)
  merging a
  warning: conflicts while merging a! (edit, then use 'hg resolve --mark')
  unresolved conflicts (see hg resolve, then hg rebase --continue)
  [1]
  $ rm a.orig
  $ hg resolve --mark a
  (no more unresolved files)
  continue: hg rebase --continue
  $ hg rebase --continue
  rebasing 2:b8d8db2b242d "a-dev" (tip)
  saved backup bundle to $TESTTMP/collapse_remember_message/.hg/strip-backup/b8d8db2b242d-f474c19a-rebase.hg
  $ hg log
  changeset:   2:45ba1d1a8665
  tag:         tip
  user:        test
  date:        Thu Jan 01 00:00:00 1970 +0000
  summary:     a-default-dev
  
  changeset:   1:3c8db56a44bc
  user:        test
  date:        Thu Jan 01 00:00:00 1970 +0000
  summary:     a-default
  
  changeset:   0:3903775176ed
  user:        test
  date:        Thu Jan 01 00:00:00 1970 +0000
  summary:     a
  
  $ cd ..
