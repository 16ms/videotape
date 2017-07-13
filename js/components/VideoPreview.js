/* @flow */
import React from 'react';

import { requireNativeComponent, View } from 'react-native';

export default class VideoPreview extends React.Component {
  render() {
    const { style } = this.props;
    const dimensions = style.width > 500
      ? {
          width: style.width / 3,
          height: style.height / 3,
        }
      : style;
    return (
      <View style={{ flex: 1, alignItems: 'center', backgroundColor: 'black' }}>
        <VTVideoPreview src={this.props.src} style={dimensions} />
      </View>
    );
  }
}

const VTVideoPreview = requireNativeComponent('VTVideoPreview', null, {
  nativeOnly: {
    src: true,
  },
});
