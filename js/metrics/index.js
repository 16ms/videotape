/* @flow */
import { type SegmentProps } from '../types';

const LATENCY_THREUSHOLD_FRAMES = 2;

export function extractFrames(framesMetadata: any) {
  // TODO: functional approach?
  let startIndex = 0;
  while (
    !framesMetadata[startIndex].diff &&
    startIndex < framesMetadata.length - 1
  ) {
    startIndex++;
  }
  let endIndex = framesMetadata.length - 1;
  while (!framesMetadata[endIndex].diff && endIndex > 0) {
    endIndex--;
  }
  return framesMetadata.slice(startIndex, endIndex + 1);
}
/*
 *  Higher stability means lower amount flakiness
 *  Less dropped frames
 */
export function calculateStability({ framesMetadata }: SegmentProps) {
  const frames = extractFrames(framesMetadata);

  if (frames.length === 0) {
    return 1;
  }
  const droppedFrames = frames.filter(f => !f.diff).length;
  return (frames.length - droppedFrames) / frames.length;
}

/*
 *  Time between touch or gesture and the feedback
 */
export function calculateLatency({ framesMetadata }: SegmentProps) {
  // at first, we implement a very naive approach
  // finding how much frames between touch and movement happened
  let i = 0;
  let touchIndex = 0;
  let latencies = [];
  while (i < framesMetadata.length) {
    if (framesMetadata[i].touch === 1) {
      touchIndex = i;
    }
    if (framesMetadata[i].touch === 0 && framesMetadata[i].diff === 1) {
      latencies.push(
        i - touchIndex <= LATENCY_THREUSHOLD_FRAMES ? 1 : 1 / (i - touchIndex)
      );
    }
    i++;
  }
  return latencies.length > 0
    ? latencies.reduce((score, l) => score + l / latencies.length, 0)
    : 1;

  // more sophisticated approach would be remembering the type
  // of the touch and pixels around it
  // is intentions fit the result?
}

export default function addMetrics(segment: SegmentProps) {
  if (!segment.framesMetadata || segment.framesMetadata.length === 0) {
    return segment;
  }
  const stability = calculateStability(segment);
  const latency = calculateLatency(segment);
  return {
    ...segment,
    score: (stability + latency) / 2, // very naive
    scoreDetails: {
      stability,
      latency,
    },
  };
}
