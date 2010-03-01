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

code_files = Rake::FileList['lib/**/*.rb', 'lib/**/*.treetop', 'lib/**/*.carat'].
               exclude('lib/parser/language.rb',
                       'lib/parser/comment.rb').to_a.sort!

task :sloccount do
  count = 0
  code_files.each do |file_name|
    File.open(file_name) do |file|
      file.each_line do |line|
        count += 1 unless line =~ /^\s*$/
      end
    end
  end
  puts count
end

task :generate_code_listing do
  listing = ""
  listing << File.read("report/code_listing_header.tex")
  code_files.each do |file|
    title = file.gsub("_", '\_').sub("lib/", "")
    language = (file =~ /\.treetop/) ? "treetop" : "Ruby"
    listing << <<-TEX
\\begin{lstlisting}[title={\\small\\ttfamily\\bfseries #{title}},language=#{language}]
#{File.read(file)}
\\end{lstlisting}
TEX
  end
  
  File.open("report/code_listing.tex", "w+") do |file|
    file.write(listing)
  end
end
