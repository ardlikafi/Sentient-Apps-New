import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const String _languageKey = 'selected_language';
  
  static const Map<String, Map<String, String>> _translations = {
    'en': {
      'home': 'Home',
      'courses': 'Courses',
      'shop': 'Shop',
      'profile': 'Profile',
      'hi': 'Hi',
      'welcome_back': 'Welcome back',
      'account': 'Account',
      'account_information': 'Account Information',
      'edit_profile': 'Edit Profile',
      'security': 'Security',
      'notifications': 'Notifications',
      'language': 'Language',
      'preferences': 'Preferences',
      'my_subscription': 'My Subscription',
      'privacy_policy': 'Privacy Policy',
      'help_support': 'Help & Support',
      'about': 'About',
      'logout': 'Logout',
      'username': 'Username',
      'email': 'Email',
      'phone': 'Phone',
      'account_created_on': 'Account Created on',
      'select_language': 'Select Language',
      'english': 'English',
      'indonesia': 'Indonesia',
      'chinese': '中文',
      'language_changed': 'Language changed to',
      'cancel': 'Cancel',
      'save': 'Save',
      'notification_settings': 'Notification Settings',
      'push_notifications': 'Push Notifications',
      'email_notifications': 'Email Notifications',
      'course_updates': 'Course Updates',
      'receive_push_notifications': 'Receive push notifications',
      'receive_email_updates': 'Receive email updates',
      'get_notified_about_new_courses': 'Get notified about new courses',
      'privacy_policy_content': '''Privacy Policy for Sentient Apps

1. Information We Collect
We collect information you provide directly to us, such as when you create an account, 
update your profile, or contact us.

2. How We Use Your Information
We use the information we collect to provide, maintain, and improve our services, 
process transactions, and communicate with you.

3. Information Sharing
We do not sell, trade, or otherwise transfer your personal information to third parties 
without your consent, except as described in this policy.

4. Data Security
We implement appropriate technical and organizational measures to protect your 
personal information against unauthorized access, alteration, disclosure, or destruction.

5. Changes to This Policy
We may update this privacy policy from time to time. We will notify you of any changes 
by posting the new policy on this page.''',
      'help_support_content': '''Help & Support

Contact Us:
Email: support@sentientapps.com
Phone: +62 812-3456-7890

Frequently Asked Questions:
Q: How do I reset my password?
A: Go to Settings > Security > Change Password

Q: How do I cancel my subscription?
A: Go to Settings > Subscription > Manage

Q: How do I report a bug?
A: Email us at support@sentientapps.com''',
      'about_content': '''Version: 1.0.0

A comprehensive chess learning platform with courses, products, and community features.

Features:
• Interactive chess courses
• Chess products and accessories
• Community features
• Expert tutorials

© 2026 Sentient Apps
All rights reserved.''',
    },
    'id': {
      'home': 'Beranda',
      'courses': 'Kursus',
      'shop': 'Toko',
      'profile': 'Profil',
      'hi': 'Hai',
      'welcome_back': 'Selamat datang kembali',
      'account': 'Akun',
      'account_information': 'Informasi Akun',
      'edit_profile': 'Edit Profil',
      'security': 'Keamanan',
      'notifications': 'Notifikasi',
      'language': 'Bahasa',
      'preferences': 'Preferensi',
      'my_subscription': 'Langganan Saya',
      'privacy_policy': 'Kebijakan Privasi',
      'help_support': 'Bantuan & Dukungan',
      'about': 'Tentang',
      'logout': 'Keluar',
      'username': 'Nama Pengguna',
      'email': 'Email',
      'phone': 'Telepon',
      'account_created_on': 'Akun Dibuat pada',
      'select_language': 'Pilih Bahasa',
      'english': 'English',
      'indonesia': 'Indonesia',
      'chinese': '中文',
      'language_changed': 'Bahasa diubah ke',
      'cancel': 'Batal',
      'save': 'Simpan',
      'notification_settings': 'Pengaturan Notifikasi',
      'push_notifications': 'Notifikasi Push',
      'email_notifications': 'Notifikasi Email',
      'course_updates': 'Update Kursus',
      'receive_push_notifications': 'Terima notifikasi push',
      'receive_email_updates': 'Terima update email',
      'get_notified_about_new_courses': 'Dapatkan notifikasi tentang kursus baru',
      'privacy_policy_content': '''Kebijakan Privasi untuk Sentient Apps

1. Informasi yang Kami Kumpulkan
Kami mengumpulkan informasi yang Anda berikan langsung kepada kami, seperti saat Anda membuat akun, 
memperbarui profil, atau menghubungi kami.

2. Cara Kami Menggunakan Informasi Anda
Kami menggunakan informasi yang kami kumpulkan untuk menyediakan, memelihara, dan meningkatkan layanan kami, 
memproses transaksi, dan berkomunikasi dengan Anda.

3. Berbagi Informasi
Kami tidak menjual, memperdagangkan, atau mentransfer informasi pribadi Anda kepada pihak ketiga 
tanpa persetujuan Anda, kecuali seperti dijelaskan dalam kebijakan ini.

4. Keamanan Data
Kami menerapkan langkah-langkah teknis dan organisasi yang tepat untuk melindungi 
informasi pribadi Anda dari akses, perubahan, pengungkapan, atau penghancuran yang tidak sah.

5. Perubahan Kebijakan Ini
Kami mungkin memperbarui kebijakan privasi ini dari waktu ke waktu. Kami akan memberi tahu Anda tentang perubahan apa pun 
dengan memposting kebijakan baru di halaman ini.''',
      'help_support_content': '''Bantuan & Dukungan

Hubungi Kami:
Email: support@sentientapps.com
Telepon: +62 812-3456-7890

Pertanyaan yang Sering Diajukan:
Q: Bagaimana cara mereset kata sandi saya?
A: Pergi ke Pengaturan > Keamanan > Ubah Kata Sandi

Q: Bagaimana cara membatalkan langganan saya?
A: Pergi ke Pengaturan > Langganan > Kelola

Q: Bagaimana cara melaporkan bug?
A: Email kami di support@sentientapps.com''',
      'about_content': '''Versi: 1.0.0

Platform pembelajaran catur komprehensif dengan kursus, produk, dan fitur komunitas.

Fitur:
• Kursus catur interaktif
• Produk dan aksesoris catur
• Fitur komunitas
• Tutorial ahli

© 2026 Sentient Apps
Hak cipta dilindungi.''',
    },
    'zh': {
      'home': '首页',
      'courses': '课程',
      'shop': '商店',
      'profile': '个人资料',
      'hi': '你好',
      'welcome_back': '欢迎回来',
      'account': '账户',
      'account_information': '账户信息',
      'edit_profile': '编辑资料',
      'security': '安全',
      'notifications': '通知',
      'language': '语言',
      'preferences': '偏好设置',
      'my_subscription': '我的订阅',
      'privacy_policy': '隐私政策',
      'help_support': '帮助与支持',
      'about': '关于',
      'logout': '退出',
      'username': '用户名',
      'email': '电子邮件',
      'phone': '电话',
      'account_created_on': '账户创建于',
      'select_language': '选择语言',
      'english': 'English',
      'indonesia': 'Indonesia',
      'chinese': '中文',
      'language_changed': '语言已更改为',
      'cancel': '取消',
      'save': '保存',
      'notification_settings': '通知设置',
      'push_notifications': '推送通知',
      'email_notifications': '电子邮件通知',
      'course_updates': '课程更新',
      'receive_push_notifications': '接收推送通知',
      'receive_email_updates': '接收电子邮件更新',
      'get_notified_about_new_courses': '获取新课程通知',
      'privacy_policy_content': '''Sentient Apps 隐私政策

1. 我们收集的信息
我们收集您直接提供给我们的信息，例如当您创建账户、更新个人资料或联系我们时。

2. 我们如何使用您的信息
我们使用收集的信息来提供、维护和改进我们的服务、处理交易并与您沟通。

3. 信息共享
除非本政策中所述，否则我们不会在未经您同意的情况下出售、交易或以其他方式将您的个人信息转移给第三方。

4. 数据安全
我们实施适当的技术和组织措施来保护您的个人信息免受未经授权的访问、更改、披露或销毁。

5. 本政策变更
我们可能会不时更新此隐私政策。我们将通过在此页面上发布新政策来通知您任何更改。''',
      'help_support_content': '''帮助与支持

联系我们：
电子邮件：support@sentientapps.com
电话：+62 812-3456-7890

常见问题：
问：如何重置密码？
答：转到设置 > 安全 > 更改密码

问：如何取消订阅？
答：转到设置 > 订阅 > 管理

问：如何报告错误？
答：发送电子邮件至 support@sentientapps.com''',
      'about_content': '''版本：1.0.0

具有课程、产品和社区功能的综合国际象棋学习平台。

功能：
• 互动国际象棋课程
• 国际象棋产品和配件
• 社区功能
• 专家教程

© 2026 Sentient Apps
版权所有。''',
    },
  };

  static Future<String> getCurrentLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? 'en';
  }

  static Future<void> setLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
  }

  static String translate(String key, {String? languageCode}) {
    final lang = languageCode ?? 'en'; // Default to English if not specified
    return _translations[lang]?[key] ?? _translations['en']?[key] ?? key;
  }

  static String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'id':
        return 'Indonesia';
      case 'zh':
        return '中文';
      default:
        return 'English';
    }
  }

  static List<Map<String, String>> getAvailableLanguages() {
    return [
      {'code': 'en', 'name': 'English'},
      {'code': 'id', 'name': 'Indonesia'},
      {'code': 'zh', 'name': '中文'},
    ];
  }
}
