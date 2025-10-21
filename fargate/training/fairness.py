"""
Fairness and bias detection utilities
"""

import numpy as np
import pandas as pd
from typing import Dict


def calculate_fairness_metrics(
    y_true: np.ndarray,
    y_pred: np.ndarray,
    protected_features: pd.DataFrame,
    task_type: str = 'regression'
) -> Dict:
    """
    Calculate fairness metrics across protected groups
    
    Metrics:
    - Demographic Parity: P(y_pred=1|group=A) ≈ P(y_pred=1|group=B)
    - 80% Rule: Min/Max of group positive rates should be >= 0.8
    - Mean Absolute Difference: |E[y_pred|group=A] - E[y_pred|group=B]|
    """
    
    if 'gender' not in protected_features.columns:
        return {}
    
    gender = protected_features['gender'].values
    unique_genders = [g for g in ['M', 'F'] if g in gender]
    
    if len(unique_genders) < 2:
        return {}
    
    metrics = {}
    
    if task_type == 'classification':
        # Demographic Parity & 80% Rule
        positive_rates = {}
        for g in unique_genders:
            mask = gender == g
            if mask.sum() > 0:
                positive_rates[g] = (y_pred[mask] == 1).mean()
        
        if len(positive_rates) >= 2:
            min_rate = min(positive_rates.values())
            max_rate = max(positive_rates.values())
            metrics['80_percent_rule'] = min_rate / max_rate if max_rate > 0 else 0
            metrics['demographic_parity_diff'] = abs(
                positive_rates[unique_genders[0]] - positive_rates[unique_genders[1]]
            )
    
    else:  # regression
        # Mean Absolute Difference
        mean_predictions = {}
        for g in unique_genders:
            mask = gender == g
            if mask.sum() > 0:
                mean_predictions[g] = y_pred[mask].mean()
        
        if len(mean_predictions) >= 2:
            metrics['mean_prediction_diff'] = abs(
                mean_predictions[unique_genders[0]] - mean_predictions[unique_genders[1]]
            )
            
            # Parity ratio
            min_pred = min(mean_predictions.values())
            max_pred = max(mean_predictions.values())
            metrics['parity_ratio'] = min_pred / max_pred if max_pred > 0 else 0
    
    return metrics

