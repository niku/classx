
class ClassX
  class AttrRequiredError < Exception; end
  class InvalidAttrArgument < Exception; end
  class LazyOptionShouldHaveDefault < Exception; end
  class OptionalAttrShouldBeWritable < Exception; end
  class RequiredAttrShouldNotHaveDefault < Exception; end
  class <<self
    def has name, attrs={}
      name = name.to_s

      setter_definition = ''
      if !attrs[:respond_to].nil?
        setter_definition += <<-END_OF_RESPOND_TO
          raise InvalidAttrArgument, "param :#{name}'s value \#{val.inspect} should respond_to #{attrs[:respond_to]}}"  unless val.respond_to? #{attrs[:respond_to]}
        END_OF_RESPOND_TO
      end
      if !attrs[:kind_of].nil?
        setter_definition += <<-END_OF_KIND_OF
          raise InvalidAttrArgument, "param :#{name}'s value \#{val.inspect} should kind_of #{attrs[:kind_of]}" unless val.kind_of? #{attrs[:kind_of]}
        END_OF_KIND_OF
      end

      self.class_eval <<-END_OF_ACCESSOR
        attr_reader "#{name}"

        def #{name}= val
          #{setter_definition}
          @#{name} = val
        end
      END_OF_ACCESSOR

      if attrs[:default].nil?
        raise LazyOptionShouldHaveDefault, "in :#{name}: :lazy option need specifying :default" if attrs[:lazy]
      else
        # when you specify :optional to false explicitly, raise Error.
        if attrs[:optional].nil?
          attrs[:optional] = true
        end
        raise RequiredAttrShouldNotHaveDefault, "in :#{name}: required attribute should not have :default option" unless attrs[:optional]
        case attrs[:default]
        when Proc
          register_attr_default_value_proc name, &attrs[:default]
        else
          register_attr_default_value name, attrs[:default]
        end
      end

      if attrs[:optional]
        if attrs[:writable].nil?
          attrs[:writable] = true
        else
          raise OptionalAttrShouldBeWritable unless attrs[:writable]
        end
      else
        register_attr_required name
      end

      unless attrs[:writable]
        __send__ :private,"#{name}="
      end

    end

    def register_attr_default_value name, value
      self.class_eval do
        define_method "set_attr_default_value_of[#{name}]" do
          self.__send__ "#{name}=", value
        end

        private "set_attr_default_value_of[#{name}]"
      end
    end

    def register_attr_default_value_proc name, &block
      self.class_eval do
        define_method "set_attr_default_value_of[#{name}]" do
          self.__send__ "#{name}=", block.call(self)
        end

        private "set_attr_default_value_of[#{name}]"
      end
    end

    def register_attr_required name
      define_method "attr_required[#{name}]" do
      end

      private "attr_required[#{name}]"
    end

    ATTR_REGEX = /^([^=]*?)=$/
    def attributes
      ( public_instance_methods + private_instance_methods ).select {|meth|
        meth.to_s =~ ATTR_REGEX
      }.map {|item|
        item.to_s.sub(ATTR_REGEX) { $1 }
      }
    end
    
    ATTR_REQUIRED_REGEX = /^attr_required\[(.*?)\]/
    def required_attributes
      private_instance_methods.select {|meth|
        meth.to_s =~ ATTR_REQUIRED_REGEX
      }.map {|item|
        item.sub(ATTR_REQUIRED_REGEX) { $1 }
      }
    end
  end

  def initialize hash={}
    before_init hash

    unless hash && hash.kind_of?(Hash)
      raise ArgumentError, "#{hash.inspect} was wrong as arguments. please specify kind of Hash instance"
    end

    hash = hash.inject({}) {|h,item| h[item.first.to_s] = item.last; h } # allow String or Symbol for key 
    self.class.required_attributes.each do |name|
      raise AttrRequiredError, "param :#{name} is required to #{hash.inspect}" unless hash.keys.include?(name)
    end
    hash.each do |key,val|
      if respond_to? "#{key}=", true
        __send__ "#{key}=", val
      end
    end
    private_methods.select do |meth|
      meth.to_s =~ /^set_attr_default_value_of\[(.*?)\]$/
    end.each do |meth|
      __send__ meth
    end
    after_init
  end

  # just extend point
  def before_init hash
  end

  def after_init
  end

end
