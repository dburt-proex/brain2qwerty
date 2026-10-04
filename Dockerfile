# Copyright (c) Meta Platforms, Inc. and affiliates.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

FROM nvidia/cuda:12.4.1-runtime-ubuntu24.04

# Prevent interactive prompts during apt installation
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH="/opt/venv/bin:$PATH"

# Install OS dependencies and Python 3.12 (native to Ubuntu 24.04)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    curl \
    ca-certificates \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    libsndfile1 \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Create and activate dedicated virtual environment
RUN python3 -m venv /opt/venv && \
    pip install --no-cache-dir --upgrade pip setuptools wheel

WORKDIR /workspace

# Layer cache: copy requirements and install dependencies first
COPY requirements.lock pyproject.toml /workspace/

RUN pip install --no-cache-dir -r requirements.lock && \
    pip install --no-cache-dir -e ".[dev,viz,lm]" --no-deps

# Copy the repository code
COPY . /workspace/

# Install the brain2qwerty packages in editable mode
RUN pip install --no-cache-dir -e . --no-deps

# Default Brain2Qwerty storage paths
ENV BRAIN2QWERTY_CACHE="/workspace/.cache/brain2qwerty" \
    BRAIN2QWERTY_RESULTS="/workspace/.cache/brain2qwerty/results" \
    BRAIN2QWERTY_STUDIES="/workspace/data/SpanishBCBL" \
    BRAIN2QWERTY_STUDIES_EN="/workspace/data/EnglishBCBL"

# Default command: run the test suite
CMD ["pytest", "tests/", "-q"]
