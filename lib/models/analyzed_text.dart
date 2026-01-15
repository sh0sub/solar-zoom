import 'package:google_mlkit_entity_extraction/google_mlkit_entity_extraction.dart';

/// 텍스트 카테고리: OCR 결과의 내용 분류
enum TextCategory {
  medicine,    // 약 설명서
  receipt,     // 영수증
  menu,        // 메뉴판
  nutrition,   // 영양성분표
  document,    // 문서
  signage,     // 간판/표지판
  unknown      // 알 수 없음
}

/// OCR 및 엔티티 추출 결과를 담는 데이터 모델
class AnalyzedText {
  /// 원본 OCR 텍스트
  final String rawText;
  
  /// 추출된 엔티티 목록 (날짜, 금액, 전화번호 등)
  final List<EntityAnnotation> entities;
  
  /// 텍스트 카테고리 (자동 추론 가능)
  final TextCategory category;
  
  /// 중요 정보 하이라이트 (키-값 쌍)
  final Map<String, String> highlights;
  
  const AnalyzedText({
    required this.rawText,
    required this.entities,
    required this.category,
    required this.highlights,
  });
  
  /// 엔티티 목록을 기반으로 텍스트 카테고리 추론
  /// 
  /// 휴리스틱:
  /// - DateTime + Phone → Medicine (약에는 유효기간과 약국 연락처)
  /// - Money + DateTime → Receipt (영수증에는 금액과 날짜)
  /// - Money만 → Menu (메뉴판에는 가격만)
  static TextCategory inferCategory(List<EntityAnnotation> entities) {
    if (entities.isEmpty) {
      return TextCategory.unknown;
    }
    
    // 엔티티 타입 분석
    final hasDateTime = entities.any((e) => 
      e.entities.any((entity) => entity.type == EntityType.dateTime));
    final hasPhone = entities.any((e) => 
      e.entities.any((entity) => entity.type == EntityType.phone));
    final hasMoney = entities.any((e) => 
      e.entities.any((entity) => entity.type == EntityType.money));
    final hasAddress = entities.any((e) => 
      e.entities.any((entity) => entity.type == EntityType.address));
    
    // 카테고리 결정
    if (hasDateTime && hasPhone) {
      return TextCategory.medicine;  // 약: 유효기간 + 연락처
    }
    
    if (hasMoney && hasDateTime) {
      return TextCategory.receipt;   // 영수증: 금액 + 날짜
    }
    
    if (hasMoney) {
      return TextCategory.menu;      // 메뉴: 가격만
    }
    
    if (hasPhone || hasAddress) {
      return TextCategory.document;  // 일반 문서: 연락처/주소
    }
    
    return TextCategory.unknown;
  }
  
  /// 하이라이트 정보 추출
  /// 엔티티에서 중요 정보를 Map으로 변환
  Map<String, String> extractHighlights() {
    final result = <String, String>{};
    
    for (final annotation in entities) {
      for (final entity in annotation.entities) {
        switch (entity.type) {
          case EntityType.dateTime:
            result['date'] = annotation.text;
            break;
          case EntityType.money:
            result['amount'] = annotation.text;
            break;
          case EntityType.phone:
            result['phone'] = annotation.text;
            break;
          default:
            break;
        }
      }
    }
    
    return result;
  }
}
