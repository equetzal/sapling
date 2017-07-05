/*
 *  Copyright (c) 2004-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */
#include "TreeEntry.h"

#include <ostream>

namespace facebook {
namespace eden {

std::ostream& operator<<(std::ostream& os, TreeEntryType type) {
  switch (type) {
    case TreeEntryType::TREE:
      os << "TREE";
      return os;
    case TreeEntryType::BLOB:
      os << "BLOB";
      return os;
  }

  os << "TreeEntryType::" << int(type);
  return os;
}

bool operator==(const TreeEntry& entry1, const TreeEntry& entry2) {
  return (entry1.getHash() == entry2.getHash()) &&
      (entry1.getFileType() == entry2.getFileType()) &&
      (entry1.getOwnerPermissions() == entry2.getOwnerPermissions()) &&
      (entry1.getName() == entry2.getName());
}

bool operator!=(const TreeEntry& entry1, const TreeEntry& entry2) {
  return !(entry1 == entry2);
}
}
}
