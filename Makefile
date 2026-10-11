# Amazon Product Recommendation System Makefile
# Cross-platform environment management and execution

PYTHON ?= python3
VENV_DIR ?= .venv

ifeq ($(OS),Windows_NT)
    VENV_BIN := $(VENV_DIR)/Scripts
    VENV_PYTHON := $(VENV_BIN)/python.exe
    VENV_PIP := $(VENV_BIN)/pip.exe
else
    VENV_BIN := $(VENV_DIR)/bin
    VENV_PYTHON := $(VENV_BIN)/python
    VENV_PIP := $(VENV_BIN)/pip
endif

NOTEBOOK := Recommendation_Systems.ipynb
HTML_REPORT := Recommendation_Systems.html

.PHONY: help venv install data run export-html clean clean-venv all

help:
	@echo "Available Makefile targets:"
	@echo "  make venv         - Create local virtual environment (.venv)"
	@echo "  make install      - Install all dependencies from requirements.txt"
	@echo "  make data         - Decompress dataset (ratings_Electronics.csv.xz -> ratings_Electronics.csv)"
	@echo "  make run          - Execute learner notebook end-to-end headlessly"
	@echo "  make export-html  - Export executed notebook to HTML report"
	@echo "  make clean        - Remove Python and Jupyter cache directories"
	@echo "  make clean-venv   - Remove virtual environment directory (.venv)"
	@echo "  make all          - Build venv, install dependencies, extract data, run notebook, and export HTML"

venv: $(VENV_PYTHON)

$(VENV_PYTHON):
	@echo "--> Creating virtual environment in $(VENV_DIR)..."
	$(PYTHON) -m venv $(VENV_DIR)

install: venv
	@echo "--> Upgrading pip and installing dependencies from requirements.txt..."
	$(VENV_PIP) install --upgrade pip
	$(VENV_PIP) install -r requirements.txt

data: ratings_Electronics.csv

ratings_Electronics.csv: ratings_Electronics.csv.xz
	@echo "--> Decompressing dataset (ratings_Electronics.csv.xz)..."
	@$(PYTHON) -c "import lzma, shutil; shutil.copyfileobj(lzma.open('ratings_Electronics.csv.xz', 'rb'), open('ratings_Electronics.csv', 'wb'))"

run: install data
	@echo "--> Executing notebook: $(NOTEBOOK)..."
	$(VENV_BIN)/jupyter nbconvert --to notebook --execute --inplace "$(NOTEBOOK)"

export-html: run
	@echo "--> Exporting notebook to HTML report..."
	$(VENV_BIN)/jupyter nbconvert --to html "$(NOTEBOOK)" --output "$(HTML_REPORT)"

clean:
	@echo "--> Removing cache files and temporary artifacts..."
	rm -rf __pycache__ .pytest_cache .ipynb_checkpoints

clean-venv:
	@echo "--> Removing virtual environment..."
	rm -rf $(VENV_DIR)

all: install data run export-html
