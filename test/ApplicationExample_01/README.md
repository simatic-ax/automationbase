# ApplicationExample_01 Tests

## Overview

This test suite validates the bool-based release example defined locally in `test/ApplicationExample_01/ReleaseExampleTest.st`.

The tests prove that the example is not just illustrative text, but a working pattern that can be promoted into the top-level README.

## Covered Behavior

- `BoolRelease` returns the configured boolean value
- `MyConveyor` stays stopped when the release signal is `FALSE`
- `MyConveyor` stops again when the release signal changes from `TRUE` to `FALSE` after automatic startup
- `MyConveyor` runs when the release signal is `TRUE` and the mode is `Automatic`

## File Structure

- `MyConveyorExample.st`: Helper class used by the tests
- `ReleaseExampleTest.st`: AxUnit fixture for the example behavior

## Promotion Rule

The top-level README example should only be updated from this application example after these tests pass.