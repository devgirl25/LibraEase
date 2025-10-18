import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:libra/screens/logins/constants.dart' show kGoogleBooksApiKey;

/// Admin page to search Google Books and add ebooks idempotently to Firestore.
/// Also provides a simple "monthly schedule" write to Firestore (cron placeholder)
/// and a "Run import now" button that will import a small set of sample queries.
class AddEBooksPage extends StatefulWidget {
  const AddEBooksPage({super.key});

  @override
  State<AddEBooksPage> createState() => _AddEBooksPageState();
}

class _AddEBooksPageState extends State<AddEBooksPage> {
  final TextEditingController _qCtrl = TextEditingController();
  final TextEditingController _apiKeyCtrl = TextEditingController();
  bool _loading = false;
  bool _runningImport = false;
  bool _monthlyEnabled = false;

  final List<String> _defaultQueries = [
    'programming',
    'flutter',
    'computer science',
  ];

  @override
  void initState() {
    super.initState();
    _loadScheduleState();
  }

  @override
  void dispose() {
    _qCtrl.dispose();
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadScheduleState() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('schedules')
          .doc('import_ebooks')
          .get();
      if (doc.exists) {
        final data = doc.data();
        final enabled = (data?['monthly'] ?? false) as bool;
        if (mounted) setState(() => _monthlyEnabled = enabled);
      }
    } catch (_) {
      // ignore
    }
  }

  Future<List<Map<String, dynamic>>> _searchGoogleBooks(String q,
      {String? apiKey}) async {
    final params = <String, String>{'q': q, 'maxResults': '12'};
    final effectiveKey =
        apiKey ?? (kGoogleBooksApiKey.isNotEmpty ? kGoogleBooksApiKey : null);
    if (effectiveKey != null) params['key'] = effectiveKey;
    final uri = Uri.https('www.googleapis.com', '/books/v1/volumes', params);
    final res = await http.get(uri);
    if (res.statusCode != 200)
      throw Exception('Google Books error ${res.statusCode}');
    final body = json.decode(res.body) as Map<String, dynamic>;
    final items = (body['items'] as List<dynamic>?) ?? [];
    return items.cast<Map<String, dynamic>>();
  }

  Future<void> _addEbookFromItem(Map<String, dynamic> it) async {
    final info = (it['volumeInfo'] ?? {}) as Map<String, dynamic>;
    final title = (info['title'] ?? '').toString();
    final authors = (info['authors'] ?? []).join(', ');
    final image = info['imageLinks'] != null
        ? (info['imageLinks']['thumbnail'] ?? '')
        : '';
    final access = (it['accessInfo'] ?? {}) as Map<String, dynamic>;
    final preview =
        (access['webReaderLink'] ?? info['previewLink'] ?? '').toString();

    if (title.isEmpty) return;

    final coll = FirebaseFirestore.instance.collection('ebooks');

    final sourceId = it['id']?.toString();
    if (sourceId != null && sourceId.isNotEmpty) {
      final q = await coll
          .where('source', isEqualTo: 'google_books')
          .where('sourceId', isEqualTo: sourceId)
          .limit(1)
          .get();
      if (q.docs.isNotEmpty) return;
    } else {
      final q = await coll
          .where('title', isEqualTo: title)
          .where('author', isEqualTo: authors)
          .limit(1)
          .get();
      if (q.docs.isNotEmpty) return;
    }

    await coll.add({
      'title': title,
      'author': authors,
      'imageUrl': image,
      'pdfUrl': preview,
      'source': 'google_books',
      'sourceId': sourceId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _searchAndShow(String query) async {
    setState(() => _loading = true);
    try {
      final items = await _searchGoogleBooks(query);
      if (!mounted) return;

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) {
          return FractionallySizedBox(
            heightFactor: 0.9,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text('Results for "${query}"'),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final it = items[i];
                        final info =
                            (it['volumeInfo'] ?? {}) as Map<String, dynamic>;
                        final title = (info['title'] ?? '').toString();
                        final authors = (info['authors'] ?? []).join(', ');
                        final thumbnail = info['imageLinks'] != null
                            ? (info['imageLinks']['thumbnail'] ?? '')
                            : '';

                        return ListTile(
                          leading: thumbnail.isNotEmpty
                              ? Image.network(thumbnail,
                                  width: 48, fit: BoxFit.cover)
                              : null,
                          title: Text(title),
                          subtitle: Text(authors),
                          trailing: ElevatedButton(
                            onPressed: () async {
                              try {
                                await _addEbookFromItem(it);
                                if (mounted)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Added')));
                              } catch (e) {
                                if (mounted)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text('Add failed: $e')));
                              }
                            },
                            child: const Text('Add'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Search failed: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _runAdminImport() async {
    setState(() => _runningImport = true);
    int attempted = 0;
    try {
      final apiKey = _apiKeyCtrl.text.trim();
      for (final q in _defaultQueries) {
        final items =
            await _searchGoogleBooks(q, apiKey: apiKey.isEmpty ? null : apiKey);
        for (final it in items) {
          await _addEbookFromItem(it);
          attempted++;
        }
      }
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Import finished. Attempted: $attempted')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Import failed: $e')));
    } finally {
      setState(() => _runningImport = false);
    }
  }

  Future<void> _toggleMonthlySchedule(bool enable) async {
    final docRef =
        FirebaseFirestore.instance.collection('schedules').doc('import_ebooks');
    await docRef.set({
      'monthly': enable,
      'updatedAt': FieldValue.serverTimestamp(),
      'enabledBy': 'admin',
    });
    if (mounted) setState(() => _monthlyEnabled = enable);
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(enable
              ? 'Monthly schedule enabled'
              : 'Monthly schedule disabled')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin: Add E-Books')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
                controller: _apiKeyCtrl,
                decoration: const InputDecoration(
                    labelText:
                        'Optional Google Books API key (leave empty to use default)')),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: _qCtrl,
                      decoration:
                          const InputDecoration(hintText: 'Search query'))),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed:
                    _loading ? null : () => _searchAndShow(_qCtrl.text.trim()),
                child: _loading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Search'),
              ),
            ]),
            const SizedBox(height: 16),
            ElevatedButton.icon(
                onPressed: _runningImport ? null : _runAdminImport,
                icon: const Icon(Icons.refresh),
                label: const Text('Run import (admin)')),
            const SizedBox(height: 12),
            Row(children: [
              const Text('Monthly import schedule'),
              const Spacer(),
              Switch(
                  value: _monthlyEnabled,
                  onChanged: (v) => _toggleMonthlySchedule(v))
            ]),
          ],
        ),
      ),
    );
  }
}
