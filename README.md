
| **Documentation** | **Build Status** | **Help** |
|:---:|:---:|:---:|
| [![][docs-dev-img]][docs-dev-url] [![][docs-stable-img]][docs-stable-url] | [![][travis-img]][travis-url] [![][codecov-img]][codecov-url] | [![][slack-img]][slack-url] [![][gitter-img]][gitter-url] |

### AutoMLPipeline (AMLP)
is a package that makes it trivial to create complex ML pipeline structures using simple expressions. AMLP leverages on the built-in macro programming features of Julia to symbolically process, manipulate pipeline expressions, and make it easy to discover optimal structures for machine learning prediction and classification.

To illustrate, here is a pipeline expression and evaluation of a typical machine learning workflow that extracts numerical features (`numf`) for `ica` (Independent Component Analysis) and `pca` (Principal Component Analysis) transformations, respectively, concatenated with the hot-bit encoding (`ohe`) of categorical features (`catf`) of a given data for `rf` (Random Forest) modeling:

```julia
julia> model = @pipeline (catf |> ohe) + (numf |> pca) + (numf |> ica) |> rf
julia> fit!(model,Xtrain,Ytrain)
julia> prediction = transform!(model,Xtest)
julia> score(:accuracy,prediction,Ytest)
julia> crossvalidate(model,X,Y,"balanced_accuracy_score")
```
Just take note that `+` has higher priority than `|>` so if you
are not sure, enclose the operations inside parentheses.
```julia
### these two expressions are the same
@pipeline a |> b + c; @pipeline a |> (b + c)

### these two expressions are the same
@pipeline a + b |> c; @pipeline (a + b) |> c
```

### Motivations
The typical workflow in machine learning
classification or prediction requires
some or combination of the following
preprocessing steps together with modeling:
- feature extraction (e.g. ica, pca, svd)
- feature transformation (e.g. normalization, scaling, ohe)
- feature selection (anova, correlation)
- modeling (rf, adaboost, xgboost, lm, svm, mlp)

Each step has several choices of functions
to use together with their corresponding
parameters. Optimizing the performance of the
entire pipeline is a combinatorial search
of the proper order and combination of preprocessing
steps, optimization of their corresponding
parameters, together with searching for
the optimal model and its hyper-parameters.

Because of close dependencies among various
steps, we can consider the entire process
to be a pipeline optimization problem (POP).
POP requires simultaneous optimization of pipeline
structure and parameter adaptation of its elements.
As a consequence, having an elegant way to
express pipeline structure can help lessen
the complexity in the management and analysis 
of the wide-array of choices of optimization routines.

The target of future work will be the
implementations of different pipeline
optimization algorithms ranging from
evolutionary approaches, integer
programming (discrete choices of POP elements),
tree/graph search, and hyper-parameter search.

### Package Features
- Pipeline API that allows high-level description of processing workflow
- Common API wrappers for ML libs including Scikitlearn, DecisionTree, etc
- Symbolic pipeline parsing for easy expression
  of complex pipeline structures
- Easily extensible architecture by overloading just two main interfaces: fit! and transform!
- Meta-ensembles that allow composition of
    ensembles of ensembles (recursively if needed)
    for robust prediction routines
- Categorical and numerical feature selectors for
    specialized preprocessing routines based on types

### Installation

AutoMLPipeline is in the Julia Official package registry.
The latest release can be installed at the Julia
prompt using Julia's package management which is triggered
by pressing `]` at the julia prompt:
```julia
julia> ]
(v1.3) pkg> update
(v1.3) pkg> add AutoMLPipeline
```
or
```julia
julia> using Pkg
julia> pkg"update"
julia> pkg"add AutoMLPipeline"
```
or

```julia
julia> using Pkg
julia> Pkg.update()
julia> Pkg.add("AutoMLPipeline")
```

### Sample Usage of AMLP
Below outlines some typical way to preprocess and model any dataset.

#### 1. Load Data
##### 1.1 Install CSV and DataFrames Packages
```julia
using Pkg
Pkg.update()
Pkg.add("CSV")
Pkg.add("DataFrames")
```
##### 1.2 Load Data, Extract Input (X) and Target (Y) 
```julia
# Make sure that the input feature is a dataframe and the target output is a 1-D vector.
using AutoMLPipeline
using CSV
profbdata = getprofb()
X = profbdata[:,2:end] 
Y = profbdata[:,1] |> Vector;
head(x)=first(x,5)
head(profbdata)
```

#### 2. Load AutoMLPipeline Package and Submodules
```julia
using AutoMLPipeline, AutoMLPipeline.FeatureSelectors, AutoMLPipeline.EnsembleMethods
using AutoMLPipeline.CrossValidators, AutoMLPipeline.DecisionTreeLearners, AutoMLPipeline.Pipelines
using AutoMLPipeline.BaseFilters, AutoMLPipeline.SKPreprocessors, AutoMLPipeline.Utils
using AutoMLPipeline.SKLearners
```

#### 3. Load Filters, Transformers, and Learners 
```julia
#### Decomposition
pca = SKPreprocessor("PCA"); fa = SKPreprocessor("FactorAnalysis"); ica = SKPreprocessor("FastICA")

#### Scaler 
rb = SKPreprocessor("RobustScaler"); pt = SKPreprocessor("PowerTransformer"); 
norm = SKPreprocessor("Normalizer"); mx = SKPreprocessor("MinMaxScaler")

#### categorical preprocessing
ohe = OneHotEncoder()

#### Column selector
catf = CatFeatureSelector(); 
numf = NumFeatureSelector()

#### Learners
rf = SKLearner("RandomForestClassifier"); 
gb = SKLearner("GradientBoostingClassifier")
lsvc = SKLearner("LinearSVC");     svc = SKLearner("SVC")
mlp = SKLearner("MLPClassifier");  ada = SKLearner("AdaBoostClassifier")
jrf = RandomForest();              vote = VoteEnsemble();
stack = StackEnsemble();           best = BestLearner();
```

Note: You can get a listing of available `SKPreprocessors` and `SKLearners` by invoking the following functions, respectively: 
- `skpreprocessors()`
- `sklearners()`

#### 4. Filter categories and hot-encode them
```julia
pohe = @pipeline catf |> ohe
tr = fit_transform!(pohe,X,Y)
head(tr)
```

#### 5. Numerical Feature Extraction Example 

##### 5.1 Filter numeric features, compute ica and pca features, and combine both features
```julia
pdec = @pipeline (numf |> pca) + (numf |> ica)
tr = fit_transform!(pdec,X,Y)
head(tr)
```

##### 5.2 Filter numeric features, transform to robust and power transform scaling, perform ica and pca, respectively, and combine both
```julia
ppt = @pipeline (numf |> rb |> ica) + (numf |> pt |> pca)
tr = fit_transform!(ppt,X,Y)
head(tr)
```

#### 6. A Pipeline for the Voting Ensemble Learner
```julia
# take all categorical columns and hot-bit encode each, 
# concatenate them to the numerical features,
# and feed them to the voting ensemble
pvote = @pipeline  (catf |> ohe) + (numf) |> vote
pred = fit_transform!(pvote,X,Y)
sc=score(:accuracy,pred,Y)
println(sc)
### cross-validate
crossvalidate(pvote,X,Y,"accuracy_score")
```
Note: `crossvalidate()` supports the following sklearn's performance metric
- `accuracy_score`, `balanced_accuracy_score`, `cohen_kappa_score`
- `jaccard_score`, `matthews_corrcoef`, `hamming_loss`, `zero_one_loss`
- `f1_score`, `precision_score`, `recall_score`

#### 7. Use `@pipelinex` instead of `@pipeline` to print the corresponding function calls in 6
```julia
julia> @pipelinex (catf |> ohe) + (numf) |> vote
:(Pipeline(ComboPipeline(Pipeline(catf, ohe), numf), vote))

# another way is to use @macroexpand with @pipeline
julia> @macroexpand @pipeline (catf |> ohe) + (numf) |> vote
:(Pipeline(ComboPipeline(Pipeline(catf, ohe), numf), vote))
```

#### 8. A Pipeline for the Random Forest (RF)
```julia
# compute the pca, ica, fa of the numerical columns,
# combine them with the hot-bit encoded categorical features
# and feed all to the random forest classifier
prf = @pipeline  (numf |> rb |> pca) + (numf |> rb |> ica) + (numf |> rb |> fa) + (catf |> ohe) |> rf
pred = fit_transform!(prf,X,Y)
score(:accuracy,pred,Y) |> println
crossvalidate(prf,X,Y,"accuracy_score")
```
#### 9. A Pipeline for the Linear Support Vector for Classification (LSVC)
```julia
plsvc = @pipeline ((numf |> rb |> pca)+(numf |> rb |> fa)+(numf |> rb |> ica)+(catf |> ohe )) |> lsvc
pred = fit_transform!(plsvc,X,Y)
score(:accuracy,pred,Y) |> println
crossvalidate(plsvc,X,Y,"accuracy_score")
```

Note: More examples can be found in the *test* directory of the package. Since
the code is written in Julia, you are highly encouraged to read the source
code and feel free to extend or adapt the package to your problem. Please
feel free to submit PRs to improve the package features. 

#### 10. Performance Comparison of Several Learners
##### 10.1 Sequential Processing
```julia
using Random
using DataFrames

Random.seed!(1)
jrf = RandomForest()
ada = SKLearner("AdaBoostClassifier")
sgd = SKLearner("SGDClassifier")
tree = PrunedTree()
std = SKPreprocessor("StandardScaler")
disc = CatNumDiscriminator()
lsvc = SKLearner("LinearSVC")

learners = DataFrame()
for learner in [jrf,ada,sgd,tree,lsvc]
  pcmc = @pipeline disc |> ((catf |> ohe) + (numf |> std)) |> learner
  println(learner.name)
  mean,sd,_ = crossvalidate(pcmc,X,Y,"accuracy_score",10)
  global learners = vcat(learners,DataFrame(name=learner.name,mean=mean,sd=sd))
end;
@show learners;
```

##### 10.2 Parallel Processing
```julia
using Random
using DataFrames
using Distributed

nprocs() == 1 && addprocs()
@everywhere using DataFrames
@everywhere using AutoMLPipeline

Random.seed!(1)
jrf = RandomForest()
ada = SKLearner("AdaBoostClassifier")
sgd = SKLearner("SGDClassifier")
tree = PrunedTree()
std = SKPreprocessor("StandardScaler")
disc = CatNumDiscriminator()
lsvc = SKLearner("LinearSVC")

learners = @distributed (vcat) for learner in [jrf,ada,sgd,tree,lsvc]
  pcmc = @pipeline disc |> ((catf |> ohe) + (numf |> std)) |> learner
  println(learner.name)
  mean,sd,_ = crossvalidate(pcmc,X,Y,"accuracy_score",10)
  DataFrame(name=learner.name,mean=mean,sd=sd)
end
@show learners;

```

#### 11. Automatic Selection of Best Learner
You can use `*` operation as a selector function which outputs the result of the best learner.
If we use the same pre-processing pipeline in 10, we expect that the average performance of
best learner which is `lsvc` will be around 73.0.
```julia
Random.seed!(1)
pcmc = @pipeline disc |> ((catf |> ohe) + (numf |> std)) |> (jrf * ada * sgd * tree * lsvc)
crossvalidate(pcmc,X,Y,"accuracy_score",10)
```

#### 12. Learners as Transformers
It is also possible to use learners in the middle of expression to serve
as transformers and their outputs become inputs to the final learner as illustrated
below.
```julia
expr = @pipeline ( 
                   ((numf |> rb)+(catf |> ohe) |> gb) + ((numf |> rb)+(catf |> ohe) |> rf) 
                 ) |> ohe |> ada;
                 
crossvalidate(expr,X,Y,"accuracy_score")
```
One can even include selector function as part of transformer preprocessing routine:
```julia
pjrf = @pipeline disc |> ((catf |> ohe) + (numf |> std)) |> 
                 ((jrf * ada ) + (sgd * tree * lsvc)) |> ohe |> ada

crossvalidate(pjrf,X,Y,"accuracy_score")
```
Note: The `ohe` is necessary in both examples
because the outputs of the learners and selector function are categorical 
values that need to be hot-bit encoded before feeding to the final `ada` learner.

#### 13. Tree Visualization of the Pipeline Structure
You can visualize the pipeline by using AbstractTrees Julia package. 
```julia
# package installation 
julia> using Pkg
julia> Pkg.update()
julia> Pkg.add("AbstractTrees") 

# load the packages
julia> using AbstractTrees
julia> using AutoMLPipeline

julia> expr = @pipelinex (catf |> ohe) + (numf |> pca) + (numf |> ica) |> rf
:(Pipeline(ComboPipeline(Pipeline(catf, ohe), Pipeline(numf, pca), Pipeline(numf, ica)), rf))

julia> print_tree(stdout, expr)
:(Pipeline(ComboPipeline(Pipeline(catf, ohe), Pipeline(numf, pca), Pipeline(numf, ica)), rf))
├─ :Pipeline
├─ :(ComboPipeline(Pipeline(catf, ohe), Pipeline(numf, pca), Pipeline(numf, ica)))
│  ├─ :ComboPipeline
│  ├─ :(Pipeline(catf, ohe))
│  │  ├─ :Pipeline
│  │  ├─ :catf
│  │  └─ :ohe
│  ├─ :(Pipeline(numf, pca))
│  │  ├─ :Pipeline
│  │  ├─ :numf
│  │  └─ :pca
│  └─ :(Pipeline(numf, ica))
│     ├─ :Pipeline
│     ├─ :numf
│     └─ :ica
└─ :rf
```

### Extending AutoMLPipeline
```
# If you want to add your own filter/transformer/learner, it is trivial. 
# Just take note that filters and transformers process the first 
# input features and ignores the target output while learners process both 
# the input features and target output arguments of the fit! function. 
# transform! function always expect one input argument in all cases. 

# First, import the abstract types and define your own mutable structure 
# as subtype of either Learner or Transformer. Also import the fit! and
# transform! functions to be overloaded. Also load the DataFrames package
# as the main data interchange format.

using DataFrames
using AutoMLPipeline.AbsTypes, AutoMLPipeline.Utils

import AutoMLPipeline.AbsTypes: fit!, transform!  #for function overloading 

export fit!, transform!, MyFilter

# define your filter structure
mutable struct MyFilter <: Transformer
  name::String
  model::Dict
  args::Dict
  function MyFilter(args::Dict())
      ....
  end
end

# define your fit! function. 
# filters and transformer ignore the target argument. 
# learners process both the input features and target argument.
function fit!(fl::MyFilter, inputfeatures::DataFrame, target::Vector=Vector())
     ....
end

#define your transform! function
function transform!(fl::MyFilter, inputfeatures::DataFrame)::DataFrame
     ....
end

# Note that the main data interchange format is a dataframe so transform! 
# output should always be a dataframe as well as the input for fit! and transform!.
# This is necessary so that the pipeline passes the dataframe format consistently to
# its filters/transformers/learners. Once you have this filter, you can use 
# it as part of the pipeline together with the other learners and filters.
```

### Feature Requests and Contributions

We welcome contributions, feature requests, and suggestions. Here is the link to open an [issue][issues-url] for any problems you encounter. If you want to contribute, please follow the guidelines in [contributors page][contrib-url].

### Help usage

Usage questions can be posted in:
- [Julia Community](https://julialang.org/community/) 
- [Gitter AutoMLPipeline Community][gitter-url]
- [Julia Discourse forum][discourse-tag-url]


[contrib-url]: https://github.com/IBM/AutoMLPipeline.jl/blob/master/CONTRIBUTORS.md
[issues-url]: https://github.com/IBM/AutoMLPipeline.jl/issues

[discourse-tag-url]: https://discourse.julialang.org/

[gitter-url]: https://gitter.im/AutoMLPipelineLearning/community
[gitter-img]: https://badges.gitter.im/ppalmes/TSML.jl.svg

[slack-img]: https://img.shields.io/badge/chat-on%20slack-yellow.svg
[slack-url]: https://julialang.slack.com/


[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-stable-url]: https://ibm.github.io/AutoMLPipeline.jl/stable/
[docs-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg
[docs-dev-url]: https://ibm.github.io/AutoMLPipeline.jl/dev/

[travis-img]: https://travis-ci.org/IBM/AutoMLPipeline.jl.svg?branch=master
[travis-url]: https://travis-ci.org/IBM/AutoMLPipeline.jl

[codecov-img]: https://codecov.io/gh/IBM/AutoMLPipeline.jl/branch/master/graph/badge.svg
[codecov-url]: https://codecov.io/gh/IBM/AutoMLPipeline.jl
