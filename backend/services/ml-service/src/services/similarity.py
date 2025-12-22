import json
from pathlib import Path
from typing import List
from collections import Counter

class SimilarityService:
    def __init__(self):
        self.books = []
        self.genre_index = {}  # genre -> list of book indices
        self._load_books()
        self._build_index()
    
    def _load_books(self):
        """Load book data"""
        try:
            data_path = Path(__file__).parent.parent.parent.parent.parent.parent / "src" / "data" / "book-details.json"
            if data_path.exists():
                with open(data_path, 'r', encoding='utf-8') as f:
                    self.books = json.load(f)
        except Exception as e:
            print(f"Error loading books: {e}")
            self.books = []
    
    def _build_index(self):
        """Build genre index for fast lookup"""
        self.genre_index = {}
        for idx, book in enumerate(self.books):
            for genre in book.get('genres', []):
                if genre not in self.genre_index:
                    self.genre_index[genre] = []
                self.genre_index[genre].append(idx)
    
    def is_ready(self) -> bool:
        return len(self.books) > 0
    
    def _compute_similarity(self, book1: dict, book2: dict) -> float:
        """Compute content-based similarity between two books"""
        score = 0.0
        
        # Genre overlap (weight: 0.5)
        genres1 = set(book1.get('genres', []))
        genres2 = set(book2.get('genres', []))
        if genres1 and genres2:
            genre_overlap = len(genres1 & genres2) / len(genres1 | genres2)
            score += 0.5 * genre_overlap
        
        # Same author (weight: 0.3)
        authors1 = set(book1.get('author', []))
        authors2 = set(book2.get('author', []))
        if authors1 & authors2:
            score += 0.3
        
        # Same language (weight: 0.1)
        if book1.get('language') == book2.get('language'):
            score += 0.1
        
        # Similar year (weight: 0.1)
        year1 = book1.get('year', 0)
        year2 = book2.get('year', 0)
        if year1 and year2:
            year_diff = abs(year1 - year2)
            if year_diff <= 5:
                score += 0.1 * (1 - year_diff / 5)
        
        return round(score, 3)
    
    def get_similar_books(self, book_id: str, n_items: int = 6) -> List[dict]:
        """Find books similar to given book"""
        # Find the source book
        source_book = None
        source_idx = -1
        for idx, book in enumerate(self.books):
            if book.get('isbn') == book_id:
                source_book = book
                source_idx = idx
                break
        
        if not source_book:
            return []
        
        # Find candidate books from same genres
        candidate_indices = set()
        for genre in source_book.get('genres', []):
            candidate_indices.update(self.genre_index.get(genre, []))
        
        # Remove source book
        candidate_indices.discard(source_idx)
        
        # Compute similarities
        similarities = []
        for idx in candidate_indices:
            book = self.books[idx]
            sim_score = self._compute_similarity(source_book, book)
            similarities.append((idx, sim_score))
        
        # Sort by similarity
        similarities.sort(key=lambda x: x[1], reverse=True)
        
        # Return top N
        result = []
        for idx, score in similarities[:n_items]:
            book = self.books[idx]
            result.append({
                "isbn": book.get('isbn'),
                "title": book.get('title'),
                "author": book.get('author'),
                "coverUrl": book.get('coverUrl'),
                "genres": book.get('genres'),
                "similarity": score
            })
        
        return result


