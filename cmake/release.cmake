# Copyright (C) 2008-2014,2018 LAAS-CNRS, JRL AIST-CNRS.
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# this program.  If not, see <http://www.gnu.org/licenses/>.

# .rst: .. command:: RELEASE_SETUP
#
# .. _target-release:
#
# This adds a *release* target which release a stable version of the current
# package.
#
# To release a package, please run:
#
# .. code-block:: bash
#
# make release VERSION=X.Y.Z
#
# where ``X.Y.Z`` is the version number of your new package.
#
# A release consists in:
#
# * adding a signed tag following the ``vVERSION`` pattern.
# * running ``make distcheck`` (:ref:`distcheck <target-distcheck>`) to make
#   sure everything is ok.
# * running ``make dist`` to generate a tarball
# * running ``make distclean`` to remove the current dist directory
# * reminds that you should push the tag and tarball on the GitHub repository
#   (to be done manually as it is simple but cannot be reverted).
#
# .. todo::
#
# The following steps are missing to the current release procedure:
#
# * uploading the stable documentation.
# * uploading the resulting tarball to GitHub.
# * announce the release by e-mail.
#
macro(RELEASE_SETUP)
  if(UNIX)
    find_program(GIT git)

    # Set LD_LIBRARY_PATH
    if(APPLE)
      set(LD_LIBRARY_PATH_VARIABLE_NAME "DYLD_LIBRARY_PATH")
    else(APPLE)
      set(LD_LIBRARY_PATH_VARIABLE_NAME "LD_LIBRARY_PATH")
    endif(APPLE)

    add_custom_target(
      release
      COMMAND
        export LD_LIBRARY_PATH=$ENV{LD_LIBRARY_PATH} && export
        ${LD_LIBRARY_PATH_VARIABLE_NAME}=$ENV{${LD_LIBRARY_PATH_VARIABLE_NAME}}
        && export PYTHONPATH=$ENV{PYTHONPATH} && ! test x$$VERSION = x ||
        (echo "Please set a version for this release" && false) && cd
        ${PROJECT_SOURCE_DIR}
        # Update version in package.xml if it exists
        && if [ -f "package.xml" ]; then
        (echo
         "Updating package.xml to $$VERSION"
         &&
         sed
         -i.back
         \"s|<version>.*</version>|<version>$$VERSION</version>|g\"
         package.xml
         &&
         rm
         package.xml.back
         &&
         ${GIT}
         add
         package.xml
         &&
         ${GIT}
         commit
         -m
         "release: Update package.xml version to $$VERSION"
         &&
         echo
         "Updated package.xml and committed") ; fi
        # Update version in pyproject.toml if it exists
        && if [ -f "pyproject.toml" ]; then
        (echo
         "Updating pyproject.toml to $$VERSION"
         &&
         ${PYTHON_EXECUTABLE}
         ${PROJECT_JRL_CMAKE_MODULE_DIR}/pyproject.py
         $$VERSION
         &&
         ${GIT}
         add
         pyproject.toml
         &&
         ${GIT}
         commit
         -m
         "release: Update pyproject.toml version to $$VERSION"
         &&
         echo
         "Updated pyproject.toml and committed") ; fi && ${GIT} tag -s
        v$$VERSION -m "Release of version $$VERSION." && cd ${CMAKE_BINARY_DIR}
        && cmake ${PROJECT_SOURCE_DIR} && make distcheck ||
        (echo
         "Please fix distcheck first."
         &&
         cd
         ${PROJECT_SOURCE_DIR}
         &&
         ${GIT}
         tag
         -d
         v$$VERSION
         &&
         cd
         ${CMAKE_BINARY_DIR}
         &&
         cmake
         ${PROJECT_SOURCE_DIR}
         &&
         false) && make dist && make distclean && echo
        "Please, run 'git push --tags' and upload the tarball to github to finalize this release."
    )
  endif()
endmacro()
