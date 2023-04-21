/**
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import type {ExportCommit, ExportStack} from 'shared/types/stack';

import {ABSENT_FILE, CommitStackState} from '../commitStackState';

const exportCommitDefault: ExportCommit = {
  requested: true,
  immutable: false,
  author: 'test <test@example.com>',
  date: [0, 0],
  node: '',
  text: '',
};

// In this test we tend to use uppercase for commits (ex. A, B, C),
// and lowercase for files (ex. x, y, z).

/**
 * Created by `drawdag --no-files`:
 *
 *       C  # C/z.txt=(removed)
 *       |
 *       B  # B/y.txt=33 (renamed from x.txt)
 *       |
 *       A  # A/x.txt=33
 *       |  # A/z.txt=22
 *      /
 *     Z  # Z/z.txt=11
 *
 * and exported via `debugexportstack -r 'desc(A)::'`.
 */
const exportStack1: ExportStack = [
  {
    ...exportCommitDefault,
    immutable: true,
    node: 'dc5d5ead34a4383bcba9636ed1b017a853a9839d',
    relevantFiles: {
      'x.txt': null,
      'z.txt': {data: '11'},
    },
    requested: false,
    text: 'Z',
  },
  {
    ...exportCommitDefault,
    files: {
      'x.txt': {data: '33'},
      'z.txt': {data: '22'},
    },
    node: 'b91bb862af35fa1ced0de1efaa10a4b60f290888',
    parents: ['dc5d5ead34a4383bcba9636ed1b017a853a9839d'],
    relevantFiles: {'y.txt': null},
    text: 'A',
  },
  {
    ...exportCommitDefault,
    files: {
      'x.txt': null,
      'y.txt': {copyFrom: 'x.txt', data: '33'},
    },
    node: '8116f2bdb3cdfd45b7955db5a1da679e0fcac78a',
    parents: ['b91bb862af35fa1ced0de1efaa10a4b60f290888'],
    relevantFiles: {'z.txt': {data: '22'}},
    text: 'B',
  },
  {
    ...exportCommitDefault,
    date: [0.0, 0],
    files: {'z.txt': null},
    node: 'e52cb4466b9bbbbff6690ccaeb2d54ad2ab1473b',
    parents: ['8116f2bdb3cdfd45b7955db5a1da679e0fcac78a'],
    text: 'C',
  },
];

describe('CommitStackState', () => {
  it('accepts an empty stack', () => {
    const stack = new CommitStackState([]);
    expect(stack.revs()).toStrictEqual([]);
  });

  it('accepts a stack without a public commit', () => {
    const stack = new CommitStackState([
      {
        ...exportCommitDefault,
        files: {'a.txt': {data: 'a'}},
        node: 'x',
        parents: [],
        text: 'A',
      },
    ]);
    expect(stack.revs()).toStrictEqual([0]);
  });

  it('rejects a stack with multiple roots', () => {
    const stack = [
      {...exportCommitDefault, node: 'Z1'},
      {...exportCommitDefault, node: 'Z2'},
    ];
    expect(() => new CommitStackState(stack)).toThrowError(
      'Multiple roots ["Z1","Z2"] is not supported',
    );
  });

  it('rejects a stack with merges', () => {
    const stack = [
      {...exportCommitDefault, node: 'A', parents: []},
      {...exportCommitDefault, node: 'B', parents: ['A']},
      {...exportCommitDefault, node: 'C', parents: ['A', 'B']},
    ];
    expect(() => new CommitStackState(stack)).toThrowError('Merge commit C is not supported');
  });

  it('rejects circular stack', () => {
    const stack = [
      {...exportCommitDefault, node: 'A', parents: ['B']},
      {...exportCommitDefault, node: 'B', parents: ['A']},
    ];
    expect(() => new CommitStackState(stack)).toThrowError();
  });

  it('provides file paths', () => {
    const stack = new CommitStackState(exportStack1);
    expect(stack.getAllPaths()).toStrictEqual(['x.txt', 'y.txt', 'z.txt']);
  });

  it('logs commit history', () => {
    const stack = new CommitStackState(exportStack1);
    expect(stack.revs()).toStrictEqual([0, 1, 2, 3]);
    expect([...stack.log(1)]).toStrictEqual([1, 0]);
    expect([...stack.log(3)]).toStrictEqual([3, 2, 1, 0]);
  });

  it('logs file history', () => {
    const stack = new CommitStackState(exportStack1);
    expect([...stack.logFile(3, 'x.txt')]).toStrictEqual([
      [2, 'x.txt'],
      [1, 'x.txt'],
    ]);
    expect([...stack.logFile(3, 'y.txt')]).toStrictEqual([[2, 'y.txt']]);
    expect([...stack.logFile(3, 'z.txt')]).toStrictEqual([
      [3, 'z.txt'],
      [1, 'z.txt'],
    ]);
    // Changes in not requested commits (rev 0) are ignored.
    expect([...stack.logFile(3, 'k.txt')]).toStrictEqual([]);
  });

  it('logs file history following renames', () => {
    const stack = new CommitStackState(exportStack1);
    expect([...stack.logFile(3, 'y.txt', true)]).toStrictEqual([
      [2, 'y.txt'],
      [1, 'x.txt'],
    ]);
  });

  it('provides file contents at given revs', () => {
    const stack = new CommitStackState(exportStack1);
    expect(stack.getFile(0, 'x.txt')).toBe(ABSENT_FILE);
    expect(stack.getFile(0, 'y.txt')).toBe(ABSENT_FILE);
    expect(stack.getFile(0, 'z.txt')).toMatchObject({data: '11'});
    expect(stack.getFile(1, 'x.txt')).toMatchObject({data: '33'});
    expect(stack.getFile(1, 'y.txt')).toBe(ABSENT_FILE);
    expect(stack.getFile(1, 'z.txt')).toMatchObject({data: '22'});
    expect(stack.getFile(2, 'x.txt')).toBe(ABSENT_FILE);
    expect(stack.getFile(2, 'y.txt')).toMatchObject({data: '33'});
    expect(stack.getFile(2, 'z.txt')).toMatchObject({data: '22'});
    expect(stack.getFile(3, 'x.txt')).toBe(ABSENT_FILE);
    expect(stack.getFile(3, 'y.txt')).toMatchObject({data: '33'});
    expect(stack.getFile(3, 'z.txt')).toBe(ABSENT_FILE);
  });

  describe('builds FileStack', () => {
    it('for double renames', () => {
      // x.txt renamed to both y.txt and z.txt.
      const stack = new CommitStackState([
        {...exportCommitDefault, node: 'A', files: {'x.txt': {data: 'xx'}}},
        {
          ...exportCommitDefault,
          node: 'B',
          parents: ['A'],
          files: {
            'x.txt': null,
            'y.txt': {data: 'yy', copyFrom: 'x.txt'},
            'z.txt': {data: 'zz', copyFrom: 'x.txt'},
          },
        },
      ]);
      expect(stack.describeFileStacks()).toStrictEqual([
        // y.txt inherits x.txt's history.
        '0:./x.txt 1:A/x.txt(xx) 2:B/y.txt(yy)',
        // z.txt does not inherit x.txt's history (but still has a parent for diff rendering purpose).
        '0:A/x.txt(xx) 1:B/z.txt(zz)',
      ]);
    });

    it('for double copies', () => {
      // x.txt copied to both y.txt and z.txt.
      const stack = new CommitStackState([
        {...exportCommitDefault, node: 'A', files: {'x.txt': {data: 'xx'}}},
        {
          ...exportCommitDefault,
          node: 'B',
          parents: ['A'],
          files: {
            'y.txt': {data: 'yy', copyFrom: 'x.txt'},
            'z.txt': {data: 'zz', copyFrom: 'y.txt'},
          },
        },
      ]);
      expect(stack.describeFileStacks()).toStrictEqual([
        // y.txt connects to x.txt's history.
        '0:./x.txt 1:A/x.txt(xx) 2:B/y.txt(yy)',
        // z.txt does not connect to x.txt's history (but still have one parent for diff).
        '0:./z.txt 1:B/z.txt(zz)',
      ]);
    });

    it('for changes and copies', () => {
      // x.txt is changed, and copied to both y.txt and z.txt.
      const stack = new CommitStackState([
        {...exportCommitDefault, node: 'A', files: {'x.txt': {data: 'xx'}}},
        {
          ...exportCommitDefault,
          node: 'B',
          parents: ['A'],
          files: {
            'x.txt': {data: 'yy'},
            'y.txt': {data: 'xx', copyFrom: 'x.txt'},
            'z.txt': {data: 'xx', copyFrom: 'x.txt'},
          },
        },
      ]);
      expect(stack.describeFileStacks()).toStrictEqual([
        // x.txt has its own history.
        '0:./x.txt 1:A/x.txt(xx) 2:B/x.txt(yy)',
        // y.txt and z.txt do not share x.txt's history (but still have one parent for diff).
        '0:A/x.txt(xx) 1:B/y.txt(xx)',
        '0:A/x.txt(xx) 1:B/z.txt(xx)',
      ]);
    });

    it('for the the example stack', () => {
      const stack = new CommitStackState(exportStack1);
      expect(stack.describeFileStacks()).toStrictEqual([
        // x.txt: added by A, modified and renamed by B.
        '0:./x.txt 1:A/x.txt(33) 2:B/y.txt(33)',
        // z.txt: modified by A, deleted by C.
        '0:./z.txt(11) 1:A/z.txt(22) 2:C/z.txt',
      ]);
    });
  });

  describe('calculates dependencies', () => {
    const e = exportCommitDefault;

    it('for content changes', () => {
      const stack = new CommitStackState([
        {...e, node: 'Z', requested: false, relevantFiles: {'x.txt': null}},
        {...e, node: 'A', parents: ['Z'], files: {'x.txt': {data: 'b\n'}}},
        {...e, node: 'B', parents: ['A'], files: {'x.txt': {data: 'a\nb\n'}}},
        {...e, node: 'C', parents: ['B'], files: {'x.txt': {data: 'a\nb\nc\n'}}},
      ]);
      expect(stack.calculateDepMap()).toStrictEqual(
        new Map([
          [0, new Set()],
          [1, new Set()],
          [2, new Set([1])],
          [3, new Set([1])], // commit C does not depend on commit B
        ]),
      );
    });

    it('for file addition and deletion', () => {
      const stack = new CommitStackState([
        {...e, node: 'Z', requested: false, relevantFiles: {'x.txt': {data: 'a'}}},
        {...e, node: 'A', parents: ['Z'], files: {'x.txt': null}},
        {...e, node: 'B', parents: ['A'], files: {'x.txt': {data: 'a'}}},
        {...e, node: 'C', parents: ['B'], files: {'x.txt': null}},
      ]);
      expect(stack.calculateDepMap()).toStrictEqual(
        new Map([
          [0, new Set()],
          [1, new Set()],
          [2, new Set([1])], // commit B adds x.txt, depends on commit A's deletion.
          [3, new Set([2])], // commit C deletes x.txt, depends on commit B's addition.
        ]),
      );
    });

    it('for copies', () => {
      const stack = new CommitStackState([
        {...e, node: 'A', files: {'x.txt': {data: 'a'}}},
        {...e, node: 'B', parents: ['A'], files: {'y.txt': {data: 'a', copyFrom: 'x.txt'}}},
        {...e, node: 'C', parents: ['B'], files: {'z.txt': {data: 'a', copyFrom: 'x.txt'}}},
        {
          ...e,
          node: 'D',
          parents: ['C'],
          files: {'p.txt': {data: 'a', copyFrom: 'x.txt'}, 'q.txt': {data: 'a', copyFrom: 'z.txt'}},
        },
      ]);
      expect(stack.calculateDepMap()).toStrictEqual(
        new Map([
          [0, new Set()],
          [1, new Set([0])], // commit B copies commit A's x.txt to y.txt.
          [2, new Set([0])], // commit C copies commit A's x.txt to z.txt.
          [3, new Set([0, 2])], // commit D copies commit A's x.txt to p.txt, and commit C's z.txt to q.txt.
        ]),
      );
    });
  });
});
