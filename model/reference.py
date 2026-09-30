"""Mathematical reference for signed 2x2 matrix multiplication.

Inputs and outputs are row-major tuples. This model deliberately uses ordinary
integer arithmetic, independent of the RTL's MAC schedule and handshakes.
"""

from collections.abc import Sequence


def matmul_2x2(
    a: Sequence[int], b: Sequence[int], *, in_width: int = 8, acc_width: int = 32
) -> tuple[int, int, int, int]:
    """Return A x B as (c00, c01, c10, c11), validating signed widths."""
    if type(in_width) is not int or in_width < 2:
        raise ValueError("in_width must be an integer of at least 2")
    if type(acc_width) is not int or acc_width < 2 * in_width + 1:
        raise ValueError("acc_width must be at least 2*in_width+1 for exact sums")
    if len(a) != 4 or len(b) != 4:
        raise ValueError("each 2x2 matrix needs four row-major elements")

    lower = -(1 << (in_width - 1))
    upper = (1 << (in_width - 1)) - 1
    for name, values in (("A", a), ("B", b)):
        for index, value in enumerate(values):
            if type(value) is not int or not lower <= value <= upper:
                raise ValueError(
                    f"{name}[{index}] must be a signed {in_width}-bit integer "
                    f"in [{lower}, {upper}]"
                )

    return (
        a[0] * b[0] + a[1] * b[2],
        a[0] * b[1] + a[1] * b[3],
        a[2] * b[0] + a[3] * b[2],
        a[2] * b[1] + a[3] * b[3],
    )
