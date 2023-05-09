add_library(asteroid-timer main.cpp resources.qrc)
set_target_properties(asteroid-timer PROPERTIES PREFIX "")

target_link_libraries(asteroid-timer PUBLIC
	AsteroidApp)

install(TARGETS asteroid-timer
	DESTINATION ${CMAKE_INSTALL_LIBDIR})
