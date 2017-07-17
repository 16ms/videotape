/* @flow */
import React from 'react';
import { StyleSheet, Text, View, FlatList } from 'react-native';
import ProjectsHeader from './ProjectsHeader';
import { type ProjectProps } from '../types';

export default ({
  projects,
  selectedProject,
}: {
  projects: Array<ProjectProps>,
  selectedProject: number,
}) =>
  <FlatList
    data={projects}
    ListHeaderComponent={() => <ProjectsHeader />}
    contentContainerStyle={styles.container}
    keyExtractor={project => project.uuid}
    renderItem={({ item }) =>
      <View
        key={item.uuid}
        contextMenu={[
          { title: 'Rename Project' },
          { title: 'Clear Project' },
          { isSeparator: true },
          { title: 'Delete Project', key: 'd' },
        ]}
        onContextMenuItemClick={({ nativeEvent: { menuItem } }) =>
          alert('Not Implemented yet')}
        style={[
          styles.projectWrapper,
          selectedProject === item.uuid ? styles.highlighted : {},
        ]}>
        <Text
          style={[
            styles.projectName,
            selectedProject === item.uuid ? styles.highlightedText : {},
          ]}>
          {item.title}
        </Text>
      </View>}
  />;

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  highlighted: {
    backgroundColor: 'rgba(0.5, 0.5, 0.5, 0.1)',
  },
  focused: {
    backgroundColor: '#3A8EFC',
  },
  projectWrapper: {
    paddingVertical: 4,
    paddingHorizontal: 20,
  },
  projectName: {
    fontSize: 13,
    fontWeight: '300',
    color: '#434343',
  },
  highlightedText: {
    fontWeight: '500',
  },
  focusedText: {
    color: '#FFFEF4',
  },
});
