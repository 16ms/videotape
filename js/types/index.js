/* @flow */
export type ProjectProps = any;

export type FrameProps = {
  diff: boolean,
  touch: number,
};

export type ScoreDetails = {
  stability: number,
  latency: number,
};

export type SegmentProps = {
  uuid?: string,
  framesMetadata: Array<FrameProps>,
  inputFrame?: any,
  snapshotURL?: string,
  movieURL?: string,
  score?: number,
  scoreDetails?: ScoreDetails,
};

export type AppState = {
  projects: Array<ProjectProps>,
  selectedProject: number,
  selectedSegment: ?string,
  segments: Array<SegmentProps>,
};
