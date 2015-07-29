module Infoboxer
  module Templates
    class Base < Tree::Template
      include Tree
      
      class << self
        attr_accessor :template_name, :template_options

        def inspect
          "#<#{clean_name}>"
        end

        def clean_name
          name ? name.sub(/^.*::/, '') : "Template[#{template_name}]"
        end
      end

      def unnamed_variables
        variables.select{|v| v.name =~ /^\d+$/}
      end

      def fetch(*patterns)
        Nodes[*patterns.map{|p| variables.find(name: p)}.flatten]
      end

      def fetch_hash(*patterns)
        fetch(*patterns).map{|v| [v.name, v]}.to_h
      end

      def fetch_date(*patterns)
        components = fetch(*patterns)
        components.pop while components.last.nil? && !components.empty?
        
        if components.empty?
          nil
        else
          Date.new(*components.map{|v| v.to_s.to_i})
        end
      end
    end

    # Renders all of its unnamed variables as space-separated text
    # Also allows in-template navigation
    class Show < Base
      alias_method :children, :unnamed_variables

      protected

      def separator
        ' '
      end
    end

    class Replace < Base
      def replace
        fail(NotImplementedError, "Descendants should define :replace")
      end

      def text
        replace
      end
    end

    class Literal < Base
      alias_method :text, :name
    end
  end
end
