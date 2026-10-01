"""Generate seeded arithmetic vectors plus input gaps and output stall lengths."""

import argparse
from pathlib import Path
from random import Random

from .generate_vectors import CASES
from .reference import matmul_2x2


def build_regression(seed: int, count: int) -> list[tuple[int, ...]]:
    """Return 8 directed rows plus count random rows, each with 14 fields."""
    if type(seed) is not int or not 0 <= seed <= 2**31 - 1:
        raise ValueError("seed must be an integer in [0, 2147483647]")
    if type(count) is not int or not 0 <= count <= 10000:
        raise ValueError("count must be an integer in [0, 10000]")

    rng = Random(seed)
    rows = []
    # Guarantee always-ready, short-stall, long-stall, and input-gap scenarios.
    directed_stalls = (0, 1, 2, 5, 20, 0, 2, 20)
    for index, (_, a, b) in enumerate(CASES):
        rows.append((*a, *b, *matmul_2x2(a, b), index % 4, directed_stalls[index]))
    for _ in range(count):
        a = tuple(rng.randint(-128, 127) for _ in range(4))
        b = tuple(rng.randint(-128, 127) for _ in range(4))
        gap = rng.randrange(4)
        stall = rng.choice((0, 1, 2, 5, 20))
        rows.append((*a, *b, *matmul_2x2(a, b), gap, stall))
    return rows


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--seed", type=int, default=17)
    parser.add_argument("--count", type=int, default=100, help="random rows, in addition to 8 directed rows")
    parser.add_argument("--output", type=Path,
        default=Path(__file__).resolve().parent.parent / "vectors" / "regression_2x2.txt")
    args = parser.parse_args()
    try:
        rows = build_regression(args.seed, args.count)
    except ValueError as error:
        parser.error(str(error))

    text = f"seed {args.seed} cases {len(rows)}\n"
    text += "".join(" ".join(map(str, row)) + "\n" for row in rows)
    data = text.encode("ascii")
    try:
        if args.output.read_bytes() == data:
            print(f"Already up to date: {args.output} (seed={args.seed}, cases={len(rows)})")
            return
    except FileNotFoundError:
        pass
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_bytes(data)
    print(f"Wrote {args.output} (seed={args.seed}, directed=8, random={args.count})")


if __name__ == "__main__":
    main()