import 'package:app/features/member/infrastructure/entities/member_entity.dart';
import 'package:app/features/shared/infrastructure/database/objectbox.dart';

class TestDataSeeder {
  static Future<void> seedTestData(ObjectBox objectBox) async {
    // 清空現有資料
    objectBox.memberBox.removeAll();

    // 新增測試會員資料
    final testMember = MemberEntity.create(
      memberId: '0',
      memberNumber: 'AA123456',
      fullName: '測試使用者 1234',
      email: 'test@example.com',
      phone: '+886912345678',
      tier: 'GOLD',
      lastLoginAt: DateTime.now(),
    );

    objectBox.memberBox.put(testMember);
  }
}
