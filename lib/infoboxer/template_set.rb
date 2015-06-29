# encoding: utf-8
module Infoboxer
  class TemplateSet
    def initialize(&definitions)
      @templates = []
      define(&definitions) if definitions
    end
    
    def find(name)
      _, template = @templates.detect{|m, t| m === name}
      template || Template
    end

    def define(&definitions)
      instance_eval(&definitions)
    end

    def clear
      @templates.clear
    end

    private

      def template(name, options = {}, &definition)
        setup_class(name, Template, options, &definition)
      end

      def inflow_template(name, options = {}, &definition)
        setup_class(name, InFlowTemplate, options, &definition)
      end

      def setup_class(name, base_class, options, &definition)
        match = options.fetch(:match, /^#{name.downcase}$/i)
        base = options.fetch(:base, base_class)
        base = self.find(base) if base.is_a?(String)
        
        Class.new(base, &definition).tap{|cls|
          cls.template_name = name
          cls.template_options = options
          @templates.unshift [match, cls]
        }
      end
  end
end