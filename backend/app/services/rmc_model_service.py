import time
import logging
from typing import Dict, Any, Optional
from app.ml.model import model_manager
from app.models.schemas import RiskLevel

logger = logging.getLogger("rmc.model")


class RMCModelService:
    """
    Authoritative Canonical Service for Ready-Mix Concrete ML Model & Operational Decision Engine.
    Executes:
    1. Feature extraction
    2. ML model inference (GBR / Random Forest slump retention prediction)
    3. Operational decision rules (PRD Section 3.2 - 3.4 & 4.3 - 4.5)
    4. Structured audit logging proving real inference execution
    """

    @classmethod
    def calculate_delivery_risk(cls, delivery_context: Dict[str, Any]) -> Dict[str, Any]:
        start_time = time.perf_counter()

        delivery_id = str(delivery_context.get("batch_id") or delivery_context.get("id") or "UNKNOWN")
        
        # Execute ML prediction & operational risk rules
        res = model_manager.predict_batch_risk(delivery_context)
        
        execution_ms = round((time.perf_counter() - start_time) * 1000.0, 2)
        model_version = res.get("model_version", "GBR-RMC-v2.0")
        risk_level = str(res.get("decision", "SAFE"))
        predicted_slump = float(res.get("predicted_slump_mm", 0.0))
        slump_retention = float(res.get("slump_retention", 1.0))

        # Structured audit logging (Prompt Section 19)
        logger.info(
            f"RMC_MODEL_INFERENCE delivery_id={delivery_id} "
            f"model_version={model_version} "
            f"grade={delivery_context.get('concrete_grade', 'M35')} "
            f"transit_min={delivery_context.get('planned_transit_minutes', delivery_context.get('eta_minutes', 0))} "
            f"predicted_slump={predicted_slump}mm "
            f"retention={slump_retention:.3f} "
            f"risk_level={risk_level} "
            f"execution_ms={execution_ms}ms"
        )

        # Standard canonical fields (Section 15) alongside existing keys for compatibility
        res["risk_level"] = risk_level
        res["predicted_slump_retention"] = slump_retention
        res["predicted_slump_at_arrival"] = predicted_slump
        res["transit_minutes"] = float(res.get("planned_transit_minutes", delivery_context.get("planned_transit_minutes", 0.0)))
        res["arrival_time"] = str(res.get("expected_arrival_time", "--:--"))
        res["explanation"] = res.get("contributors", [])
        res["recommendations"] = [res.get("recommended_action")] if res.get("recommended_action") else []
        res["execution_ms"] = execution_ms

        return res


rmc_model_service = RMCModelService()
