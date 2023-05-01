# TODO make it compatible with GCC
# now only works for clang
function(add_module_library name)
	if (CMAKE_CXX_COMPILER_ID MATCHES "Clang")
		set(CMAKE_CXX_EXTENSIONS OFF PARENT_SCOPE)
	endif()
	cmake_parse_arguments(MOD "" "IF" "Else" ${ARGN})
	set(sources ${MOD_UNPARSED_ARGUMENTS})
	add_library(${name})
	set_target_properties(${name} PROPERTIES LINKER_LANGUAGE CXX)
	target_compile_features(${name} PUBLIC cxx_std_20)
	set(pcms)
	foreach(src ${sources})
		get_filename_component(pcm ${src} NAME_WE)
		set(pcm ${pcm}.pcm)
		target_compile_options(
		${name} PUBLIC -fmodule-file=${CMAKE_CURRENT_BINARY_DIR}/${pcm})
		
		set(pcms ${pcms} ${CMAKE_CURRENT_BINARY_DIR}/${pcm})
	 	add_custom_command(
			OUTPUT ${pcm}
			COMMAND ${CMAKE_CXX_COMPILER} -std=c++20 -x c++-module --precompile -c -o ${pcm} ${CMAKE_CURRENT_SOURCE_DIR}/${src}
			COMMAND_EXPAND_LISTS
			DEPENDS ${src}
		)
	endforeach()
	set(sources)
	foreach(pcm ${pcms})
		get_filename_component(obj ${pcm} NAME_WE)
		set(obj ${obj}.o)
		set(sources ${sources} ${pcm} ${CMAKE_CURRENT_BINARY_DIR}/${obj})
		add_custom_command(
			OUTPUT ${obj}
			COMMAND ${CMAKE_CXX_COMPILER} -c -o ${obj} ${pcm}
			DEPENDS ${pcm})
	endforeach()
	target_sources(${name} PRIVATE ${sources})
endfunction()
