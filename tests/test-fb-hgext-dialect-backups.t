  $ cat >> $HGRCPATH << EOF
  > [extensions]
  > backups=
  > dialect=
  > EOF

  $ hg help -e backups | head -n 1
  backups extension - display recently made backups to recover stripped commits
