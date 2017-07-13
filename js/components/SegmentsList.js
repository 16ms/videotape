/* @flow */
import React from 'react';
import {
  StyleSheet,
  Text,
  View,
  FlatList,
  TouchableOpacity,
  TouchableHighlight,
} from 'react-native';
import { format, differenceInDays } from 'date-fns';

function trim(frames) {
  return frames.slice(1, -1);
}

function extractMetadataTitle({ fps, framesMetadata }) {
  const frames = trim(framesMetadata);
  const droppedFrames = frames.filter(f => !f.diff).length;
  const naiveFPS = fps * (frames.length - droppedFrames) / frames.length;
  return `${Math.round(
    framesMetadata.length * 1000 / 60
  )} ms, fps: ${Math.round(naiveFPS)}`;
}

function formatDate(seconds) {
  const date = new Date(seconds * 1000);
  if (differenceInDays(date, new Date()) < 1) {
    return format(date, 'HH:mm');
  }
  return format(date, 'HH:mm DD/MM/YY');
}

export default ({
  segments,
  selectedSegment,
  onSelect,
  onContextMenuItemClick,
}: any) =>
  <View style={styles.container}>
    <FlatList
      data={segments}
      keyExtractor={segment => segment.uuid}
      ItemSeparatorComponent={({ highlighted }) =>
        <View style={[styles.separator, highlighted && { marginLeft: 0 }]} />}
      renderItem={({ item }) =>
        <TouchableOpacity
          activeOpacity={0.6}
          onPress={() => onSelect(item.uuid)}
          contextMenu={[
            { title: 'Rename' },
            { title: 'Delete', key: 'd' },
            { isSeparator: true },
            { title: 'Merge with previous' },
          ]}
          onContextMenuItemClick={({ nativeEvent: { menuItem } }) =>
            onContextMenuItemClick(menuItem.title, item)}
          key={item.uuid}
          style={[
            styles.item,
            selectedSegment === item.uuid ? styles.highlighted : {},
          ]}>
          <Text style={styles.itemTitle}>
            {item.title}
          </Text>
          <Text style={styles.itemSubtitle}>
            {formatDate(item.createdAt)}, {extractMetadataTitle(item)}
          </Text>
        </TouchableOpacity>}
    />
  </View>;

const styles = StyleSheet.create({
  container: {
    borderRightWidth: 1, // StyleSheet.hairlineWidth,
    borderRightColor: '#E6E6E6',
    width: '40%',
    backgroundColor: 'white',
  },
  separator: {
    height: 1,
    flex: 1,
    backgroundColor: '#E6E6E6',
  },
  item: {
    paddingVertical: 10,
    paddingHorizontal: 20,
    backgroundColor: 'white',
  },
  itemTitle: {
    fontSize: 13,
    fontWeight: '600',
    color: '#464646',
  },
  itemSubtitle: {
    fontSize: 12,
    color: '#646463',
  },
  highlighted: {
    backgroundColor: '#DFDFDD',
  },
});
