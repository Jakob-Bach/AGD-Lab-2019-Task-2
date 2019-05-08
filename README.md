# Task 2 of the AGD Lab Course 2019

The code is written in R.
The `data.table` package is required.

## Meta-Learning for Feature Selection

The dataset comes from the experiments for

> Post (2016): "Does Feature Selection Improve Classification? A Large Scale Experiment in OpenML"

On OpenML, this is [study 15](https://www.openml.org/s/15).

- `ExplorePost2016Data` contains the inital code for download, exploration and some predictions. It is superseded by more specific files, which are more directly related to the concrete task.
- `PrepareFSData` builds the meta-dataset from OpenML and prepares it for the task. All available OpenML "dataset qualities" are used as meta-features. The difference in AUC between features selection and no feature selection (for each base dataset and base classifier) is used as `target`, but the individual `Performance` for either approach is saved as well. Data objects are identified by `classifier` plus `data.id` or `dataset`. The latter attributes also allow to retrieve the original base datasets and compute further meta-features. The final meta-dataset is saved as RDS and CSV, but the raw run (classifier performance) and dataset quality data are saved as well, so slightly different meta-datasets can be created easily without starting the whole download again.
- `SplitFSData` creates splits for the students, similar to the DMC task. Currently these are cross-validation splits making sure that all entries belonging to the same base dataset go into the same fold.
- `CreateFSDemoSubmission` creates valid submission files using a very simple baseline: always predicting zero difference between feature selection and not.
- `ScoreForFSData` reads in prediction files from a directory, does some sanity checks and then computes the RSME regarding the ground truth.

## Meta-learning for Hyperparameter Tuning

The dataset was created explicitly for experiments on the influence of hyperparameters and is described in

> Kühn (2018): "Automatic Exploration of Machine Learning Experiments on OpenML"

- `ExploreKuhn2018Data` contains the initial code for downloading the data and some preparation for predictions. It is superseded by more specific files, which are more directly related to the concrete task.
- `PrepareTuningData` builds the meta-dataset based on a downloadable CSV offered by the authors (in theory, one could also collect even more runs from [OpenML](https://www.openml.org/u/2702)). We use the `xgboost` data (most hyperparameters of all base classifiers) and runtime (if greater than 1s - considering random fluctuation and wanting to use a relative measure for meta-performance) as prediction target. Seven very basic meta-features are included by default, but the dataset id can be used to get more information from OpenML. The final meta-dataset is saved as RDS and CSV.
- `SplitTuningData` creates a holdout split, making sure that all entries belonging to the same base dataset go into either into train or test.
