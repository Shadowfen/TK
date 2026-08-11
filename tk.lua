--[[ TestKit - Lightweight Lua unit testing utility.

     TestKit provides a minimal assertion framework and result tracking system
     intended for debugging and validating Lua modules in addon environments.

     It supports:
        - Simple pass/fail assertions
        - Suite-level reporting
        - Basic localization string hooks
        - Lightweight test counters

     Typical usage flow:

        TK.init()

        TK.assertTrue(condition, "Test name")
        TK.assertFalse(condition, "Test name")
        TK.assertEquals(lvalue, rvalue, "Test name")
        TK.assertNotEquals(lvalue, rvalue, "Test name")
        TK.assertEqual(lvalue, rvalue, "Test name")
        TK.assertNotEqual(lvalue, rvalue, "Test name")
        TK.assertNil(value, "Test name")
        TK.assertNotNil(value, "Test name")

        TK.showResult("MySuite")

     ---------------------------------------------------------------------------
     DATA FIELDS
     ---------------------------------------------------------------------------

     num_tests:
        Total number of assertions executed

     pass:
        Number of successful assertions

     fail:
        Number of failed assertions

     localization_strings:
        Table of UI/output strings used for formatting test output:
            UNKNOWN_STRING
            SUITE_RESULTS
            TK_RESULTS
            TESTS_RUN
            PASS
            FAIL

     ---------------------------------------------------------------------------
     CORE FUNCTIONS
     ---------------------------------------------------------------------------

     TK.init()
        Resets all counters (num_tests, pass, fail) to zero.

     TK.showResult(suitename)
        Prints summary results.
        If suitename is provided, prints suite header instead of global header.

     TK.printSuite(moduleName, fn)
        Prints a formatted suite header for grouping tests.

     TK.assertTrue(c, tname)
        Passes if condition is true.

     TK.assertFalse(c, tname)
        Passes if condition is false.

     TK.assertNil(c, tname)
        Passes if value is nil.

     TK.assertNotNil(c, tname)
        Passes if value is not nil.

     TK.listcount(tbl)
        Returns number of key-value pairs in a table (non-array safe count).

     ---------------------------------------------------------------------------
     INTERNAL HELPERS
     ---------------------------------------------------------------------------

     local d(...)
        Wrapper around print() used for output abstraction.

     ---------------------------------------------------------------------------
     NOTES
     ---------------------------------------------------------------------------

     - This framework is intentionally minimal and does not support:
         * async tests
         * setup/teardown hooks
         * deep equality checks
         * test filtering or tagging
     - Designed for quick validation in addon development environments.
--]]
TestKit = {
  num_tests=0,
  pass = 0,
  fail = 0,  
}

local TK = TestKit

TK.localization_strings = {
  UNKNOWN_STRING = "Unknown localization string",
  SUITE_RESULTS = " results:",
  TK_RESULTS = "TestKit results:",
  TESTS_RUN = "Number of tests run: ",
  PASS = "PASSED: ",
  FAIL = "FAILED: ",
  
}
local ls = TK.localization_strings

local function d(...)
    print(...)
end

function TK.printSuite(moduleName, fn)
    print("\n"..moduleName.."_"..fn..":\n")
end

function TK.init()
  TK.num_tests = 0
  TK.pass = 0
  TK.fail = 0
end

function TK.showResult(suitename)
  if( suitename ) then
    d("\n"..suitename..ls.SUITE_RESULTS)
  else
    d("\n"..ls.TK_RESULTS)
  end
  d(string.format("  %-25s %d",ls.TESTS_RUN, TK.num_tests))
  d(string.format("  %-25s %d",ls.PASS, TK.pass))
  d(string.format("  %-25s %d",ls.FAIL, TK.fail))
end
  
  
-- Helper: Compare primitive values and shallow tables.
-- Nested tables are compared by reference.
local function ValueEqual(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) == "table" then
        -- Shallow check for this context; adjust if deep equality is strictly required
        local aKeys, bKeys = {}, {}
        for k, v in pairs(a) do aKeys[k] = true end
        for k, v in pairs(b) do bKeys[k] = true end
        
        if TK.listcount(aKeys) ~= TK.listcount(bKeys) then return false end
        for k, _ in pairs(aKeys) do
            if not bKeys[k] or a[k] ~= b[k] then return false end
        end
        return true
    end
    return a == b
end

local function report(success, name)
    TK.num_tests = TK.num_tests + 1

    if success then
        TK.pass = TK.pass + 1
        d(string.format("%-10s%s", ls.PASS, name))
    else
        TK.fail = TK.fail + 1
        d(string.format("%-10s%s", ls.FAIL, name))
    end
end

function TK.assertTrue(value, name)
    report(value, name)
end

function TK.assertFalse(value, name)
    report(not value, name)
end

function TK.assertNil(value, name)
    report(value == nil, name)
end

function TK.assertNotNil(value, name)
    report(value ~= nil, name)
end

function TK.assertEquals(expected, actual, name)
    report(ValueEqual(expected, actual), name)
end
function TK.assertNotEquals(expected, actual, name)
    report(not ValueEqual(expected, actual), name)
end

TK.assertEqual = TK.assertEquals
TK.assertNotEqual = TK.assertNotEquals

function TK.listcount(tbl)
    local i = 0
    for k,v in pairs(tbl) do
        i = i + 1
    end
    return i
end

