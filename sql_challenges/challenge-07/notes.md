## Script sample to fetch and create chunks

```
wiki = wikipediaapi.Wikipedia(
    user_agent="oracle-vector-search-lesson/1.0",
    language="en"
)

page = wiki.page(ARTICLE_TITLE)
if not page.exists():
    raise ValueError(f"Article '{ARTICLE_TITLE}' not found on Wikipedia")

print(f"✓ Fetched: {page.title}")
print(f"  Length: {len(page.text):,} characters")

# Split into paragraphs, filter short/empty ones
raw_paragraphs = [p.strip() for p in page.text.split('\n') if len(p.strip()) > 120]

# Truncate to 400 chars max per chunk (fits Oracle VARCHAR2(2000) safely)
chunks = []
for i, para in enumerate(raw_paragraphs[:30]):   # cap at 30 chunks for this lesson
    chunk = para[:400]
    # Remove references like [1], [23]
    chunk = re.sub(r'\[\d+\]', '', chunk).strip()
    if len(chunk) > 80:
        chunks.append(chunk)

print(f"  Chunks: {len(chunks)}")
print()
print("Preview of first 3 chunks:")
for i, c in enumerate(chunks[:3]):
    print(f"  [{i+1}] {c[:100]}...")
```

## Script sample to generate vector embeddings
```
# Load the model (downloads ~90MB on first run)
model = SentenceTransformer("all-MiniLM-L6-v2")
print("Model loaded ✓")

# Encode all chunks
embeddings = model.encode(chunks, show_progress_bar=True)
print(f"\nGenerated {len(embeddings)} embeddings, each with {len(embeddings[0])} dimensions")
```

## Script sample to make a question to the DB.
```
MY_QUESTION = "What denotes Semantic search?"
TOP_N = 3

q_emb = model.encode([MY_QUESTION])[0]
q_vec = format_vector(q_emb)

print(f"-- Search query: {MY_QUESTION}")
print(f"-- Top {TOP_N} most similar chunks")
print()
print("SELECT")
print("    chunk_id,")
print("    SUBSTR(chunk_text, 1, 100) AS preview,")
print(f"    ROUND(VECTOR_DISTANCE(chunk_vector, {q_vec}, COSINE), 4) AS similarity_score")
print("FROM doc_chunks")
print("ORDER BY similarity_score ASC")
print(f"FETCH FIRST {TOP_N} ROWS ONLY;")
```