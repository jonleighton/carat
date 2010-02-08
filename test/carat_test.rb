# Here are some basic tests to make sure I don't introduce too many regressions
# Will replace with RubySpec when Carat becomes mature enough

require "test/unit"
require File.dirname(__FILE__) + "/../lib/carat"
require "stringio"

class CaratTest < Test::Unit::TestCase
  def execute(code)
    old_stdout = $stdout
    output = StringIO.new
    $stdout = output
    Carat.run(code)
    output.string
  rescue SystemExit
    output.string
  ensure
    $stdout = old_stdout
  end
  
  def test_lit
    assert_equal("73\n", execute("puts 73"))
  end
  
  def test_addition
    assert_equal("7\n", execute("puts 4 + 3"))
  end
  
  def test_class_definition_and_method_calling
    code = <<-CODE
      class Foo
        def self.foo
          6
        end
        
        def foo
          2
        end
      end
      
      puts Foo.new.foo + Foo.foo
    CODE
    
    assert_equal("8\n", execute(code))
  end
  
  def test_class_reopening
    code = <<-CODE
      class Foo
        def a
          3
        end
        
        def b
          2
        end
      end
      
      class Foo
        def b
          1
        end
      end
      
      foo = Foo.new
      puts foo.a + foo.b
    CODE
    
    assert_equal("4\n", execute(code))
  end
  
  def test_subclassing
    code = <<-CODE
      class A
        def a
          4
        end
        
        def b
          2
        end
      end
      
      class B < A
        def b
          8
        end 
      end
      
      a = A.new
      b = B.new
      puts a.a + a.b + a.a + b.b
    CODE
    
    assert_equal("18\n", execute(code))
  end
  
  def test_object
    code = <<-CODE
      class Object
        def self.a
          3
        end
        
        def b
          2
        end
      end
      
      class Foo
      end
      
      puts Foo.a + Foo.b + Foo.new.b
    CODE
    
    assert_equal("7\n", execute(code))
  end
  
  def test_class
    code = <<-CODE
      class Class
        def a
          3
        end
      end
      
      class Foo
      end
      
      puts Foo.a
    CODE
    
    assert_equal("3\n", execute(code))
  end
  
  def test_module_including
    code = <<-CODE
      module Foo
        def a
          5
        end
        
        def self.b
          2
        end
      end
      
      module Foo2
        def c
          4
        end
      end

      class Bar
        include Foo
        include Foo2
      end
      
      bar = Bar.new
      puts bar.a + bar.c + Foo.b
    CODE
    
    assert_equal("11\n", execute(code))
  end
  
  def test_block_without_closure
    code = <<-CODE
      def foo
        yield(2)
      end

      foo { |x|
        puts x + 5
      }
    CODE
    
    assert_equal("7\n", execute(code))
  end
  
  def test_block_with_closure
    code = <<-CODE
      class Foo
        def a
          foo = 5
          yield
        end
      end

      foo = 2
      block = lambda do
        puts foo
        foo = 3
      end
      foo = 7
      obj = Foo.new
      obj.a(&block)
      puts foo
    CODE
    
    assert_equal("7\n3\n", execute(code))
  end
  
  def test_instance_variables
    code = <<-CODE
      class Foo
        def a
          @foo = 5
        end
        
        def b
          @foo
        end
      end

      foo = Foo.new
      puts foo.b
      foo.a
      puts foo.b
    CODE
    
    assert_equal("nil\n5\n", execute(code))
  end
  
  def test_nil_false_true
    code = <<-CODE
      puts nil
      puts true
      puts false
    CODE
    
    assert_equal("nil\ntrue\nfalse\n", execute(code))
  end
  
  def test_string
    code = <<-CODE
      puts "foo"
      puts String.new + "bar"
    CODE
    
    assert_equal("foo\nbar\n", execute(code))
  end
  
  def test_conditional
    code = <<-CODE
      if true
        puts "hi"
      else
        puts "FAIL"
      end
      
      if false
        puts "FAIL"
      else
        puts "bye"
      end
    CODE
    
    assert_equal("hi\nbye\n", execute(code))
  end
  
  def test_scoping
    code = <<-CODE
      a = 1
      puts a

      class Foo
        a = 2
        puts a
        
        def bar
          a = 3
          puts a
        end
        Foo.new.bar
        
        puts a
      end

      puts a
    CODE
    
    assert_equal("1\n2\n3\n2\n1\n", execute(code))
  end
  
  def test_array_block_operations
    code = <<-CODE
      y = [3, 5, 2].map do |item|
        item + 1
      end

      p y
    CODE
    
    assert_equal("[4, 6, 3]\n", execute(code))
  end
  
  def test_splat
    code = <<-CODE
      def foo(a, *b)
        puts a
        p b
      end
      
      foo(1, 2, 3, 4)
      
      def bar(a, b)
        puts a
        puts b
      end
      
      bar(*[4, 2])
      
      def foo(*a, b)
        p a
        puts b
      end

      foo(3, 4, 5)
    CODE
    
    assert_equal("1\n[2, 3, 4]\n4\n2\n[3, 4]\n5\n", execute(code))
  end
  
  def test_argument_defaults
    code = <<-CODE
      def foo(a = "hi")
        puts a
      end

      foo
    CODE
    
    assert_equal("hi\n", execute(code))
  end
  
  def test_and
    code = <<-CODE
      puts "FAIL" && "PASS"
    CODE
    
    assert_equal("PASS\n", execute(code))
  end
  
  def test_or
    code = <<-CODE
      puts "PASS" || "FAIL"
    CODE
    
    assert_equal("PASS\n", execute(code))
  end
  
  def test_comparison
    code = <<-CODE
      if 1 < 2 &&
         2 > 1 &&
         1 <= 2 &&
         1 <= 1 &&
         2 >= 1 &&
         2 >= 2
        puts "PASS"
      else
        puts "FAIL"
      end

      if 1 > 2 ||
         2 < 1 ||
         1 >= 2 ||
         2 <= 1
        puts "FAIL"
      else
        puts "PASS"
      end

      if (1 <=> 2) == -1
        puts "PASS"
      else
        puts "FAIL"
      end
    CODE
    
    assert_equal("PASS\nPASS\nPASS\n", execute(code))
  end
  
  def test_binary_assignment
    code = <<-CODE
      i = 1
      i += 1
      puts i

      i = true
      i &&= false
      puts i
    CODE
    
    assert_equal("2\nfalse\n", execute(code))
  end
  
  def test_while
    code = <<-CODE
      i = 1
      while i <= 5
        puts i
        i += 1
      end
    CODE
    
    assert_equal("1\n2\n3\n4\n5\n", execute(code))
  end
  
  def test_return
    code = <<-CODE
      def foo
        return "PASS"
        "FAIL"
      end

      puts foo
    CODE
    
    assert_equal("PASS\n", execute(code))
  end
  
  def test_exceptions
    code = <<-CODE
      class TestError < RuntimeError; end

      begin
        raise TestError.new("PASS")
        puts "FAIL"
      rescue TestError => error
        puts "PASS"
        puts error.to_s
      end

      begin
        begin
          raise RuntimeError
          puts "FAIL"
        rescue TestError => error
          puts "FAIL"
        end
      rescue
        puts "PASS"
      end
    CODE
    
    assert_equal("PASS\nPASS\nPASS\n", execute(code))
  end
  
  def test_scoping_after_jumps
    code = <<-CODE
      begin
        foo = 4
        raise
      rescue
        puts foo
      end

      puts foo

      a = 5

      def foo
        a = 3
        return
      end

      foo
      puts a
    CODE
    
    assert_equal("4\n4\n5\n", execute(code))
  end
  
  def test_environment
    runtime = Carat::Runtime.new
    runtime.setup_environment
    
    constants = runtime.constants
    
    constants.each do |name, object|
      if object.is_a?(Carat::Data::ClassInstance)
        case object
          when Carat::Data::SingletonClassInstance
            assert_equal constants[:SingletonClass].singleton_class, object.singleton_class
          else
            if object.superclass.nil?
              assert_equal :Object, name
            else
              assert_equal object.superclass.singleton_class, object.singleton_class.superclass
            end
        end
      end
    end
  end
end
