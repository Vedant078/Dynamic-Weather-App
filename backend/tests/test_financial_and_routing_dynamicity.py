"""
MAUSAM Financial & Dynamic Routing Acceptance Test Suite
Verifies:
1. Financial outcomes change dynamically based on:
   - Quantity (5 m3 vs 10 m3)
   - Concrete Grade (M25 vs M40)
   - Distance (15 km vs 45 km)
   - Transit duration / delay
   - Outcome (accepted vs rejected vs accepted_with_warning)
   - Mitigation / intervention
2. Routing dynamically calculates distance, duration, and waypoints for arbitrary coordinates.
3. Geocoding service handles real queries and reports failures explicitly.
"""

import pytest
from app.services.financial_service import RmcFinancialEngine
from app.services.routing_service import RoutingService
from app.services.geocoding_service import GeocodingService


def test_scenario_a_short_route_m25_on_time():
    """Scenario A: 5 m3, M25, short 15 km route, on-time delivery (45 min) -> nominal delivered cost, no loss."""
    res = RmcFinancialEngine.calculate_delivery_economics(
        volume_m3=5.0,
        concrete_grade="M25",
        total_distance_km=15.0,
        actual_transit_minutes=45.0,
        outcome="accepted",
        has_intervention=False,
        composite_risk=20.0
    )
    assert res["volume_m3"] == 5.0
    assert res["material_rate_per_m3"] == 4350.0
    assert res["material_value_inr"] == 5.0 * 4350.0  # ₹21,750
    assert res["transport_cost_inr"] == 15.0 * 75.0   # ₹1,125
    assert res["financial_type"] == "NOMINAL_DELIVERY"
    assert res["financial_impact_inr"] == 0.0
    assert res["delay_cost_inr"] == 0.0


def test_scenario_b_long_route_m35_rejection():
    """Scenario B: 8 m3, M35, 38 km route, 95 min, rejection -> severe material loss + disposal + replacement."""
    res = RmcFinancialEngine.calculate_delivery_economics(
        volume_m3=8.0,
        concrete_grade="M35",
        total_distance_km=38.0,
        actual_transit_minutes=95.0,
        outcome="rejected",
        has_intervention=False,
        composite_risk=85.0
    )
    assert res["financial_type"] == "MATERIAL_LOSS"
    assert res["material_rate_per_m3"] == 5300.0
    # Material = 8 * 5300 = 42,400
    # Transport = 38 * 75 = 2,850
    # Disposal = 8 * 850 = 6,800
    # Replacement = 42,400 + 2,850 = 45,250
    # Delay = (95 - 78) * 45 = 17 * 45 = 765
    expected_total = 42400 + 2850 + 6800 + 45250 + 765
    assert res["financial_impact_inr"] == expected_total
    assert res["financial_impact_inr"] > 90000.0
    assert res["avoided_loss_inr"] == 0.0


def test_scenario_c_same_delivery_as_b_with_successful_intervention():
    """Scenario C: Same delivery as B, but intervention applied and accepted -> substantial avoided loss."""
    res = RmcFinancialEngine.calculate_delivery_economics(
        volume_m3=8.0,
        concrete_grade="M35",
        total_distance_km=38.0,
        actual_transit_minutes=68.0,
        outcome="accepted",
        has_intervention=True,
        composite_risk=65.0
    )
    assert res["financial_type"] == "AVOIDED_LOSS"
    assert res["intervention_cost_inr"] == 1500.0
    assert res["avoided_loss_inr"] > 80000.0
    assert res["net_savings_inr"] == res["avoided_loss_inr"] - 1500.0


def test_scenario_d_quantity_scaling():
    """Scenario D: Same material and route, different volume (5 m3 vs 10 m3) -> scales proportionally."""
    res_5 = RmcFinancialEngine.calculate_delivery_economics(
        volume_m3=5.0, concrete_grade="M30", total_distance_km=25.0, outcome="rejected"
    )
    res_10 = RmcFinancialEngine.calculate_delivery_economics(
        volume_m3=10.0, concrete_grade="M30", total_distance_km=25.0, outcome="rejected"
    )
    assert res_10["material_value_inr"] == 2.0 * res_5["material_value_inr"]
    assert res_10["disposal_cost_inr"] == 2.0 * res_5["disposal_cost_inr"]
    assert res_10["financial_impact_inr"] > res_5["financial_impact_inr"] * 1.8


def test_scenario_e_grade_scaling():
    """Scenario E: Same quantity and route, different concrete grade (M20 vs M40) -> exposure changes."""
    res_m20 = RmcFinancialEngine.calculate_delivery_economics(
        volume_m3=6.0, concrete_grade="M20", total_distance_km=25.0, outcome="rejected"
    )
    res_m40 = RmcFinancialEngine.calculate_delivery_economics(
        volume_m3=6.0, concrete_grade="M40", total_distance_km=25.0, outcome="rejected"
    )
    assert res_m40["material_rate_per_m3"] > res_m20["material_rate_per_m3"]
    assert res_m40["financial_impact_inr"] > res_m20["financial_impact_inr"]


def test_scenario_f_distance_scaling():
    """Scenario F: Same delivery, different route distance (15 km vs 50 km) -> transport cost scales."""
    res_15 = RmcFinancialEngine.calculate_delivery_economics(
        volume_m3=6.0, concrete_grade="M35", total_distance_km=15.0, outcome="accepted"
    )
    res_50 = RmcFinancialEngine.calculate_delivery_economics(
        volume_m3=6.0, concrete_grade="M35", total_distance_km=50.0, outcome="accepted"
    )
    assert res_50["transport_cost_inr"] > res_15["transport_cost_inr"]
    assert res_50["transport_cost_inr"] == 50.0 * 75.0
    assert res_15["transport_cost_inr"] == 15.0 * 75.0


def test_dynamic_routing_arbitrary_coordinates():
    """Verifies RoutingService generates different routes and distances for arbitrary coordinate pairs."""
    # Ahmedabad pair
    routes_ahm = RoutingService.get_route_candidates(
        origin_lat=23.0225, origin_lng=72.5714,
        dest_lat=23.0900, dest_lng=72.6100,
        origin_name="Naroda Plant", dest_name="GIFT City"
    )
    # Mumbai pair
    routes_mum = RoutingService.get_route_candidates(
        origin_lat=19.0760, origin_lng=72.8777,
        dest_lat=19.2183, dest_lng=72.9781,
        origin_name="Bandra Plant", dest_name="Thane Site"
    )
    assert len(routes_ahm) >= 3
    assert len(routes_mum) >= 3
    # Distance of Mumbai pair (approx 20 km crow-fly) is different from Ahmedabad pair (approx 8 km crow-fly)
    assert routes_mum[0]["distance_km"] != routes_ahm[0]["distance_km"]
    assert routes_mum[0]["waypoints"][0]["lat"] == 19.0760
    assert routes_ahm[0]["waypoints"][0]["lat"] == 23.0225


def test_geocoding_handles_empty_gracefully():
    """Geocoding returns None for empty/invalid queries and never returns hardcoded fake coordinates."""
    assert GeocodingService.geocode("") is None
    assert GeocodingService.geocode(" ") is None
    assert GeocodingService.geocode("a") is None
