/* @flow */
import React from 'react';
import { StyleSheet, Text, View, FlatList } from 'react-native';

export default () =>
  <View style={styles.container}>
    <Text style={styles.text}>Projects</Text>
  </View>;

const styles = StyleSheet.create({
  container: {
    flex: 1,
    paddingTop: 7,
    paddingBottom: 7,
    paddingLeft: 10,
  },
  text: {
    fontSize: 11,
    color: '#777777',
    fontWeight: '600',
  },
});
