# Autogenerated from a Treetop grammar. Edits may be lost.


module Carat
  # This is a simple parser which strips comments from the source code before that code is actually
  # parsed. It is simpler to keep this step separate.
  # 
  # There are two kinds of comment:
  # 
  #   1. Starts with '#' and finished with \n
  #   2. Starts with '##' and finishes with next occurrence of '##'
  # 
  # With the second kind, newlines are preserved when stripping, so that error message which
  # involve line numbers still make sense.
  module Comment
    include Treetop::Runtime

    def root
      @root || :program
    end

    module Program0
      def line
        elements[1]
      end
    end

    module Program1
      def head
        elements[0]
      end

      def tail
        elements[1]
      end

    end

    module Program2
      def lines
        [head] + tail.elements.map(&:line)
      end
      
      def strip
        lines.map(&:strip).join("\n")
      end
    end

    module Program3
      def strip
        ''
      end
    end

    def _nt_program
      start_index = index
      if node_cache[:program].has_key?(index)
        cached = node_cache[:program][index]
        @index = cached.interval.end if cached
        return cached
      end

      i0 = index
      i1, s1 = index, []
      r2 = _nt_line
      s1 << r2
      if r2
        s3, i3 = [], index
        loop do
          i4, s4 = index, []
          if has_terminal?("\n", false, index)
            r5 = instantiate_node(SyntaxNode,input, index...(index + 1))
            @index += 1
          else
            terminal_parse_failure("\n")
            r5 = nil
          end
          s4 << r5
          if r5
            r6 = _nt_line
            s4 << r6
          end
          if s4.last
            r4 = instantiate_node(SyntaxNode,input, i4...index, s4)
            r4.extend(Program0)
          else
            @index = i4
            r4 = nil
          end
          if r4
            s3 << r4
          else
            break
          end
        end
        r3 = instantiate_node(SyntaxNode,input, i3...index, s3)
        s1 << r3
        if r3
          if has_terminal?("\n", false, index)
            r8 = instantiate_node(SyntaxNode,input, index...(index + 1))
            @index += 1
          else
            terminal_parse_failure("\n")
            r8 = nil
          end
          if r8
            r7 = r8
          else
            r7 = instantiate_node(SyntaxNode,input, index...index)
          end
          s1 << r7
        end
      end
      if s1.last
        r1 = instantiate_node(SyntaxNode,input, i1...index, s1)
        r1.extend(Program1)
        r1.extend(Program2)
      else
        @index = i1
        r1 = nil
      end
      if r1
        r0 = r1
      else
        if has_terminal?('', false, index)
          r9 = instantiate_node(SyntaxNode,input, index...(index + 0))
          r9.extend(Program3)
          @index += 0
        else
          terminal_parse_failure('')
          r9 = nil
        end
        if r9
          r0 = r9
        else
          @index = i0
          r0 = nil
        end
      end

      node_cache[:program][start_index] = r0

      r0
    end

    module Line0
      def parts
        elements[0]
      end

      def comment
        elements[1]
      end
    end

    module Line1
      def stripped_comment
        comment.empty? ? '' : comment.strip
      end
    
      def strip
        parts.text_value + stripped_comment
      end
    end

    def _nt_line
      start_index = index
      if node_cache[:line].has_key?(index)
        cached = node_cache[:line][index]
        @index = cached.interval.end if cached
        return cached
      end

      i0, s0 = index, []
      s1, i1 = [], index
      loop do
        i2 = index
        r3 = _nt_string
        if r3
          r2 = r3
        else
          r4 = _nt_non_string
          if r4
            r2 = r4
          else
            @index = i2
            r2 = nil
          end
        end
        if r2
          s1 << r2
        else
          break
        end
      end
      r1 = instantiate_node(SyntaxNode,input, i1...index, s1)
      s0 << r1
      if r1
        r6 = _nt_comment
        if r6
          r5 = r6
        else
          r5 = instantiate_node(SyntaxNode,input, index...index)
        end
        s0 << r5
      end
      if s0.last
        r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
        r0.extend(Line0)
        r0.extend(Line1)
      else
        @index = i0
        r0 = nil
      end

      node_cache[:line][start_index] = r0

      r0
    end

    def _nt_non_string
      start_index = index
      if node_cache[:non_string].has_key?(index)
        cached = node_cache[:non_string][index]
        @index = cached.interval.end if cached
        return cached
      end

      s0, i0 = [], index
      loop do
        if has_terminal?('\G[^\\#\\n\\"\\\']', true, index)
          r1 = true
          @index += 1
        else
          r1 = nil
        end
        if r1
          s0 << r1
        else
          break
        end
      end
      if s0.empty?
        @index = i0
        r0 = nil
      else
        r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
      end

      node_cache[:non_string][start_index] = r0

      r0
    end

    module String0
    end

    module String1
    end

    def _nt_string
      start_index = index
      if node_cache[:string].has_key?(index)
        cached = node_cache[:string][index]
        @index = cached.interval.end if cached
        return cached
      end

      i0 = index
      i1, s1 = index, []
      if has_terminal?('"', false, index)
        r2 = instantiate_node(SyntaxNode,input, index...(index + 1))
        @index += 1
      else
        terminal_parse_failure('"')
        r2 = nil
      end
      s1 << r2
      if r2
        s3, i3 = [], index
        loop do
          if has_terminal?('\G[^\\"]', true, index)
            r4 = true
            @index += 1
          else
            r4 = nil
          end
          if r4
            s3 << r4
          else
            break
          end
        end
        r3 = instantiate_node(SyntaxNode,input, i3...index, s3)
        s1 << r3
        if r3
          if has_terminal?('"', false, index)
            r5 = instantiate_node(SyntaxNode,input, index...(index + 1))
            @index += 1
          else
            terminal_parse_failure('"')
            r5 = nil
          end
          s1 << r5
        end
      end
      if s1.last
        r1 = instantiate_node(SyntaxNode,input, i1...index, s1)
        r1.extend(String0)
      else
        @index = i1
        r1 = nil
      end
      if r1
        r0 = r1
      else
        i6, s6 = index, []
        if has_terminal?("'", false, index)
          r7 = instantiate_node(SyntaxNode,input, index...(index + 1))
          @index += 1
        else
          terminal_parse_failure("'")
          r7 = nil
        end
        s6 << r7
        if r7
          s8, i8 = [], index
          loop do
            if has_terminal?('\G[^\\\']', true, index)
              r9 = true
              @index += 1
            else
              r9 = nil
            end
            if r9
              s8 << r9
            else
              break
            end
          end
          r8 = instantiate_node(SyntaxNode,input, i8...index, s8)
          s6 << r8
          if r8
            if has_terminal?("'", false, index)
              r10 = instantiate_node(SyntaxNode,input, index...(index + 1))
              @index += 1
            else
              terminal_parse_failure("'")
              r10 = nil
            end
            s6 << r10
          end
        end
        if s6.last
          r6 = instantiate_node(SyntaxNode,input, i6...index, s6)
          r6.extend(String1)
        else
          @index = i6
          r6 = nil
        end
        if r6
          r0 = r6
        else
          @index = i0
          r0 = nil
        end
      end

      node_cache[:string][start_index] = r0

      r0
    end

    def _nt_comment
      start_index = index
      if node_cache[:comment].has_key?(index)
        cached = node_cache[:comment][index]
        @index = cached.interval.end if cached
        return cached
      end

      i0 = index
      r1 = _nt_multi_line_comment
      if r1
        r0 = r1
      else
        r2 = _nt_single_line_comment
        if r2
          r0 = r2
        else
          @index = i0
          r0 = nil
        end
      end

      node_cache[:comment][start_index] = r0

      r0
    end

    module MultiLineComment0
    end

    module MultiLineComment1
    end

    module MultiLineComment2
      def strip
        # Keep the new lines so that error messages which refer to a line number still make sense
        text_value.gsub(/[^\n]/, "")
      end
    end

    def _nt_multi_line_comment
      start_index = index
      if node_cache[:multi_line_comment].has_key?(index)
        cached = node_cache[:multi_line_comment][index]
        @index = cached.interval.end if cached
        return cached
      end

      i0, s0 = index, []
      if has_terminal?('##', false, index)
        r1 = instantiate_node(SyntaxNode,input, index...(index + 2))
        @index += 2
      else
        terminal_parse_failure('##')
        r1 = nil
      end
      s0 << r1
      if r1
        s2, i2 = [], index
        loop do
          i3, s3 = index, []
          i4 = index
          if has_terminal?('##', false, index)
            r5 = instantiate_node(SyntaxNode,input, index...(index + 2))
            @index += 2
          else
            terminal_parse_failure('##')
            r5 = nil
          end
          if r5
            r4 = nil
          else
            @index = i4
            r4 = instantiate_node(SyntaxNode,input, index...index)
          end
          s3 << r4
          if r4
            if index < input_length
              r6 = instantiate_node(SyntaxNode,input, index...(index + 1))
              @index += 1
            else
              terminal_parse_failure("any character")
              r6 = nil
            end
            s3 << r6
          end
          if s3.last
            r3 = instantiate_node(SyntaxNode,input, i3...index, s3)
            r3.extend(MultiLineComment0)
          else
            @index = i3
            r3 = nil
          end
          if r3
            s2 << r3
          else
            break
          end
        end
        r2 = instantiate_node(SyntaxNode,input, i2...index, s2)
        s0 << r2
        if r2
          if has_terminal?('##', false, index)
            r7 = instantiate_node(SyntaxNode,input, index...(index + 2))
            @index += 2
          else
            terminal_parse_failure('##')
            r7 = nil
          end
          s0 << r7
        end
      end
      if s0.last
        r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
        r0.extend(MultiLineComment1)
        r0.extend(MultiLineComment2)
      else
        @index = i0
        r0 = nil
      end

      node_cache[:multi_line_comment][start_index] = r0

      r0
    end

    module SingleLineComment0
    end

    module SingleLineComment1
      def strip
        ''
      end
    end

    def _nt_single_line_comment
      start_index = index
      if node_cache[:single_line_comment].has_key?(index)
        cached = node_cache[:single_line_comment][index]
        @index = cached.interval.end if cached
        return cached
      end

      i0, s0 = index, []
      if has_terminal?('#', false, index)
        r1 = instantiate_node(SyntaxNode,input, index...(index + 1))
        @index += 1
      else
        terminal_parse_failure('#')
        r1 = nil
      end
      s0 << r1
      if r1
        s2, i2 = [], index
        loop do
          if has_terminal?('\G[^\\n]', true, index)
            r3 = true
            @index += 1
          else
            r3 = nil
          end
          if r3
            s2 << r3
          else
            break
          end
        end
        r2 = instantiate_node(SyntaxNode,input, i2...index, s2)
        s0 << r2
      end
      if s0.last
        r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
        r0.extend(SingleLineComment0)
        r0.extend(SingleLineComment1)
      else
        @index = i0
        r0 = nil
      end

      node_cache[:single_line_comment][start_index] = r0

      r0
    end

  end

  class CommentParser < Treetop::Runtime::CompiledParser
    include Comment
  end

end