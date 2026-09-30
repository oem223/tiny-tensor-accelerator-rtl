"""Hand-calculated examples and boundary checks for the independent model."""

import unittest

from model.reference import matmul_2x2


class ReferenceTests(unittest.TestCase):
    def test_known_positive_and_signed_examples(self) -> None:
        self.assertEqual(
            matmul_2x2((1, 2, 3, 4), (5, 6, 7, 8)), (19, 22, 43, 50)
        )
        self.assertEqual(
            matmul_2x2((-1, 2, 3, -4), (5, -6, -7, 8)),
            (-19, 22, 43, -50),
        )

    def test_signed_boundary(self) -> None:
        self.assertEqual(
            matmul_2x2((-128,) * 4, (-128,) * 4), (32768,) * 4
        )
        self.assertEqual(
            matmul_2x2((-128,) * 4, (127,) * 4), (-32512,) * 4
        )

    def test_invalid_width_and_element(self) -> None:
        with self.assertRaises(ValueError):
            matmul_2x2((128, 0, 0, 0), (1, 0, 0, 1))
        with self.assertRaises(ValueError):
            matmul_2x2((1, 0, 0, 1), (1, 0, 0, 1), acc_width=16)


if __name__ == "__main__":
    unittest.main()
