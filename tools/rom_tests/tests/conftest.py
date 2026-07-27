"""Shared pytest fixtures for ROM tests."""

import os
from pathlib import Path

import pytest

from tools.rom_tests.emulator import Emulator


REPOSITORY_ROOT = Path(__file__).resolve().parents[3]
RESULTS = REPOSITORY_ROOT / "test-results"


@pytest.fixture
def emulator() -> Emulator:
    driver = Emulator(
        rom=Path(os.environ.get("ROM_TEST_ROM", REPOSITORY_ROOT / "pokeyellow_debug.gbc")),
        symbols=Path(
            os.environ.get(
                "ROM_TEST_SYMBOLS",
                REPOSITORY_ROOT / "pokeyellow_debug.sym",
            )
        ),
        results=RESULTS,
    )
    try:
        yield driver
    finally:
        driver.close()
