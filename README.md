# Amazon Product Recommendation System

[![Python 3.12](https://img.shields.io/badge/Python-3.12-3776AB.svg?logo=python&logoColor=white)](https://www.python.org/)
[![Surprise](https://img.shields.io/badge/Library-scikit--surprise-orange.svg)](http://surpriselib.com/)
[![Jupyter](https://img.shields.io/badge/Notebook-Jupyter-F37626.svg?logo=jupyter&logoColor=white)](https://jupyter.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

An end-to-end recommendation systems case study analyzing Amazon Electronics customer review ratings. This project implements, tunes, and empirically benchmarks multiple recommendation paradigms—ranging from popularity-based baselines and memory-based collaborative filtering to latent factor matrix factorization (SVD).

---

## Table of Contents

- [Project Overview](#project-overview)
- [Dataset](#dataset)
- [Recommendation Architectures](#recommendation-architectures)
- [Model Evaluation & Benchmarking](#model-evaluation--benchmarking)
- [Key Insights & Metric Trade-Offs](#key-insights--metric-trade-offs)
- [Repository Structure](#repository-structure)
- [Quick Start](#quick-start)
  - [Prerequisites](#prerequisites)
  - [Automated Setup via Makefile](#automated-setup-via-makefile)
- [Deliverables](#deliverables)
- [Author](#author)

---

## Project Overview

Modern e-commerce platforms handle massive product catalogs with sparse customer engagement matrices. The objective of this project is to build personalized product recommendation algorithms that accurately predict user preferences and generate relevant top-$N$ item recommendations for Amazon Electronics shoppers.

The workflow spans:
1. **Exploratory Data Analysis (EDA):** Interaction density, rating distributions, and active user/product dynamics.
2. **Rank-Based / Popularity Baseline:** Mitigating cold-start for new visitors using interaction thresholding.
3. **User-User Collaborative Filtering (`KNNBasic`):** Neighbor-based similarity leveraging cosine distance.
4. **Item-Item Collaborative Filtering (`KNNBasic`):** Item similarity evaluation across MSD and Cosine metrics.
5. **Matrix Factorization (`SVD`):** Latent factor matrix decomposition via Regularized Stochastic Gradient Descent.
6. **Top-$K$ Evaluation:** Joint optimization of rating accuracy (RMSE) and ranking quality (Precision@10, Recall@10, F1@10).

---

## Dataset

- **Source:** Amazon Electronics Review Ratings dataset (7.8M+ original interactions).
- **Attributes:** `user_id`, `prod_id`, `rating` (scale: 1–5), `timestamp` (dropped for static modeling).
- **Pre-filtering:**
  - Users with $\ge 50$ ratings.
  - Products with $\ge 5$ ratings.
  - Results in a filtered, dense subset of **125,871 interactions** across **1,540 users** and **5,689 products**.
- **Archive:** The compressed dataset [`ratings_Electronics.csv.xz`](ratings_Electronics.csv.xz) (~81 MB) is tracked in the repository. Decompressing it yields `ratings_Electronics.csv` (~318 MB).

---

## Recommendation Architectures

### 1. Rank-Based (Popularity) Model
- Computes mean rating and total interaction count per product.
- Applies minimum interaction thresholds ($N > 50$, $N > 100$) to surface globally high-rated, high-confidence items.
- Primary role: non-personalized cold-start solution for new users with no prior rating history.

### 2. User-User Collaborative Filtering
- **Framework:** `KNNBasic` (`user_based=True`, Cosine similarity).
- **Mechanism:** Finds the $k$ most similar users based on shared item rating vectors.
- **Tuning:** Grid search cross-validation across neighbor sizes ($k \in [10, 20, 30]$) and minimum overlap constraints ($\text{min\_k} \in [3, 6, 9]$).

### 3. Item-Item Collaborative Filtering
- **Framework:** `KNNBasic` (`user_based=False`).
- **Mechanism:** Computes pairwise similarity between products based on co-rating patterns across users.
- **Tuning:** Grid search cross-validation optimizing distance metric (MSD vs. Cosine) and neighborhood thresholds.

### 4. Matrix Factorization (SVD)
- **Framework:** Regularized Singular Value Decomposition (`surprise.SVD`).
- **Mechanism:** Learns low-dimensional user ($p_u$) and item ($q_i$) latent vectors and bias terms ($b_u, b_i, \mu$) to estimate unobserved ratings:
  $$\hat{r}_{ui} = \mu + b_u + b_i + q_i^T p_u$$
- **Tuning:** 3-fold Grid Search CV over epochs ($n \in [10, 20, 30]$), learning rate ($\gamma \in [0.001, 0.005, 0.01]$), and regularization ($\lambda \in [0.2, 0.4, 0.6]$).

---

## Model Evaluation & Benchmarking

All models were evaluated on an 70/30 train-test split using both rating prediction error (RMSE) and ranking quality (Precision@10, Recall@10, and F1@10 at rating threshold $\ge 3.5$):

| Model Architecture | Hyperparameters | Test RMSE | Precision@10 | Recall@10 | F1-Score@10 |
| :--- | :--- | :---: | :---: | :---: | :---: |
| **Baseline User-User CF** | Cosine, $k=40$, $\text{min\_k}=1$ | 1.0065 | 0.8550 | 0.9080 | 0.8807 |
| **Tuned User-User CF** | Cosine, $k=30$, $\text{min\_k}=6$ | 0.9521 | 0.8465 | 0.8950 | 0.8701 |
| **Baseline Item-Item CF** | Cosine, $k=40$, $\text{min\_k}=1$ | 0.9954 | 0.8380 | 0.8790 | 0.8580 |
| **Tuned Item-Item CF** | MSD, $k=30$, $\text{min\_k}=6$ | 0.9576 | 0.8427 | 0.8961 | 0.8686 |
| **Baseline SVD** | Default ($n=20$, $\gamma=0.005$, $\lambda=0.02$) | 0.8882 | 0.8530 | 0.8795 | 0.8660 |
| **Tuned SVD** | $n=30$, $\gamma=0.01$, $\lambda=0.2$ | **0.8898** | **0.8537** | **0.8804** | **0.8668** |

---

## Key Insights & Metric Trade-Offs

1. **RMSE vs. Top-$K$ Ranking:**
   - SVD achieves the lowest rating prediction error ($\text{RMSE} \approx 0.8898$), significantly outperforming neighborhood CF methods.
   - However, in ranking quality (Precision@10 / Recall@10), neighborhood-based methods perform competitively (F1 $\approx 0.87–0.88$). In e-commerce, top-$K$ relevance often matters more than pinpoint precision on unconsumed 1-star items.
2. **Cold-Start Strategy:**
   - Collaborative filtering and SVD require prior interaction history. New users are routed to the Rank-Based Popularity Model (products with $>100$ ratings and average score $\ge 4.5$) before switching to personalized matrix factorization as ratings accumulate.
3. **Item-Item vs. User-User Scalability:**
   - In production catalogs where products change less frequently than user activity, Item-Item CF and precomputed SVD latent representations provide superior caching and latency characteristics.

---

## Repository Structure

```text
RecSys-Amazon-Product/
├── .gitignore                    # Build and data ignore rules (*.csv)
├── Makefile                      # Cross-platform setup, execution, and export
├── Recommendation_Systems.ipynb  # Fully executed Jupyter Notebook with analysis & outputs
├── Recommendation_Systems.html   # Standalone HTML report of executed notebook
├── ratings_Electronics.csv.xz    # Compressed Amazon Electronics dataset (~81 MB)
├── requirements.txt              # Pinned Python package dependencies
└── README.md                     # Comprehensive project documentation
```

---

## Quick Start

### Prerequisites
- Python **3.10+** (Python 3.12 recommended)
- `make` (standard on macOS and Linux; available via MSYS2 / WSL on Windows)

### Automated Setup via Makefile

The repository includes a system-independent [`Makefile`](Makefile) for environment creation, data decompression, headless execution, and HTML generation:

```bash
# 1. View all available targets
make help

# 2. Create the virtual environment (.venv)
make venv

# 3. Install dependencies from requirements.txt
make install

# 4. Decompress dataset (ratings_Electronics.csv.xz -> ratings_Electronics.csv)
make data

# 5. Execute the entire notebook headlessly
make run

# 6. Export the executed notebook to an HTML report
make export-html

# Or run the complete pipeline in a single step:
make all
```

---

## Deliverables

- **Jupyter Notebook:** [`Recommendation_Systems.ipynb`](Recommendation_Systems.ipynb) — Fully executed code with zero errors, detailed observations, and discussion.
- **HTML Report:** [`Recommendation_Systems.html`](Recommendation_Systems.html) — Self-contained rendered notebook export.

---

## Author

**Armin Salmasi**  
- GitHub: [@arminsalmasi](https://github.com/arminsalmasi)
