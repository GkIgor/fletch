import 'package:flutter/material.dart';
import 'package:fletch/models/http_method.dart';

class CollectionConfig {
  final String id;
  String name;
  String icon;
  String color;
  bool isExpanded = true;
  final List<RequestConfig> requests;
  final FocusNode nameFocusNode;
  String? parentId;

  CollectionConfig({
    String? id,
    required this.name,
    this.icon = 'folder',
    this.color = '#8b5cf6',
    required this.requests,
    FocusNode? nameFocusNode,
    this.parentId,
  })  : id = id ?? UniqueKey().toString(),
        nameFocusNode = nameFocusNode ?? FocusNode();

  void dispose() {
    nameFocusNode.dispose();
    for (var r in requests) {
      r.focusNode.dispose();
    }
  }
}

class RequestConfig {
  HttpMethod method;
  String name;
  final FocusNode focusNode;

  RequestConfig({
    required this.method,
    required this.name,
    FocusNode? focusNode,
  }) : focusNode = focusNode ?? FocusNode();
}

class PreviewNode {
  final String name;
  final bool isCollection;
  final List<PreviewNode> children;
  final HttpMethod? method;

  PreviewNode({
    required this.name,
    required this.isCollection,
    required this.children,
    this.method,
  });
}
