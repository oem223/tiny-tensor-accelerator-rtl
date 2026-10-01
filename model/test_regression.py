"""Check reproducibility, boundary preservation, and the stimulus contract."""

import unittest

from model.generate_regression import build_regression


class RegressionTests(unittest.TestCase):
    def test_reproducible_seed(self) -> None:
        first = build_regression(17, 100)
        self.assertEqual(first, build_regression(17, 100))
        self.assertNotEqual(first[8:], build_regression(23, 100)[8:])

    def test_directed_oracles_preserved(self) -> None:
        rows = build_regression(17, 0)
        self.assertEqual(rows[0][:12], (1, 2, 3, 4, 5, 6, 7, 8, 19, 22, 43, 50))
        self.assertEqual(rows[5][:12], (-128,) * 8 + (32768,) * 4)

    def test_stimulus_contract(self) -> None:
        rows = build_regression(17, 100)
        self.assertEqual(len(rows), 108)
        self.assertEqual({row[12] for row in rows[:8]}, {0, 1, 2, 3})
        self.assertEqual({row[13] for row in rows[:8]}, {0, 1, 2, 5, 20})
        for row in rows:
            self.assertEqual(len(row), 14)
            self.assertTrue(all(-128 <= x <= 127 for x in row[:8]))
            self.assertTrue(all(-2**31 <= x < 2**31 for x in row[8:12]))
            self.assertIn(row[12], range(4))
            self.assertIn(row[13], (0, 1, 2, 5, 20))

    def test_invalid_settings(self) -> None:
        for seed, count in ((-1, 100), (2**31, 100), (17, -1), (17, 10001)):
            with self.assertRaises(ValueError):
                build_regression(seed, count)


if __name__ == "__main__":
    unittest.main()