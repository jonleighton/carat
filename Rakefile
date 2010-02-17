require File.dirname(__FILE__) + "/lib/carat"

task :compile_kernel do
  Carat::Runtime::KernelLoader::LOAD_ORDER.each do |code_file|
    code = File.read(Carat::KERNEL_PATH + "/#{code_file}.carat")
    ast = Carat::LanguageParser.new(code, Carat::KERNEL_PATH + "/#{code_file}.carat").ast
    File.open(Carat::KERNEL_PATH + "/#{code_file}.marshal", "w+") do |file|
      file.write(Marshal.dump(ast))
    end
  end
end

task :spec do
  system "bin/cspec spec/all.carat"
end

task :default => :spec

task :sloccount do
  files = Rake::FileList['lib/**/*.rb', 'lib/**/*.treetop'].
            exclude('lib/parser/language.rb',
                    'lib/parser/comment.rb')
  system "sloccount", *files
end
