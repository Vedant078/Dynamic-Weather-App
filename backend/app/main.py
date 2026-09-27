from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings
from app.api.routes import personas, rmc_batches, rmc_routes, rmc_risk, rmc_outcomes, simulation, weather
from app.websocket import telemetry_stream
from app.ml.model import model_manager


app = FastAPI(
    title=settings.APP_NAME,
    description="Multi-Persona Weather Intelligence & RMC Logistics Risk Engine API",
    version="1.0.0"
)

# Enable CORS for Flutter mobile / web clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API Routers
app.include_router(personas.router, prefix=settings.API_V1_PREFIX)
app.include_router(rmc_batches.router, prefix=settings.API_V1_PREFIX)
app.include_router(rmc_routes.router, prefix=settings.API_V1_PREFIX)
app.include_router(rmc_risk.router, prefix=settings.API_V1_PREFIX)
app.include_router(rmc_outcomes.router, prefix=settings.API_V1_PREFIX)
app.include_router(simulation.router, prefix=settings.API_V1_PREFIX)
app.include_router(weather.router, prefix=settings.API_V1_PREFIX)
app.include_router(telemetry_stream.router)


@app.get("/")
def root():
    return {
        "app": settings.APP_NAME,
        "status": "OPERATIONAL",
        "primary_engine": "Ready-Mix Concrete Transit Loss Prevention",
        "model_version": model_manager.version,
        "docs_url": "/docs"
    }


@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "ml_engine_ready": model_manager.gbr_model is not None,
        "models_evaluated": {
            "gbr_mae": model_manager.metrics["gbr_mae"],
            "rf_mae": model_manager.metrics["rf_mae"]
        }
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
