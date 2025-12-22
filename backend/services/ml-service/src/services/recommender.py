import json
import os
from pathlib import Path
from typing import List, Optional
import random

class RecommenderService:
    def __init__(self):
        self.books = []
        self._load_books()
    
    def _load_books(self):
        """Load book data"""
        try:
            # Try to load from frontend data
            data_path = Path(__file__).parent.parent.parent.parent.parent.parent / "src" / "data" / "book-details.json"
            if data_path.exists():
                with open(data_path, 'r', encoding='utf-8') as f:
                    self.books = json.load(f)
        except Exception as e:
            print(f"Error loading books: {e}")
            self.books = []
    
    def is_ready(self) -> bool:
        return len(self.books) > 0
    
    def get_recommendations(
        self, 
        user_id: str, 
        n_items: int = 10,
        exclude_ids: List[str] = None
    ) -> List[dict]:
        """Get personalized recommendations for a user"""
        exclude_ids = exclude_ids or []
        
        # Filter out excluded books
        available_books = [b for b in self.books if b.get('isbn') not in exclude_ids]
        
        # Simple collaborative filtering simulation
        # In production, use actual user history and ML model
        
        # For now, return random selection weighted by rating
        weighted_books = []
        for book in available_books:
            rating = float(book.get('ratingAvg', 3.5) if book.get('ratingAvg') else 3.5)
            weight = rating ** 2  # Square rating to increase weight of good books
            weighted_books.extend([book] * int(weight))
        
        # Select random books from weighted list
        if len(weighted_books) > n_items:
            selected = random.sample(weighted_books, n_items)
        else:
            selected = weighted_books[:n_items]
        
        # Remove duplicates while preserving order
        seen = set()
        unique_selected = []
        for book in selected:
            isbn = book.get('isbn')
            if isbn not in seen:
                seen.add(isbn)
                unique_selected.append({
                    "isbn": book.get('isbn'),
                    "title": book.get('title'),
                    "author": book.get('author'),
                    "coverUrl": book.get('coverUrl'),
                    "ratingAvg": book.get('ratingAvg'),
                    "score": round(random.uniform(0.7, 1.0), 2)  # Recommendation score
                })
        
        return unique_selected[:n_items]
    
    def get_popular_books(self, limit: int = 10) -> List[dict]:
        """Get popular books"""
        # Sort by view count (simulated)
        sorted_books = sorted(
            self.books, 
            key=lambda x: x.get('viewCount', 0),
            reverse=True
        )
        
        return [
            {
                "isbn": b.get('isbn'),
                "title": b.get('title'),
                "author": b.get('author'),
                "coverUrl": b.get('coverUrl'),
                "ratingAvg": b.get('ratingAvg'),
                "viewCount": b.get('viewCount', 0)
            }
            for b in sorted_books[:limit]
        ]


