"""Generate deterministic 8-bit input / 32-bit output vectors for later RTL tests."""

import argparse
from pathlib import Path

from .reference import matmul_2x2


CASES = (
    ("positive", (1, 2, 3, 4), (5, 6, 7, 8)),
    ("mixed_sign", (-1, 2, 3, -4), (5, -6, -7, 8)),
    ("identity", (1, 0, 0, 1), (9, 8, 7, 6)),
    ("all_zero", (0, 0, 0, 0), (0, 0, 0, 0)),
    ("all_max", (127, 127, 127, 127), (127, 127, 127, 127)),
    ("all_min", (-128, -128, -128, -128), (-128, -128, -128, -128)),
    ("negative_products", (-128, -128, -128, -128), (127, 127, 127, 127)),
    ("mixed_extremes", (-128, 127, 127, -128), (-128, 127, 127, -128)),
)


def main() -> None:
    default_path = Path(__file__).resolve().parent.parent / "vectors" / "directed_2x2.txt"
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=default_path)
    args = parser.parse_args()

    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", encoding="ascii", newline="\n") as output:
        for _, a, b in CASES:
            c = matmul_2x2(a, b)
            output.write(" ".join(map(str, (*a, *b, *c))) + "\n")
    print(f"Wrote {len(CASES)} directed vectors to {args.output}")


if __name__ == "__main__":
    main()
