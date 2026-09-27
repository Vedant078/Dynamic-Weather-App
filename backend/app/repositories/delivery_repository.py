from typing import Optional, List, Dict, Any
from datetime import datetime, timezone
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.db.models import Delivery, DeliveryRiskResult, Telemetry, DeliveryOutcome
from app.models.schemas import FleetKPI, BatchStatus, RiskLevel


class DeliveryRepository:
    @staticmethod
    def get_by_id(
        db: Session,
        delivery_id: str,
        organization: Optional[str] = None,
        user_id: Optional[str] = None
    ) -> Optional[Delivery]:
        query = db.query(Delivery).filter(Delivery.id == delivery_id)
        if organization:
            query = query.filter((Delivery.organization == organization) | (Delivery.user_id == user_id))
        elif user_id:
            query = query.filter(Delivery.user_id == user_id)
        return query.first()

    @staticmethod
    def get_by_code(
        db: Session,
        batch_code: str,
        organization: Optional[str] = None,
        user_id: Optional[str] = None
    ) -> Optional[Delivery]:
        query = db.query(Delivery).filter(Delivery.batch_code == batch_code)
        if organization:
            query = query.filter((Delivery.organization == organization) | (Delivery.user_id == user_id))
        elif user_id:
            query = query.filter(Delivery.user_id == user_id)
        return query.first()

    @staticmethod
    def get_all(
        db: Session,
        organization: Optional[str] = None,
        user_id: Optional[str] = None,
        limit: int = 50
    ) -> List[Delivery]:
        query = db.query(Delivery)
        if organization:
            query = query.filter((Delivery.organization == organization) | (Delivery.user_id == user_id))
        elif user_id:
            query = query.filter(Delivery.user_id == user_id)
        return query.order_by(Delivery.created_at.desc()).limit(limit).all()

    @staticmethod
    def create_delivery(db: Session, delivery_data: Dict[str, Any]) -> Delivery:
        delivery = Delivery(
            id=delivery_data.get("id"),
            batch_code=delivery_data["batch_code"],
            user_id=delivery_data.get("user_id"),
            organization=delivery_data.get("organization"),
            plant_id=delivery_data.get("plant_id", "plant-001"),
            plant_name=delivery_data.get("plant_name", "Ahmedabad Central Plant"),
            plant_lat=float(delivery_data.get("plant_lat", 23.0225)),
            plant_lng=float(delivery_data.get("plant_lng", 72.5714)),
            project_id=delivery_data.get("project_id", "proj-001"),
            project_name=delivery_data.get("project_name", "Site Project 01"),
            project_lat=float(delivery_data.get("project_lat", 23.0900)),
            project_lng=float(delivery_data.get("project_lng", 72.6100)),
            concrete_grade=delivery_data.get("concrete_grade", "M35").upper(),
            volume_m3=float(delivery_data.get("volume_m3", 6.0)),
            initial_slump_mm=float(delivery_data.get("initial_slump_mm", 110.0)),
            target_slump_mm=float(delivery_data.get("target_slump_mm", 105.0)),
            current_slump_mm=float(delivery_data.get("current_slump_mm", delivery_data.get("initial_slump_mm", 110.0))),
            slump_retention_ratio=float(delivery_data.get("slump_retention_ratio", 1.0)),
            concrete_temp_c=float(delivery_data.get("concrete_temp_c", 32.0)),
            ambient_temp_c=float(delivery_data.get("ambient_temp_c", 34.0)),
            relative_humidity=float(delivery_data.get("relative_humidity", 50.0)),
            dispatch_time=str(delivery_data.get("dispatch_time", "14:00")),
            requested_delivery_time=delivery_data.get("requested_delivery_time"),
            admixture_retarder=delivery_data.get("admixture_retarder", "None"),
            planned_transit_minutes=float(delivery_data.get("planned_transit_minutes", 48.0)),
            elapsed_minutes=float(delivery_data.get("elapsed_minutes", 0.0)),
            eta_minutes=float(delivery_data.get("eta_minutes", 48.0)),
            original_eta_minutes=float(delivery_data.get("original_eta_minutes", 48.0)),
            distance_remaining_km=float(delivery_data.get("distance_remaining_km", 28.5)),
            total_distance_km=float(delivery_data.get("total_distance_km", 28.5)),
            traffic_index=float(delivery_data.get("traffic_index", 0.35)),
            precipitation_prob=float(delivery_data.get("precipitation_prob", 0.0)),
            status=delivery_data.get("status", "DISPATCHED"),
            active_route_id=delivery_data.get("active_route_id", "route-a"),
        )
        db.add(delivery)
        db.commit()
        db.refresh(delivery)
        return delivery

    @staticmethod
    def save_risk_result(db: Session, delivery_id: str, risk_dict: Dict[str, Any]) -> DeliveryRiskResult:
        risk_res = DeliveryRiskResult(
            delivery_id=delivery_id,
            model_version=risk_dict.get("model_version", "GBR-RMC-v2.0"),
            predicted_slump_mm=float(risk_dict["predicted_slump_mm"]),
            slump_retention_ratio=float(risk_dict["slump_retention"]),
            heat_risk=float(risk_dict["heat_risk"]),
            travel_risk=float(risk_dict["travel_risk"]),
            delivery_risk=float(risk_dict["delivery_risk"]),
            composite_risk=float(risk_dict["composite_risk"]),
            decision=str(risk_dict["decision"]),
            sla_status=str(risk_dict.get("sla_status", "COMPLIANT")),
            primary_driver=str(risk_dict["primary_driver"]),
            contributors=risk_dict.get("contributors", []),
            recommended_action=str(risk_dict.get("recommended_action", "MONITOR_TELEMETRY")),
            input_snapshot=risk_dict.get("input_snapshot", {})
        )
        db.add(risk_res)

        # Update delivery's current slump and slump retention
        delivery = db.query(Delivery).filter(Delivery.id == delivery_id).first()
        if delivery:
            delivery.current_slump_mm = risk_res.predicted_slump_mm
            delivery.slump_retention_ratio = risk_res.slump_retention_ratio
            delivery.updated_at = datetime.now(timezone.utc)

        db.commit()
        db.refresh(risk_res)
        return risk_res

    @staticmethod
    def get_latest_risk_result(db: Session, delivery_id: str) -> Optional[DeliveryRiskResult]:
        return db.query(DeliveryRiskResult)\
            .filter(DeliveryRiskResult.delivery_id == delivery_id)\
            .order_by(DeliveryRiskResult.calculated_at.desc())\
            .first()

    @staticmethod
    def save_telemetry(db: Session, delivery_id: str, telem_data: Dict[str, Any]) -> Telemetry:
        t = Telemetry(
            delivery_id=delivery_id,
            lat=float(telem_data["lat"]),
            lng=float(telem_data["lng"]),
            speed_kmh=float(telem_data.get("speed_kmh", 35.0)),
            concrete_temp_c=float(telem_data.get("concrete_temp_c", 32.0)),
            drum_rpm=float(telem_data.get("drum_rpm", 12.0)),
            current_slump_mm=float(telem_data.get("current_slump_mm", 105.0)),
            ambient_temp_c=float(telem_data.get("ambient_temp_c", 34.0)),
            humidity_pct=float(telem_data.get("humidity_pct", 50.0)),
        )
        db.add(t)
        db.commit()
        db.refresh(t)
        return t

    @staticmethod
    def get_telemetry_history(db: Session, delivery_id: str, limit: int = 100) -> List[Telemetry]:
        return db.query(Telemetry)\
            .filter(Telemetry.delivery_id == delivery_id)\
            .order_by(Telemetry.timestamp.desc())\
            .limit(limit)\
            .all()

    @staticmethod
    def save_outcome(db: Session, outcome_data: Dict[str, Any]) -> DeliveryOutcome:
        delivery_id = outcome_data["batch_id"]
        outcome_str = outcome_data["outcome"]
        site_slump = float(outcome_data["site_slump_mm"])
        transit_min = float(outcome_data["actual_transit_minutes"])
        conc_temp = float(outcome_data["site_concrete_temp_c"])
        rejection_reason = outcome_data.get("rejection_reason")

        is_rejected = outcome_str.lower() == "rejected"
        financial_impact = 241000.0 if is_rejected else 168000.0
        financial_type = "MATERIAL_LOSS" if is_rejected else "AVOIDED_LOSS"
        quality_grade = "REJECTED_UNUSABLE" if is_rejected else "HIGH_SPEC_DELIVERY"
        slump_variance = site_slump - 110.0

        existing = db.query(DeliveryOutcome).filter(DeliveryOutcome.delivery_id == delivery_id).first()
        if existing:
            existing.outcome = outcome_str
            existing.quality_grade = quality_grade
            existing.site_slump_mm = site_slump
            existing.slump_variance_mm = slump_variance
            existing.actual_transit_minutes = transit_min
            existing.site_concrete_temp_c = conc_temp
            existing.financial_impact_inr = financial_impact
            existing.financial_type = financial_type
            existing.rejection_reason = rejection_reason
            existing.recorded_at = datetime.now(timezone.utc)
            outcome = existing
        else:
            outcome = DeliveryOutcome(
                delivery_id=delivery_id,
                outcome=outcome_str,
                quality_grade=quality_grade,
                site_slump_mm=site_slump,
                slump_variance_mm=slump_variance,
                actual_transit_minutes=transit_min,
                site_concrete_temp_c=conc_temp,
                financial_impact_inr=financial_impact,
                financial_type=financial_type,
                rejection_reason=rejection_reason,
                recorded_at=datetime.now(timezone.utc)
            )
            db.add(outcome)

        # Update delivery status
        delivery = db.query(Delivery).filter(Delivery.id == delivery_id).first()
        if delivery:
            delivery.status = "REJECTED" if is_rejected else "DELIVERED"
            delivery.updated_at = datetime.now(timezone.utc)

        db.commit()
        db.refresh(outcome)
        return outcome

    @staticmethod
    def get_fleet_kpi(
        db: Session,
        organization: Optional[str] = None,
        user_id: Optional[str] = None
    ) -> FleetKPI:
        query = db.query(Delivery)
        if organization:
            query = query.filter((Delivery.organization == organization) | (Delivery.user_id == user_id))
        elif user_id:
            query = query.filter(Delivery.user_id == user_id)
        
        deliveries = query.all()
        active = [d for d in deliveries if d.status in ("DISPATCHED", "IN_TRANSIT", "AT_RISK", "REROUTED")]
        
        high_risk_count = 0
        watch_count = 0
        on_time_count = 0
        total_transit = 0.0
        at_risk_vol = 0.0

        for d in active:
            total_transit += d.eta_minutes
            if d.eta_minutes <= d.original_eta_minutes + 5.0:
                on_time_count += 1

            latest_risk = db.query(DeliveryRiskResult)\
                .filter(DeliveryRiskResult.delivery_id == d.id)\
                .order_by(DeliveryRiskResult.calculated_at.desc())\
                .first()

            if latest_risk:
                if latest_risk.decision in ("HIGH_RISK", "CRITICAL"):
                    high_risk_count += 1
                    at_risk_vol += d.volume_m3
                elif latest_risk.decision == "WATCH":
                    watch_count += 1

        avg_transit = round(total_transit / len(active), 1) if active else 0.0
        potential_loss = at_risk_vol * 40166.67

        # Calculate actual avoided loss from recorded outcomes for this organization/user
        delivery_ids = [d.id for d in deliveries]
        if delivery_ids:
            outcomes = db.query(DeliveryOutcome).filter(
                DeliveryOutcome.delivery_id.in_(delivery_ids),
                DeliveryOutcome.financial_type == "AVOIDED_LOSS"
            ).all()
            loss_avoided = float(sum(o.financial_impact_inr for o in outcomes))
        else:
            loss_avoided = 0.0

        return FleetKPI(
            active_deliveries=len(active),
            high_risk_batches=high_risk_count,
            on_time_count=on_time_count,
            watch_count=watch_count,
            avg_transit_minutes=avg_transit,
            at_risk_volume_m3=round(at_risk_vol, 1),
            potential_loss_inr=round(potential_loss, 2),
            loss_avoided_inr=round(loss_avoided, 2),
            freshness_seconds=2
        )
