"""
TDEE (Total Daily Energy Expenditure) Calculator
Using Mifflin-St Jeor equation for BMR calculation
"""

from datetime import datetime
from typing import Optional

class TDEECalculator:
    """Calculate TDEE and macros based on user metrics"""
    
    # Activity level multipliers
    ACTIVITY_MULTIPLIERS = {
        "sedentary": 1.2,           # Little or no exercise
        "lightly_active": 1.375,    # 1-3 days/week
        "moderate": 1.55,            # 3-5 days/week
        "very_active": 1.725,        # 6-7 days/week
        "extra_active": 1.9,         # Physical job or training twice per day
    }
    
    @staticmethod
    def calculate_bmr(
        weight_kg: float,
        height_cm: float,
        age: int,
        sex: str  # 'M' or 'F'
    ) -> float:
        """
        Calculate Basal Metabolic Rate using Mifflin-St Jeor equation
        Returns: BMR in kcal/day
        """
        if sex.upper() == 'M':
            bmr = (10 * weight_kg) + (6.25 * height_cm) - (5 * age) + 5
        else:  # Female
            bmr = (10 * weight_kg) + (6.25 * height_cm) - (5 * age) - 161
        
        return max(bmr, 0)  # Ensure non-negative
    
    @staticmethod
    def calculate_tdee(
        weight_kg: float,
        height_cm: float,
        age: int,
        sex: str,
        activity_level: str = "moderate"
    ) -> float:
        """
        Calculate Total Daily Energy Expenditure
        Returns: TDEE in kcal/day
        """
        bmr = TDEECalculator.calculate_bmr(weight_kg, height_cm, age, sex)
        multiplier = TDEECalculator.ACTIVITY_MULTIPLIERS.get(activity_level, 1.55)
        tdee = bmr * multiplier
        
        return round(tdee, 1)
    
    @staticmethod
    def calculate_age(date_of_birth: datetime) -> int:
        """Calculate age from date of birth"""
        today = datetime.utcnow().date()
        born = date_of_birth.date()
        age = today.year - born.year - ((today.month, today.day) < (born.month, born.day))
        return age
    
    @staticmethod
    def calculate_calorie_deficit(
        tdee: float,
        goal_timeline_weeks: int,
        preferred_pace: str = "steady"
    ) -> float:
        """
        Calculate daily calorie deficit target
        
        Pace options:
        - slow: 0.25 kg/week = 875 kcal/day deficit
        - steady: 0.5 kg/week = 1750 kcal/day deficit = 875 daily
        - aggressive: 1 kg/week = 1750 kcal/day deficit = 875 daily
        """
        # 1 kg fat = ~7700 kcal
        pace_deficits = {
            "slow": 875,           # 0.25 kg/week
            "steady": 875,         # 0.5 kg/week (split 875/day = ~1.75/week)
            "aggressive": 1000,    # But capped at 1000 for safety
        }
        
        daily_deficit = pace_deficits.get(preferred_pace, 875)
        
        # Minimum calorie to maintain health
        min_calories = 1200 if 'F' else 1500
        calorie_target = max(tdee - daily_deficit, min_calories)
        
        return round(calorie_target, 0)
    
    @staticmethod
    def calculate_macros(
        calorie_target: float,
        macro_type: str = "balanced"
    ) -> dict:
        """
        Calculate macro targets based on calorie goal
        
        Returns: dict with protein_g, carbs_g, fat_g
        """
        if macro_type == "high_protein":
            protein_ratio = 0.35
            carbs_ratio = 0.35
            fat_ratio = 0.30
        elif macro_type == "low_carb":
            protein_ratio = 0.35
            carbs_ratio = 0.20
            fat_ratio = 0.45
        elif macro_type == "balanced":
            protein_ratio = 0.30
            carbs_ratio = 0.40
            fat_ratio = 0.30
        else:  # custom or unknown
            protein_ratio = 0.30
            carbs_ratio = 0.40
            fat_ratio = 0.30
        
        # 1g protein = 4 kcal, 1g carbs = 4 kcal, 1g fat = 9 kcal
        protein_g = (calorie_target * protein_ratio) / 4
        carbs_g = (calorie_target * carbs_ratio) / 4
        fat_g = (calorie_target * fat_ratio) / 9
        
        return {
            "protein_g": round(protein_g, 1),
            "carbs_g": round(carbs_g, 1),
            "fat_g": round(fat_g, 1),
        }

class WeightLossCalculator:
    """Calculate weight loss progress and projections"""
    
    @staticmethod
    def calculate_weight_loss_progress(
        current_weight: float,
        goal_weight: float,
        starting_weight: Optional[float] = None
    ) -> dict:
        """Calculate progress metrics"""
        if starting_weight is None:
            starting_weight = current_weight
        
        total_to_lose = starting_weight - goal_weight
        already_lost = starting_weight - current_weight
        remaining = current_weight - goal_weight
        
        if total_to_lose > 0:
            progress_percent = (already_lost / total_to_lose) * 100
        else:
            progress_percent = 0
        
        return {
            "total_to_lose": round(total_to_lose, 1),
            "already_lost": round(already_lost, 1),
            "remaining": round(remaining, 1),
            "progress_percent": round(progress_percent, 1),
        }
    
    @staticmethod
    def detect_plateau(
        weight_entries: list,
        plateau_days: int = 21
    ) -> bool:
        """
        Detect if user is in a weight loss plateau
        (no significant weight change in X days)
        """
        if len(weight_entries) < plateau_days:
            return False
        
        recent = weight_entries[-plateau_days:]
        first_weight = recent[0].weight_kg
        last_weight = recent[-1].weight_kg
        
        # Plateau if change is less than 0.5 kg
        weight_change = abs(first_weight - last_weight)
        return weight_change < 0.5
