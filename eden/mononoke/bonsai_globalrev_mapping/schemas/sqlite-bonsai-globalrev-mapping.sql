/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This software may be used and distributed according to the terms of the
 * GNU General Public License version 2.
 */

CREATE TABLE IF NOT EXISTS bonsai_globalrev_mapping (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  repo_id INTEGER NOT NULL,
  bcs_id BINARY(32) NOT NULL,
  globalrev INTEGER NOT NULL,
  UNIQUE (repo_id, bcs_id),
  UNIQUE (repo_id, globalrev)
);
