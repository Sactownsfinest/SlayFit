"""
AI Coach proxy endpoint — forwards chat requests to Anthropic, keeping the API key server-side.
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Any
import httpx

from app.core.config import settings

router = APIRouter()

_ANTHROPIC_URL = "https://api.anthropic.com/v1/messages"
_MODEL = "claude-haiku-4-5-20251001"


class ChatMessage(BaseModel):
    role: str
    content: str


class CoachChatRequest(BaseModel):
    history: list[ChatMessage] = []
    user_message: str
    context: dict[str, Any] = {}


class CoachChatResponse(BaseModel):
    reply: str


def _build_system_prompt(ctx: dict) -> str:
    calories = ctx.get("calories", 0)
    calorie_goal = ctx.get("calorieGoal", 2000)
    protein_g = ctx.get("proteinG", 0)
    carbs_g = ctx.get("carbsG", 0)
    fat_g = ctx.get("fatG", 0)
    water_ml = ctx.get("waterMl", 0)
    streak = ctx.get("streak", 0)
    name = ctx.get("name", "User")
    current_weight = ctx.get("currentWeight")
    goal_weight = ctx.get("goalWeight")

    if current_weight is not None:
        weight_info = (
            f"Current weight: {current_weight:.1f} kg. "
            f"Goal weight: {goal_weight:.1f} kg." if goal_weight else
            f"Current weight: {current_weight:.1f} kg."
        )
    else:
        weight_info = "No weight logged yet."

    return f"""You are Slay, a supportive and motivating AI fitness coach inside the SlayFit app.

User: {name}
Today's data:
- Calories: {calories} / {calorie_goal} kcal
- Protein: {protein_g}g | Carbs: {carbs_g}g | Fat: {fat_g}g
- Water: {water_ml}ml
- Current streak: {streak} days
- {weight_info}

Be concise (2-3 sentences max unless asked for more). Be warm, direct, and science-backed.
Use the user's actual data to give personalized advice. Never make up data you don't have."""


@router.post("/chat", response_model=CoachChatResponse)
async def coach_chat(req: CoachChatRequest):
    if not settings.ANTHROPIC_API_KEY:
        raise HTTPException(status_code=503, detail="AI Coach not configured")

    messages = [{"role": m.role, "content": m.content} for m in req.history]
    messages.append({"role": "user", "content": req.user_message})

    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.post(
            _ANTHROPIC_URL,
            headers={
                "x-api-key": settings.ANTHROPIC_API_KEY,
                "anthropic-version": "2023-06-01",
                "Content-Type": "application/json",
            },
            json={
                "model": _MODEL,
                "max_tokens": 512,
                "system": _build_system_prompt(req.context),
                "messages": messages,
            },
        )

    if resp.status_code == 401:
        raise HTTPException(status_code=502, detail="Invalid Anthropic API key")
    if resp.status_code != 200:
        raise HTTPException(status_code=502, detail=f"Upstream error {resp.status_code}")

    data = resp.json()
    reply = data["content"][0]["text"]
    return CoachChatResponse(reply=reply)
