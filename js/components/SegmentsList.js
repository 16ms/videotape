/* @flow */
import React from "react";
import {
  StyleSheet,
  Text,
  View,
  FlatList,
  TouchableOpacity,
  TouchableHighlight
} from "react-native";
import { format, differenceInDays } from "date-fns";
import addMetrics from "../metrics";

function extractMetadataTitle({ fps, framesMetadata }) {
  const score = addMetrics({ framesMetadata }).score || 0;
  return `  ${Math.round(
    (framesMetadata.length * 1000) / fps
  )}ms  score: ${Math.round(score * 100)}%`;
}

function formatDate(seconds) {
  const date = new Date(seconds * 1000);
  if (differenceInDays(new Date(), date) < 1) {
    return format(date, "HH:mm");
  }
  return format(date, "DD/MM/YY");
}

export default ({
  segments,
  selectedSegment,
  onSelect,
  onContextMenuItemClick
}: any) => (
  <View style={styles.container}>
    <FlatList
      initialNumToRender={10}
      keyExtractor={({ uuid }) => uuid}
      removeClippedSubviews={false}
      data={segments}
      keyExtractor={segment => segment.uuid.toString()}
      ItemSeparatorComponent={({ highlighted }) => (
        <View style={[styles.separator, highlighted && { marginLeft: 0 }]} />
      )}
      renderItem={({ item }) => (
        <TouchableOpacity
          activeOpacity={0.6}
          onPress={() => onSelect(item.uuid)}
          contextMenu={[
            { title: "Rename" },
            { title: "Delete", key: "d" },
            { isSeparator: true },
            { title: "Merge with previous" }
          ]}
          onContextMenuItemClick={({ nativeEvent: { menuItem } }) =>
            onContextMenuItemClick(menuItem.title, item)
          }
          key={item.uuid}
          style={[
            styles.item,
            selectedSegment === item.uuid ? styles.highlighted : {}
          ]}
        >
          <Text style={styles.itemTitle}>{item.title}</Text>
          <Text style={styles.itemSubtitle}>
            {formatDate(item.createdAt)}
            {extractMetadataTitle(item)}
          </Text>
        </TouchableOpacity>
      )}
    />
  </View>
);

const styles = StyleSheet.create({
  container: {
    borderRightWidth: 1, // StyleSheet.hairlineWidth,
    borderRightColor: "#E6E6E6",
    width: "35%",
    backgroundColor: "white"
  },
  separator: {
    height: 1,
    flex: 1,
    backgroundColor: "#E6E6E6"
  },
  item: {
    paddingVertical: 10,
    paddingHorizontal: 20,
    backgroundColor: "white"
  },
  itemTitle: {
    fontSize: 13,
    fontWeight: "700",
    color: "#464646"
  },
  itemSubtitle: {
    fontSize: 12,
    color: "#646463"
  },
  highlighted: {
    backgroundColor: "#DFDFDD"
  }
});
