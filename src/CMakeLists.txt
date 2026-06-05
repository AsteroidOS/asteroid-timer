add_library(asteroid-timer main.cpp)
set_target_properties(asteroid-timer PROPERTIES PREFIX "")

asteroid_app_qml_module(asteroid-timer
	main.qml
)

target_link_libraries(
	asteroid-timer
	PUBLIC
		Asteroid::AsteroidApp6
)

install(
	TARGETS asteroid-timer
	DESTINATION ${CMAKE_INSTALL_LIBDIR}
)
