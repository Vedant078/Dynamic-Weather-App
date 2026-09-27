from fastapi import APIRouter
from typing import Dict, Any
from app.simulation.deterministic_scenario import simulator


router = APIRouter(prefix="/rmc/simulation", tags=["Demo Simulation"])


@router.get("/state")
def get_simulation_state() -> Dict[str, Any]:
    """Returns the current step and scenario telemetry for demo progression."""
    return {
        "current_step": simulator.current_step_idx,
        "total_steps": len(simulator.STEPS),
        "step_data": simulator.get_current_step()
    }


@router.post("/step/{step_idx}")
def jump_to_step(step_idx: int) -> Dict[str, Any]:
    """Jumps to a specific step in the deterministic scenario."""
    return simulator.set_step(step_idx)


@router.post("/next")
def advance_simulation_step() -> Dict[str, Any]:
    """Advances to the next step in the deterministic scenario."""
    return simulator.next_step()


@router.post("/reset")
def reset_simulation() -> Dict[str, Any]:
    """Resets the simulation to nominal initial transit state (Step 0)."""
    return simulator.reset()
