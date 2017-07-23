// @flow
import { NativeEventEmitter, NativeModules } from 'react-native';
import { type ProjectProps } from '../types';
const { VTCaptureModuleProxy } = NativeModules;

const toolbarManagerEmitter = new NativeEventEmitter(VTCaptureModuleProxy);

export function onSettingsChange(listener: Function) {
  return toolbarManagerEmitter.addListener('onSettingsChange', listener);
}

export function onCapturingStateChange(listener: Function) {
  return toolbarManagerEmitter.addListener('onCapturingStateChange', listener);
}

export async function setSettings(projectSettings: ProjectProps) {
  await VTCaptureModuleProxy.setSettings(projectSettings);
}

export function startCapturing() {
  VTCaptureModuleProxy.startCapturing();
}

export function stopCapturing() {
  VTCaptureModuleProxy.stopCapturing();
}

export function recordTouchEvent(event: any) {
  VTCaptureModuleProxy.recordTouchEvent(event);
}

export function log(json: string) {
  VTCaptureModuleProxy.writeToStdout(json);
}
