#!/usr/bin/env bash
# Zero Client Configuration
# This file contains all shared configuration variables used across scripts.
# Source this file at the beginning of any script that needs these values.
# Variables can be overridden via environment variables before sourcing.

# Image settings
export ZC_IMAGE_NAME="${ZC_IMAGE_NAME:-zero-client.img}"
export ZC_IMAGE_SIZE_GB="${ZC_IMAGE_SIZE_GB:-10}"

# Filesystem settings
export ZC_ROOT_MOUNT="${ZC_ROOT_MOUNT:-/mnt/zero-img}"
export ZC_ESP_SIZE="${ZC_ESP_SIZE:-500M}"
export ZC_ROOT_LABEL="${ZC_ROOT_LABEL:-ZEROROOT}"
export ZC_ESP_LABEL="${ZC_ESP_LABEL:-ZEROEFI}"

# User settings
export ZC_USER="${ZC_USER:-zero}"
export ZC_USER_HOME="${ZC_USER_HOME:-/home/${ZC_USER}}"
export ZC_USER_COMMENT="${ZC_USER_COMMENT:-Linkin Zero Client}"

# Version and repository
export ZC_BRANCH="${ZC_BRANCH:-v4}"
export ZC_GITHUB_REPO="${ZC_GITHUB_REPO:-techno-link/zero-client}"
export ZC_DISTRO_RELEASE="${ZC_DISTRO_RELEASE:-noble}"

# DD/burn settings
export ZC_DD_BLOCK_SIZE="${ZC_DD_BLOCK_SIZE:-4M}"
export ZC_PV_RATE_LIMIT="${ZC_PV_RATE_LIMIT:-20m}"
export ZC_STAGGER_SECONDS="${ZC_STAGGER_SECONDS:-2}"

# Derived URLs (computed from above)
export ZC_GITHUB_RAW_URL="https://raw.githubusercontent.com/${ZC_GITHUB_REPO}/${ZC_BRANCH}"
export ZC_ANSIBLE_URL="${ZC_GITHUB_RAW_URL}/ansible/zero.yml"
