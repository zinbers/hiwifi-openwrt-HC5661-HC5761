# - Find CxxTest
# Find the CxxTest suite and declare a helper macro for creating unit tests
# and integrating them with CTest.
# For more details on CxxTest see http://cxxtest.tigris.org
#
# INPUT Variables
#
#   CXXTEST_USE_PYTHON [deprecated since 1.3]
#       Only used in the case both Python & Perl
#       are detected on the system to control
#       which CxxTest code generator is used.
#       Valid only for CxxTest version 3.
#
#       NOTE: In older versions of this Find Module,
#       this variable controlled if the Python test
#       generator was used instead of the Perl one,
#       regardless of which scripting language the
#       user had installed.
#
#   CXXTEST_TESTGEN_ARGS (since CMake 2.8.3)
#       Specify a list of options to pass to the CxxTest code
#       generator.  If not defined, --error-printer is
#       passed.
#
# OUTPUT Variables
#
#   CXXTEST_FOUND
#       True if the CxxTest framework was found
#   CXXTEST_INCLUDE_DIRS
#       Where to find the CxxTest include directory
#   CXXTEST_PERL_TESTGEN_EXECUTABLE
#       The perl-based test generator
#   CXXTEST_PYTHON_TESTGEN_EXECUTABLE
#       The python-based test generator
#   CXXTEST_TESTGEN_EXECUTABLE (since CMake 2.8.3)
#       The test generator that is actually used (chosen using user preferences
#       and interpreters found in the system)
#   CXXTEST_TESTGEN_INTERPRETER (since CMake 2.8.3)
#       The full path to the Perl or Python executable on the system
#
# MACROS for optional use by CMake users:
#
#    CXXTEST_ADD_TEST(<test_name> <gen_source_file> <input_files_to_testgen...>)
#       Creates a CxxTest runner and adds it to the CTest testing suite
#       Parameters:
#           test_name               The name of the test
#           gen_source_file         The generated source filename to be
#                                   generated by CxxTest
#           input_files_to_testgen  The list of header files containing the
#                                   CxxTest::TestSuite's to be included in
#                                   this runner
#           
#       #==============
#       Example Usage:
#
#           find_package(CxxTest)
#           if(CXXTEST_FOUND)
#               include_directories(${CXXTEST_INCLUDE_DIR})
#               enable_testing()
#
#               CXXTEST_ADD_TEST(unittest_foo foo_test.cc
#                                 ${CMAKE_CURRENT_SOURCE_DIR}/foo_test.h)
#               target_link_libraries(unittest_foo foo) # as needed
#           endif()
#
#              This will (if CxxTest is found):
#              1. Invoke the testgen executable to autogenerate foo_test.cc in the
#                 binary tree from "foo_test.h" in the current source directory.
#              2. Create an executable and test called unittest_foo.
#               
#      #=============
#      Example foo_test.h:
#
#          #include <cxxtest/TestSuite.h>
#          
#          class MyTestSuite : public CxxTest::TestSuite 
#          {
#          public:
#             void testAddition( void )
#             {
#                TS_ASSERT( 1 + 1 > 1 );
#                TS_ASSERT_EQUALS( 1 + 1, 2 );
#             }
#          };
#

#=============================================================================
# Copyright 2008-2010 Kitware, Inc.
# Copyright 2008-2010 Philip Lowman <philip@yhbt.com>
#
# Distributed under the OSI-approved BSD License (the "License");
# see accompanying file Copyright.txt for details.
#
# This software is distributed WITHOUT ANY WARRANTY; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the License for more information.
#=============================================================================
# (To distribute this file outside of CMake, substitute the full
#  License text for the above reference.)

# Version 1.4 (11/18/10) (CMake 2.8.4)
#     Issue 11384: Added support to the CXX_ADD_TEST macro so header
#                  files (containing the tests themselves) show up in
#                  Visual Studio and other IDEs.
#
# Version 1.3 (8/19/10) (CMake 2.8.3)
#     Included patch by Simone Rossetto to check if either Python or Perl
#     are present in the system.  Whichever intepreter that is detected
#     is now used to run the test generator program.  If both interpreters
#     are detected, the CXXTEST_USE_PYTHON variable is obeyed.
#
#     Also added support for CXXTEST_TESTGEN_ARGS, for manually specifying
#     options to the CxxTest code generator.
# Version 1.2 (3/2/08)
#     Included patch from Tyler Roscoe to have the perl & python binaries
#     detected based on CXXTEST_INCLUDE_DIR
# Version 1.1 (2/9/08)
#     Clarified example to illustrate need to call target_link_libraries()
#     Changed commands to lowercase
#     Added licensing info
# Version 1.0 (1/8/08)
#     Fixed CXXTEST_INCLUDE_DIRS so it will work properly
#     Eliminated superfluous CXXTEST_FOUND assignment
#     Cleaned up and added more documentation

#=============================================================
# CXXTEST_ADD_TEST (public macro)
#=============================================================
macro(CXXTEST_ADD_TEST _cxxtest_testname _cxxtest_outfname)
    set(_cxxtest_real_outfname ${CMAKE_CURRENT_BINARY_DIR}/${_cxxtest_outfname})

    add_custom_command(
        OUTPUT  ${_cxxtest_real_outfname}
        DEPENDS ${ARGN}
        COMMAND ${CXXTEST_TESTGEN_INTERPRETER}
        ${CXXTEST_TESTGEN_EXECUTABLE} ${CXXTEST_TESTGEN_ARGS} -o ${_cxxtest_real_outfname} ${ARGN}
    )

    set_source_files_properties(${_cxxtest_real_outfname} PROPERTIES GENERATED true)
    add_executable(${_cxxtest_testname} ${_cxxtest_real_outfname} ${ARGN})

    if(CMAKE_RUNTIME_OUTPUT_DIRECTORY)
        add_test(${_cxxtest_testname} ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${_cxxtest_testname})
    elseif(EXECUTABLE_OUTPUT_PATH)
        add_test(${_cxxtest_testname} ${EXECUTABLE_OUTPUT_PATH}/${_cxxtest_testname})
    else()
        add_test(${_cxxtest_testname} ${CMAKE_CURRENT_BINARY_DIR}/${_cxxtest_testname})
    endif()

endmacro(CXXTEST_ADD_TEST)

#=============================================================
# main()
#=============================================================
if(NOT DEFINED CXXTEST_TESTGEN_ARGS)
   set(CXXTEST_TESTGEN_ARGS --error-printer)
endif()

find_package(PythonInterp QUIET)
find_package(Perl QUIET)

find_path(CXXTEST_INCLUDE_DIR cxxtest/TestSuite.h)
find_program(CXXTEST_PYTHON_TESTGEN_EXECUTABLE
         NAMES cxxtestgen cxxtestgen.py
         PATHS ${CXXTEST_INCLUDE_DIR})
find_program(CXXTEST_PERL_TESTGEN_EXECUTABLE cxxtestgen.pl
         PATHS ${CXXTEST_INCLUDE_DIR})

if(PYTHONINTERP_FOUND OR PERL_FOUND)
   include(${CMAKE_CURRENT_LIST_DIR}/FindPackageHandleStandardArgs.cmake)

   if(PYTHONINTERP_FOUND AND (CXXTEST_USE_PYTHON OR NOT PERL_FOUND OR NOT DEFINED CXXTEST_USE_PYTHON))
      set(CXXTEST_TESTGEN_EXECUTABLE ${CXXTEST_PYTHON_TESTGEN_EXECUTABLE})
      set(CXXTEST_TESTGEN_INTERPRETER ${PYTHON_EXECUTABLE})
      FIND_PACKAGE_HANDLE_STANDARD_ARGS(CxxTest DEFAULT_MSG
          CXXTEST_INCLUDE_DIR CXXTEST_PYTHON_TESTGEN_EXECUTABLE)

   elseif(PERL_FOUND)
      set(CXXTEST_TESTGEN_EXECUTABLE ${CXXTEST_PERL_TESTGEN_EXECUTABLE})
      set(CXXTEST_TESTGEN_INTERPRETER ${PERL_EXECUTABLE})
      FIND_PACKAGE_HANDLE_STANDARD_ARGS(CxxTest DEFAULT_MSG
          CXXTEST_INCLUDE_DIR CXXTEST_PERL_TESTGEN_EXECUTABLE)
   endif()

   if(CXXTEST_FOUND)
      set(CXXTEST_INCLUDE_DIRS ${CXXTEST_INCLUDE_DIR})
   endif()

else()

   set(CXXTEST_FOUND false)
   if(NOT CxxTest_FIND_QUIETLY)
      if(CxxTest_FIND_REQUIRED)
         message(FATAL_ERROR "Neither Python nor Perl found, cannot use CxxTest, aborting!")
      else()
         message(STATUS "Neither Python nor Perl found, CxxTest will not be used.")
      endif()
   endif()

endif()