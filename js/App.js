/**
 * @flow
 */

import React, { Component } from 'react';
import {
  AsyncStorage,
  StyleSheet,
  Text,
  View,
  LayoutAnimation,
} from 'react-native';

import * as httpBridge from 'react-native-http-bridge';
import reducer, { Actions } from './reducer';
import SplitView from './components/SplitView';
import * as CaptureModule from './components/CaptureModule';
import ProjectsList from './components/ProjectsList';
import SegmentsList from './components/SegmentsList';
import SegmentDetails from './components/SegmentDetails';
import addMetrics from './metrics';

import { type AppState } from './types';

const STORAGE_KEY = 'default_project_storage';

export default class VideoTapeApp extends Component {
  constructor() {
    super();
    this.state = {
      projects: [{ title: 'Default', appName: 'Simulator', uuid: 0 }],
      selectedProject: 0,
      segments: [],
      selectedSegment: null,
    };
    this.args = this.argsFromCli();
  }
  state: AppState;

  dispatch(action: { type: string, payload: any }) {
    this.setState(
      prevState => reducer(prevState, action),
      () => this.save(action.type)
    );
    LayoutAnimation.easeInEaseOut();
  }

  save(type: string) {
    AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(this.state));
    if (this.args.autorun && type === Actions.SEGMENT_PROCESSED) {
      const lastSegment = this.state.segments[0];
      if (lastSegment.movieURL && lastSegment.snapshotURL) {
        // output latest segment and exit
        CaptureModule.log(JSON.stringify(addMetrics(lastSegment)));
        setTimeout(() => process.exit(0), 100);
      }
    }
  }

  argsFromCli() {
    if (process.argv && process.argv[0] && process.argv[0][0] !== '-') {
      return JSON.parse(process.argv[0]);
    }
    return {};
  }

  async init() {
    if (this.args.http) {
      httpBridge.start(5561, 'incoming', request => {
        if (request.postData.type === 'START_CAPTURING') {
          CaptureModule.startCapturing();
          httpBridge.respond(200);
        }
        if (request.postData.type === 'STOP_CAPTURING') {
          CaptureModule.stopCapturing();
          httpBridge.respond(200);
        }
        if (request.postData.type === 'GET_LAST_SEGMENT') {
          httpBridge.respond(
            200,
            'application/json',
            JSON.stringify(addMetrics(this.state.segments[0]))
          );
        }
      });
    }

    const state = await AsyncStorage.getItem(STORAGE_KEY);
    if (state) {
      this.setState(JSON.parse(state));
    }

    if (this.args.target) {
      CaptureModule.setSettings({
        ...this.state.projects[0],
        appName: this.args.target,
      });
      if (this.args.autorun) {
        setTimeout(() => CaptureModule.startCapturing(), 100);
      }
    } else {
      CaptureModule.setSettings(this.state.projects[0]);
    }
  }

  componentWillMount() {
    CaptureModule.onSettingsChange(projectSettings =>
      this.dispatch({ type: Actions.UPDATE_SETTINGS, payload: projectSettings })
    );
    CaptureModule.onCapturingStateChange(event => {
      if (event.capturingState === 'error') {
        //
        if (this.args.autorun && this.resettingTries > 5) {
          CaptureModule.log(`Error: ${event.body.error}`);
          process.exit(1);
        } else {
          this.resettingTimeout = setTimeout(
            () => CaptureModule.setSettings(this.state.projects[0]),
            200
          );
        }
      }
      this.dispatch({
        type: event.capturingState,
        payload: event.body,
      });
    });
    this.init();
  }

  render() {
    const { projects, selectedProject, selectedSegment, segments } = this.state;

    const leftPanel = (
      <View>
        <ProjectsList projects={projects} selectedProject={selectedProject} />
      </View>
    );
    return (
      <SplitView leftPanel={leftPanel}>
        <View style={styles.container}>
          <SegmentsList
            segments={segments}
            selectedSegment={selectedSegment}
            onContextMenuItemClick={(action, item) =>
              this.dispatch({
                type: Actions.SEGMENT_CONTEXT_MENU_CLICKED,
                payload: { action, item },
              })}
            onSelect={selectedSegment =>
              this.dispatch({
                type: Actions.SELECT_SEGMENT,
                payload: { selectedSegment },
              })}
          />
          {selectedSegment &&
            <SegmentDetails
              segment={segments.filter(s => s.uuid === selectedSegment)[0]}
            />}
        </View>
      </SplitView>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: 'white',
    flexDirection: 'row',
  },
});
