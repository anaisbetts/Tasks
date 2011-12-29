module Tasks

  TaskRegex = /^\s*- /
  ProjectRegex = /^\s*(.*):$/
  IndentRegex = /^\s+/
  WhitespaceOnly = /^\s*$/

  def detect_indent(lines)
    t = lines.detect {|x| x =~ IndentRegex}
    return "\t" unless t

    IndentRegex.match(t)[0]
  end

  def indent_count(line, one_indent)
    m = IndentRegex.match(line)
    return 0 unless m

    m[0].length / one_indent.length
  end

  class Project
    attr_accessor :name, :tasks, :projects, :notes

    class << self

      def parse(lines, indent_defn, indent_level)
        line = lines[0]
        return [nil, lines] unless (m = ProjectRegex.match(line)) and indent_count(line, indent_defn) == indent_level

        ret = Project.new
        ret.name = m[1]
        ret.projects = []
        ret.tasks = []

        ret_lines = lines.drop(1)
        while ret_lines.length > 0 and indent_count(ret_lines[0], indent_defn) >= indent_level
          if ret_lines[0] =~ ProjectRegex
            (child, ret_lines) = Project.parse(ret_lines, indent_defn, indent_level + 1)
            return [ret, ret_lines] unless child

            ret.projects << child
            next
          end

          if ret_lines[0] =~ TaskRegex
            (child, ret_lines) = Task.parse(ret_lines, indent_defn, indent_level)
            ret.tasks << child if child

            next
          end

          unless (ret_lines[0] =~ WhitespaceOnly)
            ret.notes = (ret.notes || "") + "\n" + ret_lines[0].gsub(IndentRegex, '')
          end

          ret_lines = ret_lines.drop(1)
        end

        [ret, ret_lines]
      end

      def parse_all(lines)
        ret = []
        indent = detect_indent(lines)

        ret_lines = lines
        while ret_lines.length > 0
          if ret_lines[0] =~ WhitespaceOnly
            ret_lines = ret_lines.drop(1)
            next
          end

          (item, ret_lines) = Project.parse(ret_lines, indent, 0)
          ret << item if item
        end

        ret
      end
    end
  end

  class Task
    attr_accessor :name, :tags, :children, :notes

    class << self

      TaskNameRegex = /^\s*- ([^@]+)\s+@?.*$/
      TaskTagRegex = /^\s*- [^@]+(@?.*)$/

      def parse_tag(tag_string)
        return { tag_string => nil } unless (m = /(\(.*\))$/.match(tag_string))

        val = m[1][1..-2]
        { tag_string.gsub(m[1], '') => val}
      end

      def parse(lines, indent_defn, indent_level)
        line = lines[0]
        m = TaskNameRegex.match(line)
        return [nil, lines] unless (m and indent_count(line, indent_defn) == indent_level)

        ret = Task.new
        ret.name = m[1]

        if (m = TaskTagRegex.match(line))
          ret.tags = m[1].split(/\s+/).inject({}) {|acc, x| acc.merge(parse_tag(x.chomp))}
        end

        ret_lines = lines.drop(1)
        ret.children = []

        while ret_lines.length > 0 and indent_count(ret_lines[0], indent_defn) > indent_level
          if ret_lines[0] =~ TaskRegex
            (child, ret_lines) = Task.parse(ret_lines, indent_defn, indent_level+1)
            ret.children << child if child
            next
          end

          unless (ret_lines[0] =~ WhitespaceOnly)
            ret.notes = (ret.notes || "") + "\n" + ret_lines[0].gsub(IndentRegex, '')
          end

          ret_lines = ret_lines.drop(1)
        end

        return [ret, ret_lines]
      end

    end
  end
end
