from typing import Dict, Any, List


class CanonicalWeatherService:
    """
    Deterministic Canonical Weather Service for the MAUSAM platform.
    (PRD.md Section 3 & Prompt Section 4, 5, 6)
    
    Guarantees:
    - Same location + same time ALWAYS yields identical weather telemetry across all endpoints and UI screens.
    - Accurately computes delivery window environmental exposure.
    """

    @staticmethod
    def get_weather(location: str = "Ahmedabad Central Corridor", time_of_day: str = "14:00") -> Dict[str, Any]:
        norm_loc = location.lower().strip()
        parts = time_of_day.split(":")
        try:
            h = int(parts[0])
            m = int(parts[1]) if len(parts) > 1 else 0
        except (ValueError, IndexError):
            h, m = 14, 0
        time_val = h + m / 60.0

        base_temp = 35.0
        diurnal_offset = 0.0
        solar_offset = 0.0
        humidity = 50.0
        precip = 15.0
        wind_speed = 14.0
        condition = "Partly Cloudy"

        if 11.5 <= time_val <= 16.5:
            # Peak Solar Midday
            diurnal_offset = 3.5
            solar_offset = 2.5
            humidity = 42.0
            wind_speed = 16.0
            condition = "High Solar Heat"
        elif 9.5 <= time_val < 11.5:
            # Heat Onset
            diurnal_offset = 1.0
            solar_offset = 1.0
            humidity = 50.0
            wind_speed = 13.0
            condition = "Clear / Warming"
        elif 16.5 < time_val <= 18.5:
            # Late Afternoon / Early Evening
            diurnal_offset = 0.5
            solar_offset = 0.0
            humidity = 52.0
            wind_speed = 14.0
            condition = "Warm / Hazy Sun"
        elif 6.0 <= time_val < 9.5:
            # Morning Cool Window
            diurnal_offset = -4.5
            solar_offset = -1.5
            humidity = 65.0
            wind_speed = 10.0
            condition = "Cool Morning"
        else:
            # Night Window
            diurnal_offset = -6.0
            solar_offset = -3.5
            humidity = 70.0
            wind_speed = 8.0
            condition = "Clear Night"

        if "route a" in norm_loc or "ring road" in norm_loc or "nana chiloda" in norm_loc:
            base_temp = 35.0
            precip = 68.0 if (13.0 <= time_val <= 17.0) else 25.0
            if precip >= 50.0:
                condition = "Rain Cell Ahead"
        elif "route b" in norm_loc or "airport" in norm_loc or "bypass" in norm_loc:
            base_temp = 34.5
            precip = 12.0
            wind_speed += 2.0
            if condition == "High Solar Heat":
                condition = "Dry Expressway Corridor"
        elif "gift city" in norm_loc or "tower b" in norm_loc:
            base_temp = 34.8
            precip = 18.0
        elif "plant" in norm_loc or "naroda" in norm_loc:
            base_temp = 35.0
            precip = 15.0

        final_ambient = round(base_temp + diurnal_offset, 1)
        final_apparent = round(final_ambient + (solar_offset if solar_offset > 0 else 1.5), 1)

        return {
            "location_name": location if location else "Ahmedabad Central Corridor",
            "time_of_day": time_of_day,
            "ambient_temp_c": final_ambient,
            "apparent_temp_c": final_apparent,
            "humidity_pct": round(humidity, 1),
            "wind_speed_kmh": round(wind_speed, 1),
            "wind_direction": "SW",
            "precipitation_probability_pct": round(precip, 1),
            "weather_condition": condition,
            "solar_exposure_offset_c": solar_offset,
            "uv_index": 8.5 if (11.0 <= time_val <= 15.0) else 4.5,
            "air_quality_index": 98,
            "freshness": "LIVE · Canonical Sensor Network"
        }

    @classmethod
    def get_delivery_window_weather(cls, location: str, dispatch_time: str, transit_minutes: float) -> Dict[str, Any]:
        parts = dispatch_time.split(":")
        try:
            start_hour = int(parts[0])
            start_min = int(parts[1]) if len(parts) > 1 else 0
        except (ValueError, IndexError):
            start_hour, start_min = 14, 0
        total_start_min = start_hour * 60 + start_min

        samples = 5
        step = transit_minutes / samples
        temps, offsets, hums, precips = [], [], [], []

        for i in range(samples + 1):
            cur_min = int(total_start_min + i * step) % (24 * 60)
            h = cur_min // 60
            m = cur_min % 60
            sample = cls.get_weather(location, f"{h:02d}:{m:02d}")
            temps.append(sample["ambient_temp_c"])
            offsets.append(sample["solar_exposure_offset_c"])
            hums.append(sample["humidity_pct"])
            precips.append(sample["precipitation_probability_pct"])

        avg_temp = round(sum(temps) / len(temps), 1)
        avg_offset = round(sum(offsets) / len(offsets), 1)
        avg_humidity = round(sum(hums) / len(hums), 1)
        avg_precip = round(sum(precips) / len(precips), 1)

        base = cls.get_weather(location, dispatch_time)
        condition = base["weather_condition"]
        if avg_precip >= 50.0:
            condition = "Rain Front Active Across Route"
        elif avg_temp + avg_offset >= 38.0:
            condition = "Extreme Solar Heat / Rapid Hydration"

        arrival_total = total_start_min + int(transit_minutes)
        arr_h = (arrival_total // 60) % 24
        arr_m = arrival_total % 60

        return {
            "location_name": location,
            "time_of_day": dispatch_time,
            "ambient_temp_c": avg_temp,
            "apparent_temp_c": round(avg_temp + 2.5, 1),
            "humidity_pct": avg_humidity,
            "wind_speed_kmh": base["wind_speed_kmh"],
            "wind_direction": base["wind_direction"],
            "precipitation_probability_pct": avg_precip,
            "weather_condition": condition,
            "solar_exposure_offset_c": avg_offset,
            "uv_index": base["uv_index"],
            "air_quality_index": base["air_quality_index"],
            "freshness": f"INTEGRATED · Delivery Window {dispatch_time}–{arr_h:02d}:{arr_m:02d}"
        }


canonical_weather_service = CanonicalWeatherService()
