
## print all current/available variables
function(echo_all_cmake_variable_values)
    message(STATUS “”)
    get_cmake_property(vs VARIABLES)
    foreach(v ${vs})
        message(STATUS “${v}=’${${v}}'”)
    endforeach(v)
    message(STATUS “”)
endfunction()

## check if given NAME is a target alias, and return aliased target
function(check_if_alias NAME)
    get_property(ALIASED TARGET "${NAME}" PROPERTY ALIASED_TARGET)
    if("${ALIASED}" STREQUAL "")
        message(WARNING "${NAME} is not an alias")
        # return(${NAME})
    else()
        message(WARNING "${NAME} is an alias of ${ALIASED}")
        # return(${ALIASED})
    endif()
endfunction()

## check, find or fetch package
## useful to bruteforce dependency (abstraction over the source)
## defines ${NAME}_TARGET with a valid target/alias
## @note consider using ther User Package Registry (cross-plaform, creates system-wide info about packages and their config files); may not be the best option when actually installing packages as catkin does
include(FetchContent)
function(search_for_package NAME URL BRANCH)
    # message(WARNING "Searching for ${PROJECT_NAME}")
    if (TARGET ${NAME})
        ## if in the build tree / being built
        ## target name does not require namespace
        # set(${NAME}_TARGET ${NAME} PARENT_SCOPE)
        set(${NAME}_TARGET ${NAME} CACHE INTERNAL ${NAME})
        message(STATUS "${NAME} found in the build tree!")
    else ()
        find_package(${NAME} QUIET)
        if (${${NAME}_FOUND})
            message(STATUS "Found ${NAME} [${${NAME}_VERSION}]")
            ## if installed, target name is prefixed by the namespace
            # 1. check if name is a target (in install/export tree)
            #    differs from top-level condition as it handles the result of find_package
            if (TARGET ${NAME})
                set(${NAME}_TARGET ${NAME} CACHE INTERNAL ${NAME})
            else()
                if (DEFINED ARGV3)
                    # specify target
                    set(${NAME}_TARGET ${NAME}::${ARGV3} CACHE INTERNAL ${NAME}::${ARGV3})
                else()
                    # prepend with target name as namespace (common usage)
                    set(${NAME}_TARGET ${NAME}::${NAME} CACHE INTERNAL ${NAME}::${NAME})
                endif()
            endif()
        else()
            message(STATUS "Can't find ${NAME}, fetching from source [${URL}:${BRANCH}]")
            FetchContent_Declare(${NAME}
                GIT_REPOSITORY  ${URL}
                GIT_TAG         ${BRANCH}
            )
            FetchContent_MakeAvailable(${NAME})
            # define install behavior
            ## @note exporting dependencies leads to issue https://discourse.cmake.org/t/how-to-export-target-which-depends-on-other-target-which-is-in-multiple-export-sets/3007/2
            if (DEFINED ARGV3)
                install(TARGETS ${ARGV3})  # EXPORT ${PROJECT_NAME}Targets
                # define target name
                set(${NAME}_TARGET ${NAME}::${ARGV3} CACHE INTERNAL ${NAME}::${ARGV3})
            else()
                install(TARGETS ${NAME})   # EXPORT ${PROJECT_NAME}Targets
                # define target name
                set(${NAME}_TARGET ${NAME} CACHE INTERNAL ${NAME})
            endif()
        endif()
    endif()
    ## check if valid target
    if (NOT TARGET ${${NAME}_TARGET})
        message(FATAL_ERROR "Unable to find a valid target for ${NAME} [${${NAME}_TARGET}]")
    endif()
    ## set imported flag
    get_target_property(${NAME}_IMPORTED ${${NAME}_TARGET} IMPORTED)
    set(${NAME}_IMPORTED "${${NAME}_IMPORTED}" CACHE INTERNAL "${${NAME}_IMPORTED}")
    # message(WARNING "${${NAME}_IMPORTED}")
endfunction()

# populate a variable with all targets in build tree
# cf. https://discourse.cmake.org/t/cmake-list-of-all-project-targets/1077/16
function (get_all_cmake_targets out_var current_dir)
    get_property(targets DIRECTORY ${current_dir} PROPERTY BUILDSYSTEM_TARGETS)
    get_property(subdirs DIRECTORY ${current_dir} PROPERTY SUBDIRECTORIES)

    foreach(subdir ${subdirs})
        get_all_cmake_targets(subdir_targets ${subdir})
        list(APPEND targets ${subdir_targets})
    endforeach()

    set(${out_var} ${targets} PARENT_SCOPE)
endfunction()

function (print_all_cmake_targets)
    get_all_cmake_targets(all_targets ${CMAKE_CURRENT_LIST_DIR})
    list(LENGTH all_targets sz)
    message(WARNING "${sz} targets: ${all_targets}")
endfunction()

