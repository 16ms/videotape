/* @flow */
import React from "react";

import {
  requireNativeComponent,
  View,
  StyleSheet,
  ScrollView
} from "react-native";

// const RCTSplitView = requireNativeComponent('RCTSplitView', null);

export default class SplitView extends React.Component {
  // renderNativeSplitView() {
  //   return <RCTSplitView />;
  // }

  render() {
    return (
      <View style={styles.container}>
        <ScrollView style={styles.leftPanel}>{this.props.leftPanel}</ScrollView>
        <View style={styles.main}>{this.props.children}</View>
      </View>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    flexDirection: "row"
  },
  leftPanel: {
    backgroundColor: "white",
    maxWidth: 200
  },
  main: {
    flex: 1
  }
});
