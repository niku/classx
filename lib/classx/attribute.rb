class ClassX
  class AttributeFactory
    def self.create args
      klass = Class.new
      klass.class_eval do
        # args.each do |key, val|
        #   key = key.to_s
        #   include "ClassX::Attribute::#{key.capitalize}"
        # end
        
        # XXX: Hack for defining class method for klass
        mod = Module.new
        mod.module_eval do
          define_method :config do
            args
          end
        end
        __send__ :extend, mod

        raise ClassX::RequiredAttrShouldNotHaveDefault if args[:optional] == false && !args[:default].nil?
        raise ClassX::OptionalAttrShouldBeWritable if args[:optional] && args[:writable] == false

        define_method :initialize do |val|
          @parent = val
          @data = nil
        end

        define_method :get do
          @data ||= default
        end

        # for extending attribute point.
        if args[:include]
          case args[:include]
          when Array
            args[:include].each do |mod|
              self.__send__ :include, mod
            end
          else
            self.__send__ :include, args[:include]
          end
        end

        if args[:extend]
          case args[:extend]
          when Array
            args[:extend].each do |mod|
              self.__send__ :extend, mod
            end
          else
            self.__send__ :extend, args[:extend]
          end
        end

        # description for attribute
        define_method :desc do
          args[:desc] 
        end

        # default paramater for attribute.
        # if default is Proc, run Proc every time in instanciate.
        define_method :default do
          case args[:default]
          when Proc
            args[:default].call(@parent)
          else
            args[:default]
          end
        end

        # when it lazy option specified, it will not be initialized when #initialize.
        define_method :lazy? do
          return args[:lazy]
        end

        # when this option specify true, not raise error in #initialize without value.
        define_method :optional? do
          return args[:optional]
        end

        # you can specify :validate option for checking when value is setted.
        # you can use :respond_to as shotcut for specifying { :validate => proc {|val| respond_to?(val, true) } }
        # you can use :isa or :kind_of as shotcut for specifying { :validate => proc {|val| kind_of?(val) } }
        define_method :validate? do |val|
          if args[:validate]
            case args[:validate]
            when Proc
              return args[:validate].call(val)
            when Regexp
              return args[:validate] =~ val
            else
              return args[:validate] == val
            end
          elsif klass = ( args[:isa] || args[:kind_of] )
            return val.kind_of?(klass)
          elsif args[:respond_to]
            return val.respond_to?(args[:respond_to], true)
          else
            # nothing checked.
            true
          end
        end

        define_method :set do |val|
          raise ClassX::InvalidAttrArgument unless validate? val
          @data = val
        end

        define_method :inspect do
          "<#ClassX::Attribute #{self.class.config.inspect}:#{object_id} #{ @data.nil? ? '' : '@data=' + @data.inspect } >"
        end
      end

      klass
    end
  end
end
