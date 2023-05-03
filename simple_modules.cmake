set(GENERIC_CXX_MODULE_FLAGS -std=c++20 -fmodules-ts -xc++-system-header)
set(GCM_CACHE gcm.cache/usr/include/c++/12.2.1)

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
	set(std_modules ${modules} PARENT_SCOPE)
endfunction()

function(add_stdheader_gcm)
	cmake_parse_arguments(MOD "" "IF" "Else" ${ARGN})
	set(source ${MOD_UNPARSED_ARGUMENTS})
	check_no_import_stdlib(has_stdimport ${source})
	set(STD_HEADERS_BUILT FALSE PARENT_SCOPE)
	if(CMAKE_CXX_COMPILER_ID MATCHES "GNU")
		set(CMAKE_CXX_EXTENSIONS OFF PARENT_SCOPE)
		list(LENGTH std_modules len_std_modules)	
		if(len_std_modules GREATER 0)
			foreach(std_module ${std_modules})
				string(REGEX MATCH "\<.*\>" match ${std_module})
				if(NOT match STREQUAL "")
					string(REGEX MATCH "[a-z]+" module ${std_module})
					add_custom_target(${module} ALL)
					add_custom_command(
						TARGET ${module}
						COMMAND ${CMAKE_CXX_COMPILER} ${GENERIC_CXX_MODULE_FLAGS} ${module}
					)
				endif()
			endforeach()
			set(STD_HEADERS_BUILT TRUE PARENT_SCOPE)
		endif()
	elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
		message(FATAL_ERROR "std modules with Clang is not supported yet")
	endif()
endfunction()

function(add_stdmodular_executable name)
	cmake_parse_arguments(MOD "" "IF" "Else" ${ARGN})
	set(source ${MOD_UNPARSED_ARGUMENTS})
	if(NOT STD_HEADERS_BUILT)
		add_stdheader_gcm(${source})	
	endif()
	add_executable(${name} ${source})
	target_compile_options(${name} PUBLIC -std=c++20 -fmodules-ts)
endfunction()


function(add_module_library name)
	cmake_parse_arguments(MOD "" "IF" "Else" ${ARGN})
	set(sources ${MOD_UNPARSED_ARGUMENTS})
	if (CMAKE_CXX_COMPILER_ID MATCHES "Clang")
		set(CMAKE_CXX_EXTENSIONS OFF PARENT_SCOPE)
		if(has_stdheaders)
			message(FATAL_ERROR "idk how to suppport standard headers with Clang yet, please use GCC")
		endif()
	endif()

	if(NOT STD_HEADERS_BUILT)
		add_stdheader_gcm(${sources})	
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
