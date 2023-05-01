function(check_no_import_stdlib result) 
	set(stdlib_list iostream string vector) # add the entire list of standard headers?
	cmake_parse_arguments(MOD "" "IF" "Else" ${ARGN})
	set(files ${MOD_UNPARSED_ARGUMENTS})
	set(modules)
	foreach(file ${files})
		file(READ ${file} contents)
		string(REGEX REPLACE "\n" ";" lines ${contents}) 
		foreach(line ${lines})
			string(REGEX MATCH "import.*" import ${line})
			if(NOT import STREQUAL "")
				string(REGEX REPLACE " " ";" conts ${import})
				list(GET conts 1 module)
				set(modules ${modules} ${module})
			endif()
		endforeach()
			
	endforeach()

	set(${result} FALSE PARENT_SCOPE)
	foreach(module ${modules})
		string(REGEX MATCH "\<.*\>" match ${module})
		if(NOT match STREQUAL "")
			set(${result} TRUE PARENT_SCOPE)
		endif()
		if(${module} IN_LIST stdlib_list)
			set(${result} TRUE PARENT_SCOPE)
		endif()
	endforeach()
endfunction()

function(add_module_library name)
	cmake_parse_arguments(MOD "" "IF" "Else" ${ARGN})
	set(sources ${MOD_UNPARSED_ARGUMENTS})
	check_no_import_stdlib(has_stdheaders ${sources})
	if (CMAKE_CXX_COMPILER_ID MATCHES "Clang")
		set(CMAKE_CXX_EXTENSIONS OFF PARENT_SCOPE)
		if(has_stdheaders)
			message(FATAL_ERROR "idk how to suppport standard headers with Clang yet, please use GCC")
		endif()
	endif()
		
	add_library(${name})
	set_target_properties(${name} PROPERTIES LINKER_LANGUAGE CXX)
	target_compile_features(${name} PUBLIC cxx_std_20)
		
	if (CMAKE_CXX_COMPILER_ID MATCHES "GNU")
		target_compile_options(${name} PUBLIC -std=c++20 -fmodules-ts)
		target_sources(${name} PUBLIC ${sources})
		set(CXX_GCC_MODULE_FLAGS -std=c++20 -fmodules-ts PARENT_SCOPE)
		return()
	endif()

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
