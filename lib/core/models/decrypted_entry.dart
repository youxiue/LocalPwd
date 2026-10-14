/// 自定义字段
class CustomField {
  String key;
  String value;

  CustomField({required this.key, required this.value});

  Map<String, dynamic> toJson() => {'key': key, 'value': value};

  factory CustomField.fromJson(Map<String, dynamic> json) {
    return CustomField(
      key: json['key'] as String,
      value: json['value'] as String,
    );
  }
}

/// 解密后的条目数据
class DecryptedEntry {
  String title;
  String username;
  String password;
  String url;
  String notes;
  List<CustomField> customFields;

  DecryptedEntry({
    this.title = '',
    this.username = '',
    this.password = '',
    this.url = '',
    this.notes = '',
    List<CustomField>? customFields,
  }) : customFields = customFields ?? [];

  Map<String, dynamic> toJson() => {
    'title': title,
    'username': username,
    'password': password,
    'url': url,
    'notes': notes,
    'customFields': customFields.map((f) => f.toJson()).toList(),
  };

  factory DecryptedEntry.fromJson(Map<String, dynamic> json) {
    return DecryptedEntry(
      title: json['title'] as String? ?? '',
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
      url: json['url'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      customFields: (json['customFields'] as List?)
          ?.map((f) => CustomField.fromJson(f as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }
}
