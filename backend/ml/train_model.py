import pandas as pd
import numpy as np
import joblib

from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import (
    train_test_split,
    StratifiedKFold,
    cross_val_score,
)
from sklearn.metrics import (
    accuracy_score,
    classification_report,
    confusion_matrix,
)
from sklearn.preprocessing import LabelEncoder

print("Veri seti okunuyor...")

df = pd.read_csv("ai_dataset.csv")

# =====================================
# DATA AUGMENTATION + NOISE
# =====================================

np.random.seed(42)

augmented_rows = []

for _, row in df.iterrows():

    augmented_rows.append(row.to_dict())

    for i in range(8):

        new_row = row.copy()

        # Yaş varyasyonu
        new_row["age"] = max(
            18,
            min(
                75,
                row["age"] + np.random.randint(-4, 5),
            ),
        )

        # BMI varyasyonu
        new_row["bmi"] = round(
            row["bmi"] + np.random.uniform(-3.0, 3.0),
            1,
        )

        # Kilo değişimi varyasyonu
        new_row["weightChange"] = round(
            row["weightChange"] + np.random.uniform(-1.5, 1.5),
            1,
        )

        # Hedef kilo farkı varyasyonu
        new_row["targetWeightDiff"] = round(
            row["targetWeightDiff"] + np.random.uniform(-4, 4),
            1,
        )

        # Program ilerleme varyasyonu
        new_row["programProgress"] = max(
            0,
            min(
                100,
                row["programProgress"]
                + np.random.randint(-25, 26),
            ),
        )

        # %15 sağlık durumu değişimi
        if np.random.random() < 0.15:
            new_row["hasHealthIssue"] = (
                1 - row["hasHealthIssue"]
            )

        # %15 sakatlık değişimi
        if np.random.random() < 0.15:
            new_row["hasInjury"] = (
                1 - row["hasInjury"]
            )

        augmented_rows.append(new_row.to_dict())

df = pd.DataFrame(augmented_rows)

print("Toplam kayıt:", len(df))

# =====================================
# LABEL ENCODING
# =====================================

goal_encoder = LabelEncoder()
activity_encoder = LabelEncoder()
target_encoder = LabelEncoder()

df["goal"] = goal_encoder.fit_transform(
    df["goal"]
)

df["activityLevel"] = activity_encoder.fit_transform(
    df["activityLevel"]
)

df["programType"] = target_encoder.fit_transform(
    df["programType"]
)

# =====================================
# FEATURES
# =====================================

X = df[
    [
        "age",
        "gender",
        "bmi",
        "goal",
        "activityLevel",
        "hasHealthIssue",
        "hasInjury",
        "weightChange",
        "targetWeightDiff",
        "programProgress",
    ]
]

y = df["programType"]

# =====================================
# TRAIN TEST SPLIT
# =====================================

X_train, X_test, y_train, y_test = train_test_split(
    X,
    y,
    test_size=0.30,
    random_state=42,
    stratify=y,
)

# =====================================
# RANDOM FOREST
# =====================================

model = RandomForestClassifier(
    n_estimators=120,
    max_depth=5,
    min_samples_split=12,
    min_samples_leaf=6,
    max_features="sqrt",
    class_weight="balanced",
    random_state=42,
)

# =====================================
# CROSS VALIDATION
# =====================================

cv = StratifiedKFold(
    n_splits=5,
    shuffle=True,
    random_state=42,
)

cv_scores = cross_val_score(
    model,
    X,
    y,
    cv=cv,
    scoring="accuracy",
)

print()
print(
    "Cross Validation Accuracy Scores:",
    np.round(cv_scores * 100, 2),
)
print(
    "Ortalama CV Accuracy:",
    round(cv_scores.mean() * 100, 2),
    "%",
)
print()

# =====================================
# TRAIN
# =====================================

print("Model eğitiliyor...")

model.fit(X_train, y_train)

# =====================================
# TEST
# =====================================

predictions = model.predict(X_test)

accuracy = accuracy_score(
    y_test,
    predictions,
)

print()
print(
    "Test Accuracy:",
    round(accuracy * 100, 2),
    "%",
)
print()

print("Classification Report:")
print(
    classification_report(
        y_test,
        predictions,
        target_names=target_encoder.classes_,
    )
)

print("Confusion Matrix:")
print(
    confusion_matrix(
        y_test,
        predictions,
    )
)

# =====================================
# SAVE MODEL
# =====================================

joblib.dump(
    {
        "model": model,
        "goal_encoder": goal_encoder,
        "activity_encoder": activity_encoder,
        "target_encoder": target_encoder,
        "feature_columns": list(X.columns),
    },
    "ai_program_model.pkl",
)

print()
print("Model kaydedildi.")
print("Dosya: ai_program_model.pkl")