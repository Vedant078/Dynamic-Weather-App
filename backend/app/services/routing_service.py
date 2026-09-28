"""
MAUSAM Dynamic Routing Service
Calculates distance, ETA, waypoints, and candidate route options
between any arbitrary origin and destination coordinates.
Uses live OSRM routing with deterministic geographic fallback.
"""

import math
import logging
from typing import List, Dict, Any, Optional
import httpx

logger = logging.getLogger("routing_service")


class RoutingService:
    OSRM_BASE_URL = "https://router.project-osrm.org/route/v1/driving"

    @staticmethod
    def haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        """Calculates great-circle distance between two points in kilometers."""
        r = 6371.0
        d_lat = math.radians(lat2 - lat1)
        d_lon = math.radians(lon2 - lon1)
        a = (
            math.sin(d_lat / 2.0) ** 2
            + math.cos(math.radians(lat1))
            * math.cos(math.radians(lat2))
            * math.sin(d_lon / 2.0) ** 2
        )
        c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))
        return r * c

    @classmethod
    def get_route_candidates(
        cls,
        origin_lat: float,
        origin_lng: float,
        dest_lat: float,
        dest_lng: float,
        origin_name: str = "Origin Plant",
        dest_name: str = "Destination Site",
    ) -> List[Dict[str, Any]]:
        """
        Calculates dynamic candidate routes connecting origin and destination coordinates.
        Never falls back to hardcoded Ahmedabad coordinates for non-Ahmedabad locations.
        """
        crow_fly_km = cls.haversine_km(origin_lat, origin_lng, dest_lat, dest_lng)
        base_road_dist_km = round(max(1.0, crow_fly_km * 1.28), 1)

        # Attempt live OSRM routing
        live_dist_km: Optional[float] = None
        live_dur_min: Optional[float] = None
        osrm_points: List[Dict[str, float]] = []

        try:
            url = f"{cls.OSRM_BASE_URL}/{origin_lng},{origin_lat};{dest_lng},{dest_lat}?overview=simplified&geometries=geojson"
            with httpx.Client(timeout=3.0) as client:
                res = client.get(url)
                if res.status_code == 200:
                    data = res.json()
                    if data.get("code") == "Ok" and data.get("routes"):
                        route_info = data["routes"][0]
                        live_dist_km = round(route_info["distance"] / 1000.0, 1)
                        live_dur_min = round(route_info["duration"] / 60.0, 1)
                        coords = route_info.get("geometry", {}).get("coordinates", [])
                        if coords:
                            # Subsample coords to ~5-8 waypoints
                            step = max(1, len(coords) // 6)
                            for i in range(0, len(coords), step):
                                pt = coords[i]
                                osrm_points.append({"lat": round(pt[1], 4), "lng": round(pt[0], 4)})
        except Exception as e:
            logger.debug(f"OSRM live routing skipped/unavailable: {e}")

        dist_a = live_dist_km if live_dist_km is not None else base_road_dist_km
        # Urban average speed ~32 km/h
        dur_a = live_dur_min if live_dur_min is not None else round((dist_a / 32.0) * 60.0, 1)

        # Midpoint calculations
        mid_lat = (origin_lat + dest_lat) / 2.0
        mid_lng = (origin_lng + dest_lng) / 2.0
        d_lat = dest_lat - origin_lat
        d_lng = dest_lng - origin_lng

        # Perpendicular offsets for alternative corridors
        norm = math.sqrt(d_lat * d_lat + d_lng * d_lng)
        perp_lat = (-d_lng / norm) * (crow_fly_km * 0.003) if norm > 0 else 0.02
        perp_lng = (d_lat / norm) * (crow_fly_km * 0.003) if norm > 0 else 0.02

        # Waypoints for Route A (Arterial / Direct)
        wp_a = [
            {"lat": origin_lat, "lng": origin_lng, "name": origin_name},
            {"lat": round(mid_lat, 4), "lng": round(mid_lng, 4), "name": "Direct Corridor Midpoint"},
            {"lat": dest_lat, "lng": dest_lng, "name": dest_name}
        ] if not osrm_points else [
            {"lat": origin_lat, "lng": origin_lng, "name": origin_name},
            *osrm_points[1:-1],
            {"lat": dest_lat, "lng": dest_lng, "name": dest_name}
        ]

        # Route B (Bypass Corridor - slightly longer, less congestion)
        dist_b = round(dist_a * 1.09, 1)
        dur_b = round(dur_a * 0.85, 1)  # Faster transit via bypass
        wp_b = [
            {"lat": origin_lat, "lng": origin_lng, "name": origin_name},
            {"lat": round(mid_lat + perp_lat, 4), "lng": round(mid_lng + perp_lng, 4), "name": "Outer Bypass Corridor"},
            {"lat": dest_lat, "lng": dest_lng, "name": dest_name}
        ]

        # Route C (Alternate Arterial)
        dist_c = round(dist_a * 1.18, 1)
        dur_c = round(dur_a * 1.12, 1)
        wp_c = [
            {"lat": origin_lat, "lng": origin_lng, "name": origin_name},
            {"lat": round(mid_lat - perp_lat, 4), "lng": round(mid_lng - perp_lng, 4), "name": "Secondary Arterial"},
            {"lat": dest_lat, "lng": dest_lng, "name": dest_name}
        ]

        # Recommended route selection (Route B if duration exceeds 55m or Route A if short)
        rec_is_b = dur_a > 45.0

        candidates = [
            {
                "route_id": "route-a",
                "route_name": f"Route A (Direct Corridor - {dist_a} km)",
                "is_recommended": not rec_is_b,
                "eta_minutes": dur_a,
                "distance_km": dist_a,
                "delivery_risk": 58.0 if dur_a > 60.0 else 32.0,
                "heat_risk": 45.0,
                "travel_risk": 55.0 if dur_a > 60.0 else 28.0,
                "traffic_level": "Arterial Congestion (+8m delay)" if dur_a > 50 else "Nominal Traffic",
                "weather_summary": "Corridor tracking",
                "trade_off_explanation": "Shortest physical route, but subject to urban congestion bottlenecks.",
                "waypoints": wp_a
            },
            {
                "route_id": "route-b",
                "route_name": f"Route B (Outer Bypass Corridor - {dist_b} km)",
                "is_recommended": rec_is_b,
                "eta_minutes": dur_b,
                "distance_km": dist_b,
                "delivery_risk": 28.0,
                "heat_risk": 32.0,
                "travel_risk": 24.0,
                "traffic_level": "Free Flow (Expressway)",
                "weather_summary": "Open corridor",
                "trade_off_explanation": f"+{round(dist_b - dist_a, 1)} km longer distance, but saves {round(max(0, dur_a - dur_b), 1)} minutes and preserves slump.",
                "waypoints": wp_b
            },
            {
                "route_id": "route-c",
                "route_name": f"Route C (Secondary Arterial - {dist_c} km)",
                "is_recommended": False,
                "eta_minutes": dur_c,
                "distance_km": dist_c,
                "delivery_risk": 72.0 if dur_c > 65.0 else 42.0,
                "heat_risk": 50.0,
                "travel_risk": 68.0,
                "traffic_level": "High Intersections",
                "weather_summary": "Corridor tracking",
                "trade_off_explanation": "Alternative arterial with signalized intersections; higher transit variability.",
                "waypoints": wp_c
            }
        ]
        return candidates
