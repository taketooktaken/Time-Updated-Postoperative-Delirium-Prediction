# Time-Updated Postoperative Delirium Prediction

This repository contains code for extracting data from the OneICU database and developing machine-learning models for predicting postoperative delirium in intensive care unit (ICU) patients.

The project includes both dynamic, time-updated prediction models and a single-timepoint 24-hour prediction model. The workflow is designed to provide a reproducible pipeline for cohort construction, feature extraction, model development, evaluation, and interpretation using real-world ICU data.

## Table of Contents

- Overview
- Repository Structure
- Requirements
- Usage
- Dynamic Prediction Models
- Single-Timepoint 24-Hour Model
- License
- Contact

## Overview

This repository contains SQL and Python scripts for:

- Constructing the study cohort from the OneICU database
- Extracting and preprocessing clinical features
- Developing dynamic models for predicting delirium within 24 or 72 hours
- Developing a single-timepoint model using data from the first 24 hours after ICU admission
- Training machine-learning models using H2O AutoML
- Evaluating model performance using AUROC, AUPRC, and calibration
- Interpreting model predictions using SHAP values

For the dynamic models, clinical information is updated over time using hourly time windows. The prediction horizon can be configured as either 24 or 72 hours by changing the corresponding time-horizon parameter in the dynamic-model analysis code.

The single-timepoint 24-hour model summarizes clinical information collected during the first 24 hours after ICU admission and generates one prediction per ICU stay.

## Repository Structure

```text
TIME-UPDATED-POSTOPERATIVE-DELIRIUM
├── python_for_dynamic_models/
│   └── ...
├── python_for_single_timepoint_model/
│   └── ...
├── sql_for_dynamic_models/
│   └── ...
├── sql_for_single_timepoint_model/
│   └── ...
├── LICENSE
└── README.md
```

### `sql_for_dynamic_models/`

Contains SQL scripts for cohort construction, feature extraction, preprocessing, and creation of hourly time-window data used for the dynamic prediction models.

The same pipeline can be used for both the 24-hour and 72-hour dynamic prediction tasks by specifying the corresponding prediction horizon.

### `python_for_dynamic_models/`

Contains Python scripts for:

- Preprocessing time-updated data
- Constructing prediction labels based on the specified prediction horizon
- Training minimum, compact, and full machine-learning models
- Evaluating model performance using AUROC and AUPRC
- Assessing model calibration
- Calculating and visualizing SHAP values

The dynamic modeling code supports both the **24-hour** and **72-hour** prediction models. These analyses can be performed by changing the prediction-horizon parameter in the relevant scripts to either 24 or 72 hours.

### `sql_for_single_timepoint_model/`

Contains SQL scripts for cohort construction and extraction of clinical features collected during the first 24 hours after ICU admission.

Time-series variables are summarized over the initial 24-hour period to generate a single feature set for each ICU stay.

### `python_for_single_timepoint_model/`

Contains Python scripts for:

- Preprocessing the 24-hour feature dataset
- Training the single-timepoint machine-learning model
- Evaluating model performance
- Generating ROC and precision-recall curves
- Assessing calibration
- Calculating and visualizing SHAP values

## Requirements

### Google BigQuery Access

To run the SQL scripts, access to Google BigQuery and appropriate credentials for querying the OneICU database are required.

### Python

Python 3.12 or a compatible version is recommended.

### Python Packages

The analysis uses common data science and machine-learning packages, including:

- pandas
- numpy
- matplotlib
- scikit-learn
- h2o
- shap

Please refer to the individual Python scripts for specific package requirements.

## Usage

### Dynamic Prediction Models

1. Navigate to `sql_for_dynamic_models/`.
2. Run the SQL scripts in the appropriate order to construct the study cohort and extract time-updated features.
3. Navigate to `python_for_dynamic_models/`.
4. Specify the desired prediction horizon as **24 hours** or **72 hours** in the relevant analysis code.
5. Run the Python scripts to:
   - preprocess the extracted data,
   - train the machine-learning models,
   - evaluate discrimination and calibration, and
   - generate SHAP-based model interpretation outputs.

The same dynamic-model pipeline is used for both prediction horizons; the prediction horizon is changed through the corresponding time-horizon variable in the analysis code.

### Single-Timepoint 24-Hour Model

1. Navigate to `sql_for_single_timepoint_model/`.
2. Run the SQL scripts to construct the study cohort and summarize clinical information from the first 24 hours after ICU admission.
3. Navigate to `python_for_single_timepoint_model/`.
4. Run the Python scripts to:
   - preprocess the extracted data,
   - train the single-timepoint 24-hour model,
   - evaluate predictive performance and calibration, and
   - generate SHAP-based model interpretation outputs.

## Reproducibility

This repository provides the analysis code used for data extraction, preprocessing, model development, evaluation, and interpretation.

Individual-level patient data from the OneICU database are not included in this repository because of data-use and privacy restrictions. Access to the appropriate OneICU datasets is therefore required to reproduce the complete analysis.

## Contact

For questions or collaboration inquiries, please contact:

MeDiCU, Inc.

## License

This project is licensed under the GNU General Public License (GPL). See the `LICENSE` file for details.

## Disclaimer

The code in this repository is provided for academic research and educational purposes. Individual patient data are not provided.