/* @flow */
import React from 'react';
import {
  StyleSheet,
  ScrollView,
  Text,
  View,
  Image,
  Linking,
  TouchableOpacity,
  ActivityIndicator,
} from 'react-native';
import VideoPreview from './VideoPreview';
import { type FrameProps, type SegmentProps } from '../types';

const Frame = ({ diff, touch }: FrameProps) =>
  <View
    toolTip={`Touch state: ${touch}, ${diff
      ? 'frame has changed pixels'
      : 'frame has not changed to previous'}`}
    style={[
      styles.frame,
      !diff ? styles.droppedFrameStyle : {},
      touch > 0 ? styles.touchFrameStyle : {},
    ]}
  />;

const Title = ({ children }: { children: string }) =>
  <View style={styles.title}>
    <Text style={styles.titleText}>{children}</Text>
  </View>;

export default ({ segment }: { segment: SegmentProps }) =>
  <ScrollView contentContainerStyle={styles.container}>
    <Title>Frames stats</Title>
    <View style={styles.frames}>
      {segment.framesMetadata.map((f, i) => <Frame key={i} {...f} />)}
    </View>
    <Title>Video fragment</Title>
    {segment.movieURL
      ? <VideoPreview src={segment.movieURL} style={segment.inputFrame} />
      : <ActivityIndicator />}
    <Title>Diffs (changed pixels highlighted)</Title>
    {segment.snapshotURL
      ? <TouchableOpacity onPress={() => Linking.openURL(segment.snapshotURL)}>
          <Image
            source={{ uri: segment.snapshotURL }}
            resizeMode={'contain'}
            style={{ width: '100%', height: 500 }}
          />
        </TouchableOpacity>
      : <ActivityIndicator />}
    <Text>{JSON.stringify(segment)}</Text>
  </ScrollView>;

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: 20,
  },
  title: {
    alignItems: 'center',
    marginTop: 20,
    marginBottom: 5,
  },
  titleText: {
    fontSize: 11,
    color: '#777777',
  },

  frames: {
    flexDirection: 'row',
    flex: 1,
    flexWrap: 'wrap',
  },
  frame: {
    width: 15,
    height: 15,
    margin: 1,
    backgroundColor: '#88CC88',
  },
  droppedFrameStyle: {
    backgroundColor: '#FFD1AA',
  },
  touchFrameStyle: {
    borderRadius: 15 / 2,
  },
});
