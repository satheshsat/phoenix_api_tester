import 'api_request.dart';

enum CollectionItemType {
  project,
  service, // or folder
  request,
}

class CollectionItem {
  String id;
  String name;
  String description;
  CollectionItemType type;
  String? parentId;
  ApiRequest? request;
  List<CollectionItem> children;
  bool isExpanded;

  CollectionItem({
    required this.id,
    required this.name,
    this.description = '',
    required this.type,
    this.parentId,
    this.request,
    List<CollectionItem>? children,
    this.isExpanded = true,
  }) : children = children ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'type': type.name,
        'parentId': parentId,
        'request': request?.toJson(),
        'children': children.map((e) => e.toJson()).toList(),
        'isExpanded': isExpanded,
      };

  factory CollectionItem.fromJson(Map<String, dynamic> json) => CollectionItem(
        id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: json['name'] as String? ?? 'Unnamed',
        description: json['description'] as String? ?? '',
        type: CollectionItemType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => CollectionItemType.request,
        ),
        parentId: json['parentId'] as String?,
        request: json['request'] != null
            ? ApiRequest.fromJson(json['request'] as Map<String, dynamic>)
            : null,
        children: (json['children'] as List<dynamic>?)
                ?.map((e) => CollectionItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        isExpanded: json['isExpanded'] as bool? ?? true,
      );

  CollectionItem copyWith({
    String? id,
    String? name,
    String? description,
    CollectionItemType? type,
    String? parentId,
    ApiRequest? request,
    List<CollectionItem>? children,
    bool? isExpanded,
  }) {
    return CollectionItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      parentId: parentId ?? this.parentId,
      request: request ?? this.request?.copyWith(),
      children: children ?? this.children.map((e) => e.copyWith()).toList(),
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }
}

