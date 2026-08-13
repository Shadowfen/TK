# TestKit

A lightweight Lua unit-testing framework for **Elder Scrolls Online (ESO) addon development**.

TestKit is designed for testing ESO Lua libraries and addons outside the normal ESO UI environment while still supporting the kinds of APIs, globals, and test patterns commonly used by ESO addons.

## Features

* Simple test functions with minimal setup
* Assertions for common Lua/ESO test cases
* Test suites and grouped test execution
* Clear pass/fail reporting
* Designed for ESO addon and library development
* Suitable for testing code that normally runs inside ESO
* Can be used from a standalone Lua test environment
* Lightweight with no external testing framework required
* Useful for regression testing during addon development

## Basic Usage

A test typically looks like:

```lua
local function testSomething()
    local result = someFunction()

    TK.assertEquals("expected", result, "result should match expected value")
end
```

Tests can then be grouped into a test runner:

```lua
function runTests()
    TK.init()

    testSomething()
    testSomethingElse()

    TK.showResult("MyAddon")
end
```

The exact test organization is intentionally simple: tests are ordinary Lua functions, and TestKit provides the assertion and reporting infrastructure.

## Assertions

TestKit provides assertions for common unit-test requirements, including:

```lua
TK.assertTrue(condition, message)
TK.assertFalse(condition, message)
TK.assertEquals(expected, actual, message)
```

Assertions should include a useful message describing what is being verified. This makes failures substantially easier to diagnose when running a larger test suite.

Example:

```lua
TK.assertTrue(value ~= nil, "value should exist")
TK.assertEquals(42, result, "calculated value")
```

## Testing ESO Libraries

TestKit is particularly useful for ESO libraries where much of the implementation can be tested independently of the ESO UI.

For example:

```lua
local result = sfutil.optstr(
    {
        tableOpen = "{",
        tableClose = "}",
        keyValueDelim = "=",
    },
    ", ",
    "one",
    "two"
)

TK.assertEquals("one, two", result, "optstr formats multiple values")
```

ESO-specific globals can be mocked or supplied by the test environment when required.

This allows library code to be tested without requiring the complete ESO client to be running.

## Test Organization

A practical TestKit test file generally follows this pattern:

```lua
local function testFeature()
    -- Arrange
    local input = ...

    -- Act
    local result = someFunction(input)

    -- Assert
    TK.assertEquals(expected, result, "feature result")
end

local function testAnotherFeature()
    ...
end

function runTests()
    TK.init()

    testFeature()
    testAnotherFeature()

    TK.showResult("MyLibrary")
end
```

Keeping each test focused on one behavior makes failures easier to understand and makes the test suite useful as executable documentation.

## Testing Edge Cases

TestKit is intended for more than just testing successful calls.

Good unit tests should also cover:

* `nil` values
* empty strings
* empty tables
* nested tables
* recursive table references
* invalid arguments
* boundary values
* optional arguments
* default behavior
* error conditions
* repeated calls
* state changes
* ESO API edge cases

For example:

```lua
local function testRecursiveTable()
    local t = {}
    t.self = t

    local result = formatTable(t)

    TK.assertEquals("{self=<seen>}", result,
        "recursive table reference should be detected")
end
```

## Standalone Lua Testing

TestKit can be used with a standalone Lua interpreter by providing the modules and ESO API stubs required by the code under test.

A typical test environment may load:

```lua
require "TestKit"
require "MyLibrary"
require "MyLibrary_Tests"
```

This makes it possible to run library tests repeatedly without launching ESO.

The exact setup depends on the library being tested and which ESO APIs it uses.

## Mocking ESO APIs

Code that directly depends on ESO APIs can be tested by supplying minimal mocks.

For example:

```lua
GetString = function(id)
    return "localized:" .. tostring(id)
end
```

The goal is generally **not** to reproduce the entire ESO API. Instead, provide the smallest implementation necessary for the behavior being tested.

This keeps tests fast and makes failures easier to understand.

## TestKit Philosophy

TestKit is deliberately small.

The goal is not to reproduce a large general-purpose testing framework. For ESO addon development, a useful test framework should make it easy to:

1. Write a test.
2. Run it quickly.
3. Know exactly what failed.
4. Fix the code.
5. Run the test again.

Tests should remain ordinary Lua code rather than requiring a specialized test language or extensive framework infrastructure.

## Recommended Testing Strategy

For an ESO library, tests should generally be organized around behavior rather than implementation details.

For example, instead of testing that an internal table contains a particular field, test the public behavior that depends on that field.

Prefer:

```lua
TK.assertEquals("expected", library:GetValue(), "GetValue returns value")
```

over tests that depend on private implementation details.

This makes the test suite more resilient to refactoring.

## Regression Testing

One of TestKit's primary uses is preventing previously fixed bugs from returning.

When a bug is discovered:

1. Create a test that reproduces the problem.
2. Verify that the test fails with the buggy implementation.
3. Fix the implementation.
4. Verify that the test passes.
5. Keep the test permanently.

This turns individual debugging sessions into permanent regression protection.

## Performance Testing

TestKit is primarily a unit-testing framework rather than a benchmarking framework.

Performance-sensitive ESO code can still be tested by repeatedly invoking a function and measuring execution time, but timing results should be interpreted carefully because standalone Lua execution and the ESO client do not have identical runtime characteristics.

Functional correctness should generally be established before optimizing.

## Requirements

TestKit is intended for Lua environments compatible with the Lua version used by the code being tested.

For ESO development, the standalone test environment should use a compatible Lua runtime and provide any ESO globals required by the library under test.

## Project Structure

A project using TestKit might be organized like:

```text
MyLibrary/
├── MyLibrary.lua
├── MyLibrary_Strings.lua
├── MyLibrary_Tables.lua
└── tests/
    ├── TestKit.lua
    ├── MyLibrary_Tests.lua
    └── run_tests.lua
```

The exact layout is up to the project.

## Why Test ESO Libraries Outside ESO?

Running tests in a standalone environment provides several advantages:

* Much faster iteration
* No need to repeatedly launch ESO
* Easier automated testing
* Easier debugging
* Easier regression testing
* Tests can be run as part of development tooling
* Pure Lua logic can be tested independently of the game client

ESO-specific behavior that cannot reasonably be reproduced outside the client can still be tested separately inside ESO.

## Scope

TestKit is intended primarily for:

* ESO addon development
* ESO library development
* Lua utility libraries
* Standalone unit testing of Lua code
* Regression testing

It is **not** intended to replace integration testing inside ESO. APIs involving the actual game client, UI, events, saved variables, combat systems, or other client-specific behavior may still require in-game testing.

## Contributing

Contributions are welcome.

When submitting a change:

* Keep the framework lightweight.
* Add tests for new functionality.
* Preserve existing behavior unless the change is intentional.
* Prefer simple APIs over framework complexity.
* Document behavior that may not be obvious.
* Avoid introducing dependencies when a small Lua implementation is sufficient.

## License

See the repository's `LICENSE` file for the applicable license.

## Status

TestKit is intended to be a practical development tool for ESO addon and library authors. Its API may evolve as additional testing requirements are identified through real-world addon development.
