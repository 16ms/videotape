/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 * @flow
 */

import React, { Component } from 'react';
import {
  AppRegistry,
  StyleSheet,
  NativeModules,
  Button,
  View,
  Text,
} from 'react-native';
import { StackNavigator } from 'react-navigation';

const { VideoTape } = NativeModules;

class ChatScreen extends React.Component {
  static navigationOptions = {
    title: 'Chat with Lucy',
  };
  render() {
    return (
      <View>
        <Text>Chat with Lucy</Text>
      </View>
    );
  }
}

class HomeScreen extends React.Component {
  static navigationOptions = {
    title: 'Welcome',
  };
  render() {
    const { navigate } = this.props.navigation;
    return (
      <View>
        <Text>Hello, Chat App!</Text>
        <Button onPress={() => navigate('Chat')} title="Chat with Lucy" />
        <Button onPress={() => VideoTape.start()} title="Videotape start" />
        <Button
          onPress={() =>
            VideoTape.getLastSegment().then(res => console.log(res))}
          title="Get last segment"
        />
        <Button onPress={() => VideoTape.stop()} title="Videotape stop" />
      </View>
    );
  }
}

const SimpleApp = StackNavigator({
  Home: { screen: HomeScreen },
  Chat: { screen: ChatScreen },
});

AppRegistry.registerComponent('VideoTapeTester', () => SimpleApp);
