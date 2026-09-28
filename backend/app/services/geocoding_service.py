"""
MAUSAM Geocoding Service
Converts physical address/name to latitude & longitude using OpenStreetMap Nominatim.
Never fabricates or falls back to fixed coordinates.
"""

import logging
from typing import Optional, Dict, Any
import httpx

logger = logging.getLogger("geocoding_service")


class GeocodingService:
    NOMINATIM_URL = "https://nominatim.openstreetmap.org/search"
    USER_AGENT = "Mausam-RMC-Engine/1.0"

    @classmethod
    def geocode(cls, address: str) -> Optional[Dict[str, Any]]:
        """
        Geocodes an address string to latitude, longitude, and formatted name.
        Returns None if not found or on error.
        """
        if not address or len(address.strip()) < 2:
            return None

        clean_addr = address.strip()
        params = {
            "q": clean_addr,
            "format": "json",
            "limit": 1,
            "addressdetails": 1
        }
        headers = {
            "User-Agent": cls.USER_AGENT
        }

        try:
            with httpx.Client(timeout=4.0) as client:
                resp = client.get(cls.NOMINATIM_URL, params=params, headers=headers)
                if resp.status_code == 200:
                    data = resp.json()
                    if isinstance(data, list) and len(data) > 0:
                        first = data[0]
                        return {
                            "latitude": float(first["lat"]),
                            "longitude": float(first["lon"]),
                            "display_name": first.get("display_name", clean_addr)
                        }
        except Exception as e:
            logger.warning(f"Geocoding request failed for '{clean_addr}': {e}")

        return None
