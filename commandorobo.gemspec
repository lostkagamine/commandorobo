Gem::Specification.new do |s|
	s.name = 'commandorobo'
	s.version = '0.0.6'
	s.date = '2018-03-25'
	s.summary = 'Command framework for discordrb'
	s.description = 'A command framework for discordrb.'
	s.authors = ['ry00001']
	s.email = 'ry00001@protonmail.com'
	s.files = Dir['lib/**/*.*']
	s.homepage = 'https://github.com/ry00001/commandorobo'
	s.license = 'MIT'
	s.add_runtime_dependency 'discordrb', '~> 3.1', '>= 3.1.0'
	s.required_ruby_version = '>= 2.2.4'
end
