weather_sources = [
  'main.vala',
  'application.vala',
  'window.vala',
]

weather_deps = [
  dependency('gtk4'),
  dependency('libadwaita-1', version: '>= 1.2'),
  dependency('gweather4'),
  dependency('libgeoclue-2.0')
]

weather_sources += gnome.compile_resources('weather-resources',
  'weather.gresource.xml',
  c_name: 'weather'
)

executable('weather', weather_sources,
  dependencies: weather_deps,
       install: true,
)
