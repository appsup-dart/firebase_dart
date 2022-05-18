part of firebase.protocol;

/// Transforms a channel with frames of limited length to full strings
final framesChannelTransformer = const FramesChannelTransformer();

class FramesChannelTransformer
    implements StreamChannelTransformer<String, String> {
  final int maxFrameSize;

  const FramesChannelTransformer({this.maxFrameSize = 16384});

  @override
  StreamChannel<String> bind(StreamChannel<String> channel) {
    var stream = channel.stream
        .transform(FramesToMessagesTransformer(maxFrameSize: maxFrameSize));
    var sink = StreamSinkTransformer<String, String>.fromHandlers(
        handleData: (data, sink) {
      var dataSegs = List.generate(
          (data.length / maxFrameSize).ceil(),
          (i) => data.substring(
              i * maxFrameSize, min((i + 1) * maxFrameSize, data.length)));

      if (dataSegs.length > 1) {
        sink.add('${dataSegs.length}');
      }
      for (var v in dataSegs) {
        sink.add(v);
      }
    }).bind(channel.sink);
    return StreamChannel.withCloseGuarantee(stream, sink);
  }
}

class FramesToMessagesTransformer
    extends StreamTransformerBase<String, String> {
  final int maxFrameSize;

  const FramesToMessagesTransformer({this.maxFrameSize = 16384});

  @override
  Stream<String> bind(Stream<String> stream) {
    return Stream<String>.eventTransformed(
        stream, (EventSink<String> sink) => _FramesToMessagesEventSink(sink));
  }
}

class _FramesToMessagesEventSink extends EventSink<String> {
  final EventSink<String> _outputSink;

  int? _totalFrames;
  List<String>? _frames;

  _FramesToMessagesEventSink(this._outputSink);

  @override
  void add(String event) {
    if (_frames != null) {
      _frames!.add(event);
      if (_frames!.length == _totalFrames) {
        var fullMess = _frames!.join('');
        _frames = null;
        _outputSink.add(fullMess);
      }
    } else {
      if (event.length <= 6) {
        var frameCount = int.tryParse(event);
        if (frameCount != null) {
          _totalFrames = frameCount;
          _frames = [];
          return;
        }
      }
      _outputSink.add(event);
    }
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _outputSink.addError(error, stackTrace);
  }

  @override
  void close() {
    _outputSink.close();
  }
}
