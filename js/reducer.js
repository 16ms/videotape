// @flow

export const Actions = {
  SEGMENT_FOUND: 'segmentFound',
  SEGMENT_PROCESSED: 'segmentProcessed',
  SELECT_SEGMENT: 'SELECT_SEGMENT',
  SEGMENT_CONTEXT_MENU_CLICKED: 'SEGMENT_CONTEXT_MENU_CLICKED',
  UPDATE_SETTINGS: 'UPDATE_SETTINGS',
};

export default function reducer(state, action) {
  console.log('reducer for action =>', action);
  switch (action.type) {
    case Actions.UPDATE_SETTINGS:
      return {
        ...state,
        projects: state.projects.map(
          project =>
            project.uuid === action.payload.uuid
              ? {
                  ...project,
                  ...action.payload,
                }
              : project
        ),
      };
    case Actions.SEGMENT_FOUND:
      return {
        ...state,
        segments: [
          {
            ...action.payload,
            title: `${action.payload.windowState.appName} (${state.segments
              .length})`,
          },
          ...state.segments,
        ],
      };
    case Actions.SEGMENT_PROCESSED:
      const uuid = action.payload.uuid;
      return {
        ...state,
        segments: state.segments.map(
          segment =>
            segment.uuid === uuid
              ? {
                  ...segment,
                  ...action.payload,
                }
              : segment
        ),
      };
    case Actions.SELECT_SEGMENT:
      return {
        ...state,
        selectedSegment: action.payload.selectedSegment,
      };
    case Actions.SEGMENT_CONTEXT_MENU_CLICKED:
      return {
        ...state,
        segments: state.segments.filter(
          segment => segment.title !== action.payload.item.title
        ),
        selectedSegment: null, // TODO: choose next on the list
      };
    default:
      return state;
  }
}
