import 'dart:async';
import 'package:flutter/material.dart';

/// 스트리밍 응답 위젯
/// 
/// 실시간으로 텍스트 청크를 받아서 화면에 표시
/// AI 응답이 스트리밍되는 동안 실시간 업데이트
class StreamingResponseWidget extends StatefulWidget {
  /// 텍스트 청크 스트림
  final Stream<String> stream;

  /// 텍스트 스타일
  final TextStyle? textStyle;

  /// 로딩 인디케이터 표시 여부
  final bool showLoadingIndicator;

  const StreamingResponseWidget({
    super.key,
    required this.stream,
    this.textStyle,
    this.showLoadingIndicator = false,
  });

  @override
  State<StreamingResponseWidget> createState() =>
      _StreamingResponseWidgetState();
}

class _StreamingResponseWidgetState extends State<StreamingResponseWidget> {
  final StringBuffer _buffer = StringBuffer();
  StreamSubscription<String>? _subscription;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _listenToStream();
  }

  @override
  void didUpdateWidget(StreamingResponseWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 스트림이 변경되면 재구독
    if (widget.stream != oldWidget.stream) {
      _subscription?.cancel();
      _buffer.clear();
      _isLoading = true;
      _errorMessage = null;
      _listenToStream();
    }
  }

  void _listenToStream() {
    _subscription = widget.stream.listen(
      (chunk) {
        setState(() {
          _buffer.write(chunk);
          _isLoading = false;
          _errorMessage = null;
        });
      },
      onError: (error) {
        setState(() {
          _errorMessage = '오류가 발생했습니다: ${error.toString()}';
          _isLoading = false;
        });
      },
      onDone: () {
        setState(() {
          _isLoading = false;
        });
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 에러 상태
    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          _errorMessage!,
          style: TextStyle(
            color: Colors.red[700],
            fontSize: 16,
          ),
        ),
      );
    }

    // 로딩 상태 (데이터가 아직 없을 때만)
    if (_isLoading && _buffer.isEmpty && widget.showLoadingIndicator) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 텍스트 표시
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        _buffer.toString(),
        style: widget.textStyle ??
            const TextStyle(
              fontSize: 18,
              height: 1.5,
              color: Colors.black87,
            ),
      ),
    );
  }
}
