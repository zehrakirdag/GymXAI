import sys
import json
import joblib
import pandas as pd
import os

MODEL_PATH = os.path.join(
    os.path.dirname(__file__),
    "ai_program_model.pkl"
)

# -------------------------------------------------
# 1) INPUT ALMA
# -------------------------------------------------

test_data = {
    "age": 30,
    "gender": 0,
    "bmi": 32,
    "goal": "WEIGHT_LOSS",
    "activityLevel": "LOW",
    "hasHealthIssue": 0,
    "hasInjury": 0,
    "weightChange": 1.5,
    "targetWeightDiff": -12,
    "programProgress": 25,
}

try:
    if len(sys.argv) > 1:
        data = json.loads(sys.argv[1])
    else:
        data = test_data
except Exception as e:
    print(
        json.dumps(
            {
                "error": "JSON input okunamadı",
                "detail": str(e),
                "rawInput": sys.argv[1] if len(sys.argv) > 1 else None,
            },
            ensure_ascii=False,
        )
    )
    sys.exit(1)

# -------------------------------------------------
# 2) MODEL YÜKLEME
# -------------------------------------------------

try:
    saved = joblib.load(MODEL_PATH)

    model = saved["model"]
    goal_encoder = saved["goal_encoder"]
    activity_encoder = saved["activity_encoder"]
    target_encoder = saved["target_encoder"]
    feature_columns = saved["feature_columns"]

except Exception as e:
    print(
        json.dumps(
            {
                "error": "Model yüklenemedi",
                "detail": str(e),
            },
            ensure_ascii=False,
        )
    )
    sys.exit(1)

# -------------------------------------------------
# 3) GÜVENLİ DEĞER DÖNÜŞÜMLERİ
# -------------------------------------------------

goal = data.get("goal", "GENERAL_FITNESS")
activity_level = data.get("activityLevel", "MEDIUM")

if goal not in goal_encoder.classes_:
    goal = "GENERAL_FITNESS"

if activity_level not in activity_encoder.classes_:
    activity_level = "MEDIUM"

input_df = pd.DataFrame(
    [
        {
            "age": data.get("age", 25),
            "gender": data.get("gender", 0),
            "bmi": data.get("bmi", 25),
            "goal": goal_encoder.transform([goal])[0],
            "activityLevel": activity_encoder.transform([activity_level])[0],
            "hasHealthIssue": data.get("hasHealthIssue", 0),
            "hasInjury": data.get("hasInjury", 0),
            "weightChange": data.get("weightChange", 0),
            "targetWeightDiff": data.get("targetWeightDiff", 0),
            "programProgress": data.get("programProgress", 0),
        }
    ]
)

input_df = input_df[feature_columns]

# -------------------------------------------------
# 4) TAHMİN
# -------------------------------------------------

try:
    prediction = model.predict(input_df)[0]
    probabilities = model.predict_proba(input_df)[0]

    program_type = target_encoder.inverse_transform([prediction])[0]
    confidence = float(max(probabilities))

    print(
        json.dumps(
            {
                "programType": program_type,
                "confidence": round(confidence, 4),
            },
            ensure_ascii=False,
        )
    )

except Exception as e:
    print(
        json.dumps(
            {
                "error": "Tahmin yapılamadı",
                "detail": str(e),
            },
            ensure_ascii=False,
        )
    )
    sys.exit(1)