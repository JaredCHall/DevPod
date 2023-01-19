#!/bin/bash
set -euo pipefail

dnf module install nodejs:${NODE_VERSION}
