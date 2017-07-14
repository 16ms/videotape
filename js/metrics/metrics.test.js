import addMetrics, { calculateStability, calculateLatency } from './index';

test('returns zero if there is no frames metadata', () => {
  const emptySegment = {};
  const noFrames = { framesMetadata: [] };
  expect(addMetrics(emptySegment)).toBe(emptySegment);
  expect(addMetrics(noFrames)).toBe(noFrames);
});

test('stability should not depend on the beginning and the ending of segment', () => {
  const trimmedSegment = {
    framesMetadata: [{ diff: 1 }, { diff: 0 }, { diff: 1 }],
  };
  const notTrimmedSegment = {
    framesMetadata: [{ diff: 0 }]
      .concat(trimmedSegment.framesMetadata)
      .concat([{ diff: 0 }, { diff: 0 }]),
  };
  expect(calculateStability(trimmedSegment)).toBe(
    calculateStability(notTrimmedSegment)
  );
});

test('segment without dropped frames shoud have stability score = 1', () => {
  const segment = {
    framesMetadata: [{ diff: 1 }, { diff: 1 }, { diff: 1 }],
  };
  expect(calculateStability(segment)).toBe(1);
});

test('segment with dropped frames shoud have stability score < 1', () => {
  const segment = {
    framesMetadata: [{ diff: 1 }, { diff: 0 }, { diff: 1 }],
  };
  expect(calculateStability(segment)).toBeLessThan(1);
});

test('segment without diff frames has stability = 1', () => {
  const segment = {
    framesMetadata: [{ diff: 0 }, { diff: 0 }, { diff: 0 }],
  };
  expect(calculateStability(segment)).toBe(1);
});

test('segment with immidiate reaction on touch should have ideal latency score', () => {
  const segment = {
    framesMetadata: [{ diff: 0, touch: 1 }, { diff: 1, touch: 0 }],
  };
  expect(calculateLatency(segment)).toBe(1);
  const segment2 = {
    framesMetadata: [
      { diff: 0, touch: 1 },
      { diff: 0, touch: 0 },
      { diff: 1, touch: 0 },
    ],
  };
  expect(calculateLatency(segment2)).toBe(1);
});

test('segment with 3 frames reaction should have score less than 1', () => {
  const segment = {
    framesMetadata: [
      { diff: 0, touch: 1 },
      { diff: 0, touch: 0 },
      { diff: 0, touch: 0 },
      { diff: 1, touch: 0 },
    ],
  };
  expect(calculateLatency(segment)).toBeLessThan(1);
});
