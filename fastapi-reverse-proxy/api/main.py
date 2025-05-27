from fastapi import FastAPI, HTTPException, Depends, status, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.responses import JSONResponse, Response
from pydantic import BaseModel, EmailStr, Field
from typing import List, Optional
import uvicorn
import time
import asyncio
import redis.asyncio as redis
from datetime import datetime, timedelta
import jwt
import hashlib
import os
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST

# Configuration
SECRET_KEY = os.getenv("SECRET_KEY", "your-secret-key-change-in-production")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30
REDIS_URL = os.getenv("REDIS_URL", "redis://redis:6379")

# Metrics
request_count = Counter('fastapi_requests_total', 'Total requests', ['method', 'endpoint'])
request_duration = Histogram('fastapi_request_duration_seconds', 'Request duration')

# FastAPI app
app = FastAPI(
    title="FastAPI Secure Microservice",
    description="High-performance API behind reverse proxy",
    version="1.0.0",
    docs_url="/api/docs",
    redoc_url="/api/redoc",
    openapi_url="/api/openapi.json"
)

# Security middleware
app.add_middleware(
    TrustedHostMiddleware, 
    allowed_hosts=["localhost", "127.0.0.1", "*.yourdomain.com", "api"]
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "https://yourdomain.com"],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["*"],
)

# Security
security = HTTPBearer()

# Redis connection
redis_client = None

@app.on_event("startup")
async def startup_event():
    global redis_client
    try:
        redis_client = redis.from_url(REDIS_URL, decode_responses=True)
        await redis_client.ping()
        print("✅ Connected to Redis")
    except Exception as e:
        print(f"❌ Redis connection failed: {e}")
        redis_client = None

@app.on_event("shutdown")
async def shutdown_event():
    if redis_client:
        await redis_client.close()

# Middleware for metrics
@app.middleware("http")
async def metrics_middleware(request: Request, call_next):
    start_time = time.time()
    
    response = await call_next(request)
    
    # Record metrics
    duration = time.time() - start_time
    request_count.labels(method=request.method, endpoint=request.url.path).inc()
    request_duration.observe(duration)
    
    # Add security headers
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
    
    return response

# Pydantic models
class UserCreate(BaseModel):
    username: str = Field(..., min_length=3, max_length=50)
    email: EmailStr
    password: str = Field(..., min_length=8)
    full_name: Optional[str] = None

class UserResponse(BaseModel):
    id: str
    username: str
    email: str
    full_name: Optional[str]
    created_at: datetime
    is_active: bool

class LoginRequest(BaseModel):
    username: str
    password: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str
    expires_in: int

class HealthResponse(BaseModel):
    status: str
    timestamp: datetime
    version: str
    uptime_seconds: float
    redis_status: str

# Utility functions
def hash_password(password: str) -> str:
    return hashlib.sha256(password.encode()).hexdigest()

def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    try:
        payload = jwt.decode(credentials.credentials, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise HTTPException(status_code=401, detail="Invalid token")
        return username
    except jwt.PyJWTError:
        raise HTTPException(status_code=401, detail="Invalid token")

# Routes
@app.get("/", response_model=dict)
async def root():
    return {
        "message": "🚀 FastAPI Secure Microservice",
        "version": "1.0.0",
        "docs": "/api/docs",
        "health": "/health",
        "metrics": "/metrics"
    }

@app.get("/health", response_model=HealthResponse)
async def health_check():
    start_time = getattr(app.state, 'start_time', time.time())
    uptime = time.time() - start_time
    
    # Check Redis connection
    redis_status = "connected"
    if redis_client:
        try:
            await redis_client.ping()
        except:
            redis_status = "disconnected"
    else:
        redis_status = "not_configured"
    
    return HealthResponse(
        status="healthy",
        timestamp=datetime.utcnow(),
        version="1.0.0",
        uptime_seconds=uptime,
        redis_status=redis_status
    )

@app.get("/metrics")
async def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)

@app.post("/api/auth/register", response_model=UserResponse)
async def register_user(user: UserCreate):
    # In a real app, you'd save to a database
    user_data = {
        "id": hashlib.md5(user.username.encode()).hexdigest()[:8],
        "username": user.username,
        "email": user.email,
        "full_name": user.full_name,
        "password_hash": hash_password(user.password),
        "created_at": datetime.utcnow(),
        "is_active": True
    }
    
    # Cache in Redis if available
    if redis_client:
        await redis_client.hset(f"user:{user_data['id']}", mapping={
            "username": user_data["username"],
            "email": user_data["email"],
            "full_name": user_data["full_name"] or "",
            "created_at": user_data["created_at"].isoformat(),
            "is_active": str(user_data["is_active"])
        })
    
    return UserResponse(**user_data)

@app.post("/api/auth/login", response_model=TokenResponse)
async def login_user(login_data: LoginRequest):
    # In a real app, you'd verify against a database
    # For demo, accept any username with password "password123"
    if login_data.password == "password123":
        access_token = create_access_token(data={"sub": login_data.username})
        return TokenResponse(
            access_token=access_token,
            token_type="bearer",
            expires_in=ACCESS_TOKEN_EXPIRE_MINUTES * 60
        )
    
    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Incorrect username or password"
    )

@app.get("/api/users/me", response_model=dict)
async def get_current_user(current_user: str = Depends(verify_token)):
    return {
        "username": current_user,
        "message": f"Hello, {current_user}! You are authenticated."
    }

@app.get("/api/data", response_model=List[dict])
async def get_sample_data(current_user: str = Depends(verify_token)):
    # Simulate async database call
    await asyncio.sleep(0.1)
    
    return [
        {"id": 1, "name": "Sample Item 1", "value": 100},
        {"id": 2, "name": "Sample Item 2", "value": 200},
        {"id": 3, "name": "Sample Item 3", "value": 300}
    ]

@app.get("/api/performance-test")
async def performance_test():
    """Endpoint for load testing"""
    # Simulate some work
    await asyncio.sleep(0.01)
    return {
        "message": "Performance test endpoint",
        "timestamp": datetime.utcnow().isoformat(),
        "random_number": hash(str(time.time())) % 1000
    }

# Store start time
app.state.start_time = time.time()

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )