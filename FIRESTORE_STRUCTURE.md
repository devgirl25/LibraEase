# Firestore Database Structure

## Collection Structure

### 1. `books` (Main Collection)
Physical books available in the library.

```
books/{bookId}
├── title: string
├── author: string
├── description: string
├── imageUrl: string (URL to book cover)
├── category: string (e.g., "Computer", "Physics", "Mathematics")
├── available: boolean
└── addedAt: timestamp
```

**Example Document:**
```json
{
  "title": "Introduction to Algorithms",
  "author": "Thomas H. Cormen",
  "description": "A comprehensive guide to algorithms",
  "imageUrl": "https://example.com/book-cover.jpg",
  "category": "Computer Science",
  "available": true,
  "addedAt": "2024-01-15T10:30:00Z"
}
```

### 2. `ebooks` (Main Collection)
Digital books and resources.

```
ebooks/{ebookId}
├── title: string
├── author: string
├── category: string
└── pdfUrl: string (URL to PDF file)
```

**Example Document:**
```json
{
  "title": "Software Engineering Fundamentals",
  "author": "Dr. John Smith",
  "category": "Computer Science",
  "pdfUrl": "https://example.com/ebook.pdf"
}
```

### 3. `previous_papers` (Main Collection)
Previous year examination papers.

```
previous_papers/{paperId}
├── title: string
├── subject: string
├── year: number
├── semester: string
└── pdfUrl: string
```

**Example Document:**
```json
{
  "title": "Computer Networks Final Exam 2023",
  "subject": "Computer Networks",
  "year": 2023,
  "semester": "Semester 6",
  "pdfUrl": "https://example.com/paper-2023.pdf"
}
```

### 4. `registration_requests` (Main Collection)
Student registration requests for library access.

```
registration_requests/{requestId}
├── userId: string (Firebase Auth UID)
├── status: string ("pending", "approved", "rejected")
├── timestamp: timestamp
└── remarks: string (admin comments)
```

**Example Document:**
```json
{
  "userId": "abc123xyz",
  "status": "approved",
  "timestamp": "2024-01-15T10:30:00Z",
  "remarks": "Verified student ID"
}
```

### 5. `borrow_requests` (Main Collection)
Borrow requests for admin approval.

```
borrow_requests/{requestId}
├── bookId: string
├── bookTitle: string
├── userId: string
├── borrowDate: timestamp
├── dueDate: timestamp
└── status: string ("pending", "approved", "rejected")
```

### 6. `users` (Main Collection)
User profiles and subcollections.

```
users/{userId}
├── name: string
├── email: string
├── id: string (student/staff ID)
├── role: string ("student", "admin")
└── createdAt: timestamp
```

## User Subcollections

### 6.1. `users/{userId}/wishlist`
User's wishlisted physical books.

```
users/{userId}/wishlist/{bookId}
├── bookId: string
├── title: string
├── author: string
├── imageUrl: string
├── category: string
├── available: boolean
└── timestamp: timestamp
```

### 6.2. `users/{userId}/ebook_wishlist`
User's wishlisted e-books (separate from physical books).

```
users/{userId}/ebook_wishlist/{ebookId}
├── ebookId: string
├── title: string
├── author: string
├── category: string
├── pdfUrl: string
└── timestamp: timestamp
```

### 6.3. `users/{userId}/borrow_history`
User's borrowing history.

```
users/{userId}/borrow_history/{historyId}
├── bookId: string
├── bookTitle: string
├── author: string (optional)
├── imageUrl: string (optional)
├── category: string (optional)
├── borrowDate: timestamp
├── dueDate: timestamp
└── status: string ("borrowed", "returned")
```

### 6.4. `users/{userId}/notifications`
User notifications.

```
users/{userId}/notifications/{notificationId}
├── title: string
├── message: string
├── timestamp: timestamp
└── read: boolean
```

### 6.5. `users/{userId}/reviews`
User book reviews (structure for future implementation).

```
users/{userId}/reviews/{reviewId}
├── bookId: string
├── rating: number (1-5)
├── review: string
└── timestamp: timestamp
```

## Firestore Indexes Required

To enable the queries used in the app, create these composite indexes:

1. **books collection:**
   - `addedAt` (Descending)

2. **ebooks collection:**
   - `title` (Ascending)

3. **previous_papers collection:**
   - `year` (Descending)

4. **registration_requests collection:**
   - `userId` (Ascending), `timestamp` (Descending)

5. **users/{userId}/wishlist subcollection:**
   - `timestamp` (Descending)

6. **users/{userId}/borrow_history subcollection:**
   - `status` (Ascending), `dueDate` (Ascending)

7. **users/{userId}/notifications subcollection:**
   - `timestamp` (Descending)

## Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper function to check if user is authenticated
    function isSignedIn() {
      return request.auth != null;
    }

    // Helper function to check if user is admin
    function isAdmin() {
      return isSignedIn() &&
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }

    // Books - Read for all authenticated users, write for admins only
    match /books/{bookId} {
      allow read: if isSignedIn();
      allow write: if isAdmin();
    }

    // E-books - Read for all authenticated users, write for admins only
    match /ebooks/{ebookId} {
      allow read: if isSignedIn();
      allow write: if isAdmin();
    }

    // Previous Papers - Read for all authenticated users, write for admins only
    match /previous_papers/{paperId} {
      allow read: if isSignedIn();
      allow write: if isAdmin();
    }

    // Registration Requests
    match /registration_requests/{requestId} {
      allow read: if isSignedIn() &&
                     (request.auth.uid == resource.data.userId || isAdmin());
      allow create: if isSignedIn() && request.auth.uid == request.resource.data.userId;
      allow update, delete: if isAdmin();
    }

    // Borrow Requests
    match /borrow_requests/{requestId} {
      allow read: if isSignedIn();
      allow create: if isSignedIn() && request.auth.uid == request.resource.data.userId;
      allow update, delete: if isAdmin();
    }

    // User documents
    match /users/{userId} {
      allow read: if isSignedIn();
      allow write: if isSignedIn() && request.auth.uid == userId || isAdmin();

      // User subcollections
      match /wishlist/{bookId} {
        allow read, write: if isSignedIn() && request.auth.uid == userId;
      }

      match /ebook_wishlist/{ebookId} {
        allow read, write: if isSignedIn() && request.auth.uid == userId;
      }

      match /borrow_history/{historyId} {
        allow read: if isSignedIn() && request.auth.uid == userId;
        allow write: if isSignedIn() &&
                       (request.auth.uid == userId || isAdmin());
      }

      match /notifications/{notificationId} {
        allow read, write: if isSignedIn() && request.auth.uid == userId;
      }

      match /reviews/{reviewId} {
        allow read: if isSignedIn();
        allow write: if isSignedIn() && request.auth.uid == userId;
      }
    }
  }
}
```

## Sample Data for Testing

### Sample Book
```javascript
db.collection('books').add({
  title: "Clean Code",
  author: "Robert C. Martin",
  description: "A handbook of agile software craftsmanship",
  imageUrl: "https://example.com/clean-code.jpg",
  category: "Software Engineering",
  available: true,
  addedAt: firebase.firestore.FieldValue.serverTimestamp()
});
```

### Sample E-Book
```javascript
db.collection('ebooks').add({
  title: "Introduction to Machine Learning",
  author: "Dr. Andrew Ng",
  category: "Computer Science",
  pdfUrl: "https://example.com/ml-intro.pdf"
});
```

### Sample Previous Paper
```javascript
db.collection('previous_papers').add({
  title: "Data Structures Final Exam 2023",
  subject: "Data Structures",
  year: 2023,
  semester: "Semester 4",
  pdfUrl: "https://example.com/ds-exam-2023.pdf"
});
```

### Sample User
```javascript
db.collection('users').doc(userId).set({
  name: "John Doe",
  email: "john@example.com",
  id: "STU2024001",
  role: "student",
  createdAt: firebase.firestore.FieldValue.serverTimestamp()
});
```

## Notes

1. **Image Storage**: Use Firebase Storage or external CDN for book cover images
2. **PDF Storage**: Use Firebase Storage for PDF files
3. **Timestamps**: Always use `FieldValue.serverTimestamp()` for consistency
4. **Data Validation**: Implement Cloud Functions for additional validation
5. **Backups**: Set up automated Firestore backups
6. **Monitoring**: Use Firestore monitoring to track usage and costs
