import 'dart:ui';

/// 좌표 스케일링 유틸리티
/// 이미지 좌표계를 화면 좌표계로 변환
class CoordinateScaler {
  /// Rect를 이미지 크기에서 화면 크기로 스케일링
  /// 
  /// [rect]: 원본 이미지의 바운딩 박스
  /// [imageSize]: 원본 이미지 크기
  /// [screenSize]: 화면에 표시될 크기
  static Rect scaleRect(
    Rect rect,
    Size imageSize,
    Size screenSize,
  ) {
    if (imageSize.width == 0 || imageSize.height == 0) {
      throw ArgumentError('Image size cannot be zero');
    }

    final scaleX = screenSize.width / imageSize.width;
    final scaleY = screenSize.height / imageSize.height;

    return Rect.fromLTRB(
      rect.left * scaleX,
      rect.top * scaleY,
      rect.right * scaleX,
      rect.bottom * scaleY,
    );
  }

  /// Point를 이미지 크기에서 화면 크기로 스케일링
  static Offset scalePoint(
    Offset point,
    Size imageSize,
    Size screenSize,
  ) {
    final scaleX = screenSize.width / imageSize.width;
    final scaleY = screenSize.height / imageSize.height;

    return Offset(
      point.dx * scaleX,
      point.dy * scaleY,
    );
  }

  /// 스케일 팩터 계산
  static ScaleFactor calculateScaleFactor(
    Size imageSize,
    Size screenSize,
  ) {
    return ScaleFactor(
      scaleX: screenSize.width / imageSize.width,
      scaleY: screenSize.height / imageSize.height,
    );
  }
}

/// 스케일 팩터를 담는 데이터 클래스
class ScaleFactor {
  final double scaleX;
  final double scaleY;

  const ScaleFactor({
    required this.scaleX,
    required this.scaleY,
  });
}
