// Example Cloud Function HTTP handler for importing ebooks (for emulator or Cloud Functions).
// Deploying scheduled imports requires Blaze billing. This file is for reference/testing only.

const admin = require('firebase-admin');
const fetch = require('node-fetch');

admin.initializeApp();
const db = admin.firestore();

const DEFAULT_QUERIES = ['programming', 'flutter', 'computer science'];

async function search(q, apiKey) {
  const params = new URLSearchParams({ q, maxResults: '12' });
  if (apiKey) params.append('key', apiKey);
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

exports.importEbooksHttp = async (req, res) => {
  const apiKey = req.query.key || process.env.GOOGLE_BOOKS_API_KEY || '';
  try {
    let added = 0;
    for (const q of DEFAULT_QUERIES) {
      const items = await search(q, apiKey);
      for (const it of items) {
        const ok = await addIfNew(it);
        if (ok) added++;
      }
    }
    res.status(200).json({ added });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: e.message });
  }
};
