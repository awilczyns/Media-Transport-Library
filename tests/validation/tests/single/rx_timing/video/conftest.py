# SPDX-License-Identifier: BSD-3-Clause
# Copyright(c) 2026 Intel Corporation
import pytest
from mtl_engine.media_files import yuv_files


@pytest.fixture
def stream_info(request):
    """Map this suite's video parametrization to the producer stream.

    Tests parametrized on ``video_format`` resolve via ``yuv_files``;
    fixed-format tests (e.g. test_replicas) declare a 1080p60 stream
    matching what they send to RxTxApp.
    """
    if "video_format" in request.fixturenames:
        return yuv_files[request.getfixturevalue("video_format")]
    return yuv_files["i1080p60"]
