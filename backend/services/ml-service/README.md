# ML Service

Machine Learning service for eShelf platform.

## Features

- Personalized book recommendations
- Similar books (content-based filtering)
- Reading time estimation
- Featured/popular books ranking

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check |
| POST | `/recommendations` | Get personalized recommendations |
| POST | `/similar` | Get similar books |
| POST | `/estimate-time` | Estimate reading time |
| GET | `/featured` | Get featured books |

## Request Examples

### Get Recommendations

```bash
POST /recommendations
{
  "user_id": "user123",
  "n_items": 10,
  "exclude_ids": ["isbn1", "isbn2"]
}
```

### Get Similar Books

```bash
POST /similar
{
  "book_id": "9780099908401",
  "n_items": 6
}
```

### Estimate Reading Time

```bash
POST /estimate-time
{
  "pages": 300,
  "genre": "Văn Học"
}
```

## Setup

```bash
# Install dependencies
pip install -r requirements.txt

# Start service
uvicorn src.main:app --reload --host 0.0.0.0 --port 8000
```

## API Documentation

Interactive API docs available at: http://localhost:8000/docs

## Docker

```bash
docker build -t eshelf/ml-service .
docker run -p 8000:8000 eshelf/ml-service
```

