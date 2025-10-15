// StreamBuilder<QuerySnapshot>(
//   stream: FirebaseFirestore.instance
//       .collection('borrow_requests')
//       .where('status', isEqualTo: 'borrowed')
//       .where('dueDate', isLessThan: Timestamp.now())
//       .orderBy('dueDate')
//       .snapshots(),
//   builder: (context, snapshot) {
//     if (!snapshot.hasData) return CircularProgressIndicator();

//     final docs = snapshot.data!.docs;

//     return ListView.builder(
//       itemCount: docs.length,
//       itemBuilder: (context, index) {
//         final data = docs[index].data() as Map<String, dynamic>;
//         return ListTile(
//           title: Text(data['bookTitle']),
//           subtitle: Text('User: ${data['userId']} | Due: ${data['dueDate'].toDate()}'),
//         );
//       },
//     );
//   },
// )
