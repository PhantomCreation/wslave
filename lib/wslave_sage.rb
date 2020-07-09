require 'yaml'

class WSlaveSage
  attr_reader :theme_name

  def initialize()
    @theme_name = ''
  end

  def create(name)
    unless File.exist?("./config/.wslave")
      puts "This command must be run in the root of a WSlave setup"
    end

    name = 'wslave-sage-theme' if name.empty?
    project_root = Dir.pwd

    puts "Creating Sage theme at public/wp-content/themes/#{name}"
    `cd public/wp-content/themes && composer create-project roots/sage #{name} dev-master`

    Dir.chdir project_root
    _write_wslave_sage_config(name)
    _overwrite_sage_webpack_browsersync_config
  end

  def update()
    return unless _check()
    system("cd public/wp-content/themes/#{@theme_name} && yarn && yarn build")
  end

  def dev()
    return unless _check()
    system("cd public/wp-content/themes/#{@theme_name} && yarn start")
  end

  def build()
    return unless _check()
    system("cd public/wp-content/themes/#{@theme_name} && yarn build")
  end

  def production()
    return unless _check()
    system("cd public/wp-content/themes/#{@theme_name} && yarn build:production")
  end

  def theme_name?()
    return '' unless _check()
    @theme_name
  end

  def _write_wslave_sage_config(name)
    File.open("./config/sage.yml", 'w') {|f| YAML.dump({theme: name}, f)}
  end

  def _overwrite_sage_webpack_browsersync_config
    return unless _check()
    theme_info = YAML.load_file("./config/sage.yml")
    Dir.chdir "#{Dir.pwd}/public/wp-content/themes/#{theme_info[:theme]}"

    webpack_config_path = './webpack.mix.js'
    new_webpack_config = File.read(webpack_config_path).gsub(
      /browserSync\('sage.test'\)/, "browserSync('localhost:8000')"
    )
    File.open(webpack_config_path, 'w') { |f| f.puts new_webpack_config }
  end

  def _check()
    if (File.exist?("./config/.wslave") && File.exist?("./config/sage.yml"))
      theme_info = YAML.load_file("./config/sage.yml")
      @theme_name = theme_info[:theme]
      return true
    end
    puts "This does not appear to be the root of a WSlave managed app with a Sage theme."
    false
  end
end
