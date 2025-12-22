from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import json
import os
from pathlib import Path

# Import services
from services.recommender import RecommenderService
from services.similarity import SimilarityService

app = FastAPI(
    title="eShelf ML Service",
    description="Machine Learning service for book recommendations",
    version="1.0.0"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173", "http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize services
recommender = RecommenderService()
similarity = SimilarityService()

# Request/Response models
class RecommendationRequest(BaseModel):
    user_id: str
    n_items: int = 10
    exclude_ids: Optional[List[str]] = None

class RecommendationResponse(BaseModel):
    success: bool
    data: List[dict]

class SimilarBooksRequest(BaseModel):
    book_id: str
    n_items: int = 6

class ReadingTimeRequest(BaseModel):
    pages: int
    genre: Optional[str] = None

# Health check
@app.get("/health")
async def health_check():
    return {
        "status": "ok",
        "service": "ml-service",
        "models": {
            "recommender": recommender.is_ready(),
            "similarity": similarity.is_ready()
        }
    }

# Get recommendations
@app.post("/recommendations", response_model=RecommendationResponse)
async def get_recommendations(request: RecommendationRequest):
    try:
        recommendations = recommender.get_recommendations(
            user_id=request.user_id,
            n_items=request.n_items,
            exclude_ids=request.exclude_ids or []
        )
        return {"success": True, "data": recommendations}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Get similar books
@app.post("/similar")
async def get_similar_books(request: SimilarBooksRequest):
    try:
        similar = similarity.get_similar_books(
            book_id=request.book_id,
            n_items=request.n_items
        )
        return {"success": True, "data": similar}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Estimate reading time
@app.post("/estimate-time")
async def estimate_reading_time(request: ReadingTimeRequest):
    try:
        # Average reading speed: 250 words per minute
        # Average words per page: 250
        words_per_page = 250
        words_per_minute = 250
        
        # Adjust for genre
        genre_multiplier = 1.0
        if request.genre:
            genre_lower = request.genre.lower()
            if "kỹ thuật" in genre_lower or "khoa học" in genre_lower:
                genre_multiplier = 1.3  # Technical content takes longer
            elif "truyện tranh" in genre_lower:
                genre_multiplier = 0.5  # Comics are faster
        
        total_words = request.pages * words_per_page
        minutes = int((total_words / words_per_minute) * genre_multiplier)
        
        return {
            "success": True,
            "data": {
                "minutes": minutes,
                "hours": round(minutes / 60, 1),
                "formatted": f"{minutes // 60}h {minutes % 60}m" if minutes >= 60 else f"{minutes} phút"
            }
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Featured/popular books (ML-enhanced)
@app.get("/featured")
async def get_featured_books(limit: int = 10):
    try:
        featured = recommender.get_popular_books(limit)
        return {"success": True, "data": featured}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)


