# Standalone site configuration for the vendored compiler-rt TSan tests.
#
# The build-generated original hardcodes absolute paths into the build tree it came from.
# This one derives everything from TSAN_LLVM_ROOT (the artifact's install prefix) and the
# location of this file, so the suite runs against the shipped compiler with no build tree.
import os

_here = os.path.dirname(os.path.abspath(__file__))
_tests = os.path.dirname(_here)
_root = os.environ.get("TSAN_LLVM_ROOT", "/opt/tsan-llvm")

config.name_suffix = "-x86_64-linux"
config.tsan_lit_source_dir = _here
config.has_libcxx = False
config.apple_platform = "osx"
config.apple_platform_min_deployment_target_flag = ""
config.target_cflags = "-m64 -msse4.2 "
config.target_arch = "x86_64"
config.deflake_threshold = "10"
config.tsan_eviction_stats = False

config.test_exec_root = os.environ.get("ART_LIT_EXEC_ROOT", _here)

lit_config.load_config(config, os.path.join(_tests, "lit.common.configured"))

lit_config.load_config(config, os.path.join(_here, "lit.cfg.py"))
