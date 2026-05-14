# SPDX-License-Identifier: BSD-3-Clause
# Copyright(c) 2026 Intel Corporation
import pytest
from mtl_engine.media_files import yuv_files


@pytest.fixture
def stream_info():
    """Mixed st20p+st30p+ancillary suite: video dominates the packet rate,
    so size the EBU LIST capture for full ST 2110-20 frames of the
    1080p50 video stream the test produces."""
    return yuv_files["i1080p50"]
