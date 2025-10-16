import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../logins/constants.dart';

class PreviousPapersPage extends StatefulWidget {
  const PreviousPapersPage({super.key});

  @override
  State<PreviousPapersPage> createState() => _PreviousPapersPageState();
}

class _PreviousPapersPageState extends State<PreviousPapersPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedYear = 'All';
  String _selectedSubject = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBackground,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('previous_papers')
                  .orderBy('year', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No previous year papers available',
                      style: TextStyle(color: kPrimaryBrown, fontSize: 16),
                    ),
                  );
                }

                final filteredDocs = docs.where((doc) {
                  final data = doc.data();
                  final title =
                      (data['title'] ?? '').toString().toLowerCase();
                  final subject =
                      (data['subject'] ?? '').toString().toLowerCase();
                  final year = (data['year'] ?? '').toString();
                  final query = _searchQuery.toLowerCase();

                  bool matchesSearch =
                      title.contains(query) || subject.contains(query);
                  bool matchesYear =
                      _selectedYear == 'All' || year == _selectedYear;
                  bool matchesSubject = _selectedSubject == 'All' ||
                      subject == _selectedSubject.toLowerCase();

                  return matchesSearch && matchesYear && matchesSubject;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No papers found',
                      style: TextStyle(color: kPrimaryBrown, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final data = filteredDocs[index].data();
                    return PaperListItem(
                      paperId: filteredDocs[index].id,
                      title: data['title'] ?? '',
                      subject: data['subject'] ?? '',
                      year: data['year']?.toString() ?? '',
                      semester: data['semester'] ?? '',
                      pdfUrl: data['pdfUrl'] ?? '',
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(140.0),
      child: Container(
        decoration: const BoxDecoration(
          color: kPrimaryBrown,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              ListTile(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: const Text(
                  'Previous Year Papers',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'Search papers...',
                      prefixIcon: Icon(Icons.search, color: kPrimaryBrown),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildDropdown(
              value: _selectedYear,
              items: ['All', '2024', '2023', '2022', '2021', '2020'],
              onChanged: (value) {
                setState(() {
                  _selectedYear = value!;
                });
              },
              hint: 'Year',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildDropdown(
              value: _selectedSubject,
              items: [
                'All',
                'Mathematics',
                'Physics',
                'Chemistry',
                'Computer Science',
                'Engineering',
              ],
              onChanged: (value) {
                setState(() {
                  _selectedSubject = value!;
                });
              },
              hint: 'Subject',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required String hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPrimaryBrown.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(hint),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: const TextStyle(color: kPrimaryBrown),
              ),
            );
          }).toList(),
          onChanged: onChanged,
          icon: const Icon(Icons.arrow_drop_down, color: kPrimaryBrown),
        ),
      ),
    );
  }
}

class PaperListItem extends StatelessWidget {
  final String paperId;
  final String title;
  final String subject;
  final String year;
  final String semester;
  final String pdfUrl;

  const PaperListItem({
    super.key,
    required this.paperId,
    required this.title,
    required this.subject,
    required this.year,
    required this.semester,
    required this.pdfUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEAE3DC),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kPrimaryBrown.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.description,
                    color: kPrimaryBrown,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: kPrimaryBrown,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subject,
                        style: TextStyle(
                          fontSize: 14,
                          color: kPrimaryBrown.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: kPrimaryBrown.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 14, color: kPrimaryBrown),
                      const SizedBox(width: 4),
                      Text(
                        year,
                        style: const TextStyle(
                          fontSize: 12,
                          color: kPrimaryBrown,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (semester.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      semester,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    if (pdfUrl.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Opening $title...')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('PDF not available')),
                      );
                    }
                  },
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Download'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryBrown,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
