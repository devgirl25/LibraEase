// Simple local importer that fetches Google Books and writes to Firestore using Admin SDK.
// Usage: provide GOOGLE_APPLICATION_CREDENTIALS env var pointing to service account JSON, then run `npm install` and `npm run import`.

const admin = require('firebase-admin');
const fetch = require('node-fetch');

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.error('Set GOOGLE_APPLICATION_CREDENTIALS to your service account json path');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});

const db = admin.firestore();

const DEFAULT_QUERIES = ['programming', 'flutter', 'computer science'];
const API_KEY = process.env.GOOGLE_BOOKS_API_KEY || '';

async function search(q) {
  const params = new URLSearchParams({ q, maxResults: '12' });
  if (API_KEY) params.append('key', API_KEY);
  const url = `https://www.googleapis.com/books/v1/volumes?${params.toString()}`;
  const res = await fetch(url);
  if (!res.ok) throw new Error(`Books API ${res.status} ${await res.text()}`);
  const body = await res.json();
  return body.items || [];
}

async function addIfNew(item) {
  const info = item.volumeInfo || {};
  const title = info.title || '';
  const authors = (info.authors || []).join(', ');
  const sourceId = item.id || null;
  const coll = db.collection('ebooks');
  if (sourceId) {
    const q = await coll.where('source', '==', 'google_books').where('sourceId', '==', sourceId).limit(1).get();
    if (!q.empty) return false;
  } else {
    const q = await coll.where('title', '==', title).where('author', '==', authors).limit(1).get();
    if (!q.empty) return false;
  }

  const image = (info.imageLinks && info.imageLinks.thumbnail) ? info.imageLinks.thumbnail : '';
  const access = item.accessInfo || {};
  const preview = access.webReaderLink || info.previewLink || '';

  await coll.add({
    title,
    author: authors,
    imageUrl: image,
    pdfUrl: preview,
    source: 'google_books',
    sourceId: sourceId,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return true;
}

(async () => {
  try {
    let added = 0;
    for (const q of DEFAULT_QUERIES) {
      const items = await search(q);
      for (const it of items) {
        const ok = await addIfNew(it);
        if (ok) added++;
      }
    }
    console.log('Import finished. Added:', added);
  } catch (e) {
    console.error('Import failed', e);
    process.exit(1);
  }
})();
