"""Tests for scripts in the Tools/scripts directory.

This file contains extremely basic regression tests for the scripts found in
the Tools directory of a Python checkout or tarball which don't have separate
tests of their own.
"""

import os
import unittest
from test.support import import_helper

from test.test_tools import scriptsdir, import_tool, skip_if_missing

skip_if_missing()

class TestSundryScripts(unittest.TestCase):
    # At least make sure the rest don't have syntax errors.  When tests are
    # added for a script it should be added to the allowlist below.

    skiplist = ['2to3']

    # import logging registers "atfork" functions which keep indirectly the
    # logging module dictionary alive. Mock the function to be able to unload
    # cleanly the logging module.
    @import_helper.mock_register_at_fork
    def test_sundry(self, mock_os):
        old_modules = import_helper.modules_setup()
        try:
            for fn in os.listdir(scriptsdir):
                if not fn.endswith('.py'):
                    continue

                name = fn[:-3]
                if name in self.skiplist:
                    continue

                import_tool(name)
        finally:
            # Unload all modules loaded in this test
            import_helper.modules_cleanup(*old_modules)


if __name__ == '__main__':
    unittest.main()
