"""
MAUSAM RMC Financial Impact & Economics Calculation Engine
Derives ground-truth financial exposure, transport costs, and avoided losses
from delivery-specific inputs (concrete grade, volume, distance, delay, rejection, interventions).
"""

from typing import Dict, Any, Optional
import math


class RmcFinancialEngine:
    # Base material rate per m3 by concrete grade (IS 456 / Indian RMC benchmark rates in INR)
    GRADE_RATES_INR_PER_M3 = {
        "M15": 3600.0,
        "M20": 3950.0,
        "M25": 4350.0,
        "M30": 4800.0,
        "M35": 5300.0,
        "M40": 5900.0,
        "M45": 6550.0,
        "M50": 7200.0,
    }
    DEFAULT_MATERIAL_RATE_PER_M3 = 4800.0

    # Operational economics
    TRANSPORT_RATE_PER_KM = 75.0         # INR per km transit mixer logistics
    PUMPING_RATE_PER_M3 = 250.0          # INR per m3 handling / pumping
    DELAY_COST_PER_MINUTE = 45.0         # INR per minute idle / turn delay beyond threshold
    DISPOSAL_COST_PER_M3 = 850.0         # INR per m3 environmental dumping/crushing
    RETARDER_INTERVENTION_BASE_INR = 1500.0 # Standard chemical retarder dosage per truck batch

    @classmethod
    def get_material_rate(cls, grade: Optional[str]) -> float:
        if not grade:
            return cls.DEFAULT_MATERIAL_RATE_PER_M3
        norm = grade.strip().upper()
        return cls.GRADE_RATES_INR_PER_M3.get(norm, cls.DEFAULT_MATERIAL_RATE_PER_M3)

    @classmethod
    def calculate_delivery_economics(
        cls,
        volume_m3: float,
        concrete_grade: str,
        total_distance_km: float,
        actual_transit_minutes: float = 0.0,
        sla_minutes: float = 78.0,
        outcome: str = "accepted",
        has_intervention: bool = False,
        extra_reroute_km: float = 0.0,
        composite_risk: float = 25.0
    ) -> Dict[str, Any]:
        """
        Calculates delivery-specific economics and financial impact.
        Returns detailed breakdown with explainable assumptions.
        """
        vol = max(0.5, float(volume_m3))
        dist = max(1.0, float(total_distance_km))
        rate_per_m3 = cls.get_material_rate(concrete_grade)

        # 1. Base Costs
        material_value = round(vol * rate_per_m3, 2)
        transport_cost = round(dist * cls.TRANSPORT_RATE_PER_KM, 2)
        pumping_cost = round(vol * cls.PUMPING_RATE_PER_M3, 2)
        nominal_delivered_cost = round(material_value + transport_cost + pumping_cost, 2)

        # 2. Delay costs
        excess_transit = max(0.0, actual_transit_minutes - sla_minutes)
        delay_cost = round(excess_transit * cls.DELAY_COST_PER_MINUTE, 2)

        # 3. Disposal & Replacement liability under rejection
        disposal_cost = round(vol * cls.DISPOSAL_COST_PER_M3, 2)
        # Contractual replacement requires remanufacturing batch + replacement haul
        replacement_cost = round(material_value + transport_cost, 2)
        potential_total_loss = round(
            material_value + transport_cost + disposal_cost + replacement_cost + delay_cost,
            2
        )

        # 4. Intervention economics
        intervention_cost = 0.0
        if has_intervention:
            intervention_cost = round(
                cls.RETARDER_INTERVENTION_BASE_INR + (extra_reroute_km * cls.TRANSPORT_RATE_PER_KM),
                2
            )

        norm_outcome = outcome.strip().lower()
        if norm_outcome == "rejected":
            financial_type = "MATERIAL_LOSS"
            financial_impact_inr = potential_total_loss
            avoided_loss_inr = 0.0
            net_savings_inr = 0.0
        elif norm_outcome == "accepted_with_warning":
            financial_type = "NOMINAL_COST"
            # Site testing & minor remediation
            remediation_cost = round(3500.0 + delay_cost, 2)
            financial_impact_inr = remediation_cost
            avoided_loss_inr = round(potential_total_loss - remediation_cost, 2)
            net_savings_inr = avoided_loss_inr
        else:
            # Accepted delivery
            if has_intervention or composite_risk > 50.0:
                financial_type = "AVOIDED_LOSS"
                # Prevented full rejection through timely action
                avoided_loss_inr = round(potential_total_loss - intervention_cost, 2)
                financial_impact_inr = avoided_loss_inr
                net_savings_inr = round(avoided_loss_inr - intervention_cost, 2)
            else:
                financial_type = "NOMINAL_DELIVERY"
                financial_impact_inr = 0.0
                avoided_loss_inr = 0.0
                net_savings_inr = 0.0

        # Estimated pre-dispatch loss exposure based on composite risk
        loss_exposure_inr = round(potential_total_loss * (min(100.0, max(0.0, composite_risk)) / 100.0), 2)

        return {
            "volume_m3": vol,
            "concrete_grade": concrete_grade,
            "material_rate_per_m3": rate_per_m3,
            "material_value_inr": material_value,
            "transport_cost_inr": transport_cost,
            "pumping_cost_inr": pumping_cost,
            "nominal_delivered_cost_inr": nominal_delivered_cost,
            "delay_cost_inr": delay_cost,
            "disposal_cost_inr": disposal_cost,
            "replacement_cost_inr": replacement_cost,
            "potential_total_loss_inr": potential_total_loss,
            "intervention_cost_inr": intervention_cost,
            "financial_type": financial_type,
            "financial_impact_inr": financial_impact_inr,
            "avoided_loss_inr": avoided_loss_inr,
            "net_savings_inr": net_savings_inr,
            "estimated_loss_exposure_inr": loss_exposure_inr,
            "currency": "INR",
            "assumptions_used": f"Rate: ₹{rate_per_m3:,.0f}/m³ ({concrete_grade}), Transport: ₹{cls.TRANSPORT_RATE_PER_KM}/km, Disposal: ₹{cls.DISPOSAL_COST_PER_M3}/m³"
        }
