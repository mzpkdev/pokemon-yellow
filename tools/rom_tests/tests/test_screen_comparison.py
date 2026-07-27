"""Focused unit coverage for visual-regression masking."""

from PIL import Image

from tools.rom_tests.emulator import screen_difference


def test_ignored_region_masks_only_that_region() -> None:
    reference = Image.new("RGB", (160, 144), "white")
    actual = reference.copy()
    actual.paste("black", (32, 88, 48, 104))
    actual.putpixel((120, 120), (0, 0, 0))

    difference = screen_difference(
        actual,
        reference,
        ignored_regions=((24, 80, 56, 112),),
    )

    assert difference.getpixel((32, 88)) == (0, 0, 0)
    assert difference.getpixel((120, 120)) != (0, 0, 0)
    assert difference.getbbox() == (120, 120, 121, 121)


def test_full_frame_is_compared_without_ignored_regions() -> None:
    reference = Image.new("RGB", (160, 144), "white")
    actual = reference.copy()
    actual.putpixel((80, 120), (0, 0, 0))

    difference = screen_difference(actual, reference)

    assert difference.getbbox() == (80, 120, 81, 121)
