

function(echo_all_cmake_variable_values)
  message(STATUS “”)
  get_cmake_property(vs VARIABLES)
  foreach(v ${vs})
    message(STATUS “${v}=’${${v}}'”)
  endforeach(v)
  message(STATUS “”)
endfunction()

## check, find or fetch package
## useful to bruteforce dependency (abstraction over the source)
## defines ${NAME}_TARGET with a valid target
## @note consider using ther User Package Registry (cross-plaform, creates system-wide info about packages and their config files); may not be the best option when actually installing packages as catkin does
function(search_for_package NAME URL BRANCH)
    # message(WARNING "${ALFACE}")
    ## mplearn dependencies are propagated to target variable
    if (TARGET ${NAME})
        ## if in the build tree / being built
        ## target name does not require namespace
        # set(${NAME}_TARGET ${NAME} PARENT_SCOPE)
        set(${NAME}_TARGET ${NAME} CACHE INTERNAL ${NAME})
        message(STATUS "${NAME} found in the build tree!")
    else ()
        find_package(${NAME} QUIET)
        if (${${NAME}_FOUND})
            message(STATUS "${NAME} FOUND!")
            ## if installed, target name is prefixed by the namespace
            # set(${NAME}_TARGET ${NAME}::${NAME} PARENT_SCOPE)
            # set(${NAME}_TARGET ${NAME}::${NAME} CACHE INTERNAL ${NAME}::${NAME})
            # 1. check if name is a target
            if (TARGET ${NAME})
                set(${NAME}_TARGET ${NAME} CACHE INTERNAL ${NAME})
            else()
                if (DEFINED ARGV3)
                    # prepend with given namespace
                    set(${NAME}_TARGET ${ARGV3}::${NAME} CACHE INTERNAL ${ARGV3}::${NAME})
                else()
                    # prepend with target name (common)
                    set(${NAME}_TARGET ${NAME}::${NAME} CACHE INTERNAL ${NAME}::${NAME})
                endif()
            endif()
            # if (DEFINED ARGV3)
            #     message(WARNING "Setting target name to ${ARGV3}")
            #     set(${NAME}_TARGET ${CONFIG_TARGET} CACHE INTERNAL ${CONFIG_TARGET})
            # else()
            #     set(${NAME}_TARGET ${NAME}::${NAME} CACHE INTERNAL ${NAME}::${NAME})
            # endif()
        else()
            message(STATUS "${NAME} NOT FOUND, fetching from source!")
            FetchContent_Declare(${NAME}
                GIT_REPOSITORY  ${URL}
                GIT_TAG         ${BRANCH}
            )
            FetchContent_MakeAvailable(${NAME})
            install(
                TARGETS ${NAME}
                EXPORT ${PROJECT_NAME}Targets
                # More arguments as necessary...
            )
            message("Targets from ${NAME}: ${${NAME}Targets}")
            ## if fetched, the source tree is consumed
            # set(${NAME}_TARGET ${NAME} PARENT_SCOPE)
            set(${NAME}_TARGET ${NAME} CACHE INTERNAL ${NAME})
        endif()
    endif()
    ## check if valid target
    if (NOT TARGET ${${NAME}_TARGET})
        message(FATAL_ERROR "Unable to find a target for ${NAME} [${${NAME}_TARGET}]")
    endif()

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

