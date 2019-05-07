# Task 2 of the AGD Lab Course 2019

## Meta-Learning for Feature Selection

The dataset comes from the experiments for

> Post (2016): "Does Feature Selection Improve Classification? A Large Scale Experiment in OpenML"

On OpenML, this is [study 15](https://www.openml.org/s/15)

- `ExplorePost2016Data` contains the inital code for download, exploration and some predictions. It is superseded by more specific files, which are more directly related to the concrete task.
- `PrepareFSData` builds the meta-dataset from OpenML and prepares it for the task. All available OpenML "dataset qualities" are used as meta-features. The difference in AUC between features selection and no feature selection (for each base dataset and base classifier) is used as `target`, but the individual `Performance` for either approach is saved as well. Data objects are identified by `classifier` plus `data.id` or `dataset`. The latter attributes also allow to retrieve the original base datasets and compute further meta-features. The final meta-dataset is saved as RDS and CSV, but the raw run (classifier performance) and dataset quality data are saved as well, so slightly different meta-datasets can be created easily without starting the whole download again.
