# Standalone lit configuration for the vendored TSan IR tests.
#
# The tests in this directory are copied verbatim from
# llvm/test/Instrumentation/ThreadSanitizerNew/ in the branch this artifact's
# compiler is built from. They need only `opt`, `FileCheck`, `llvm-link` and
# `count`; none carries a REQUIRES: line. That is why this config can be a
# dozen lines instead of inheriting llvm/test/lit.cfg.py, which would drag in
# a build-generated lit.site.cfg.py that the artifact image does not have.
import os
import lit.formats

config.name = "TSanAnalysesIR"
config.test_format = lit.formats.ShTest(True)
config.suffixes = [".ll"]
config.test_source_root = os.path.dirname(__file__)
config.test_exec_root = os.environ.get("ART_LIT_EXEC_ROOT", config.test_source_root)

# Tool directory: the artifact's install prefix inside the container, or whatever
# TSAN_LLVM_ROOT points at on a host checkout.
bindir = os.path.join(os.environ.get("TSAN_LLVM_ROOT", "/opt/tsan-llvm"), "bin")
# Resolve tools through PATH, NOT through name substitutions. A substitution on the bare
# word `count` rewrites the `count` inside the flag -tsan-use-active-thread-count, because
# \b treats '-' as a word boundary; that turned a passing test into a failure that looked
# like a compiler regression. PATH has no such failure mode.
config.environment["PATH"] = bindir + os.pathsep + os.environ.get("PATH", "")
