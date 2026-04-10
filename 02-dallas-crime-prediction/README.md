# Dallas Crime Data: Predicting Crime Locations Using Machine Learning

Multi-class classification project predicting where a crime will occur (location/premise type) based on crime type and category. Built on 10 years of Dallas Police Department open data.

## Results

### All Location Classes (2024 Holdout)

| Model | Accuracy | AUC |
|-------|----------|-----|
| Logistic Regression | 0.0667 | **0.7175** |
| Random Forest | 0.0400 | 0.7054 |
| KNN | 0.1867 | 0.6107 |

### Top 5 Most Frequent Locations (2024 Holdout)

| Model | Accuracy |
|-------|----------|
| Logistic Regression | **0.4211** |
| Random Forest | **0.4211** |
| KNN | 0.2895 |

Filtering to top-5 locations significantly improves accuracy — confirms that multi-class imbalance is the primary driver of degraded full-set performance.

## Data

- **Source:** Dallas Open Data Portal (Socrata API)
- **Time range:** 2014–2024
- **Records:** 10,000 pulled → 9,790 after cleaning
- **Train set:** 2014–2023
- **Test set:** 2024 holdout

**Features used:**
- `crime` (offense incident type)
- `crime_category` (NIBRS category)

**Target:** `location` (premise type — multi-class)

## Methodology

1. Pulled data via Socrata API (`sodapy`)
2. Cleaned missing/unclear values (primarily in NIBRS category)
3. One-hot encoded all categorical features
4. 3-fold cross-validation during model training
5. Final evaluation on 2024 holdout — strict temporal separation

## Stack

Python · scikit-learn · sodapy · pandas · NumPy · Matplotlib · Jupyter

## Files

- [`analysis.ipynb`](analysis.ipynb) — full notebook: data pull, cleaning, modeling, evaluation
- [`report.pdf`](report.pdf) — final project report

## Limitations and Future Work

- Multi-class imbalance is the core bottleneck — ~60+ location classes with very unequal distribution
- Potential improvements:
  - SMOTE or other resampling for rare classes
  - Gradient boosting (XGBoost, LightGBM)
  - Hyperparameter tuning with RandomizedSearchCV
  - Adding temporal features (time of day, day of week, month)
  - Geographic clustering with lat/lon coordinates
