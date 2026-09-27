from typing import Dict, Any, List, Tuple, Optional
import numpy as np
from app.config import settings
from app.models.schemas import RiskLevel, MitigationAction, RiskPredictResponse
from app.ml.features import extract_feature_vector, FEATURE_NAMES
from app.ml.training import train_rmc_models


from app.services.rmc_risk_engine import calculate_delivery_risk


class RMCModelManager:
    _instance = None
    
    def __init__(self):
        self.gbr_model = None
        self.rf_model = None
        self.metrics = None
        self.version = "GBR-RMC-v2.0"
        self._initialize_models()
        
    def _initialize_models(self):
        self.gbr_model, self.rf_model, self.metrics = train_rmc_models()

    @classmethod
    def get_instance(cls):
        if cls._instance is None:
            cls._instance = RMCModelManager()
        return cls._instance

    def predict_batch_risk(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Executes full inference:
        1. Feature extraction
        2. GBR predicted slump retention (ML Inference Layer)
        3. Multi-factor operational decision via centralized calculate_delivery_risk
        """
        features = extract_feature_vector(data)
        features_2d = features.reshape(1, -1)
        
        # Predicted slump retention ratio from ML model
        try:
            raw_retention = float(self.gbr_model.predict(features_2d)[0])
            ml_retention = float(np.clip(raw_retention, 0.70, 0.99))
        except Exception:
            ml_retention = None

        # Execute centralized risk engine with ML-supplied retention
        res = calculate_delivery_risk(data, ml_model_retention=ml_retention)
        res["model_version"] = self.version
        return res


model_manager = RMCModelManager.get_instance()

