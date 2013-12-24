# encoding: utf-8

class ImmutableStruct
  VERSION = '1.1.1'
  
  def self.new(*attrs, &block)
    struct = Struct.new(*attrs, &block)
    make_immutable!(struct)
    optionalize_constructor!(struct)
    extend_dup!(struct)
    struct
  end
  
private

  def self.make_immutable!(struct)
    struct.send(:undef_method, "[]=".to_sym)
    struct.members.each do |member|
      original_setter = "#{member}=".to_sym
      private_setter  = "_#{member}=".to_sym
      struct.send(:alias_method, private_setter, original_setter)
      struct.send(:private, private_setter)
      struct.send(:undef_method, original_setter)
    end
  end
  
  def self.optionalize_constructor!(struct)
    struct.class_eval do
      alias_method :struct_initialize, :initialize

      def initialize(*attrs)
        if members.size > 1 && attrs && attrs.size == 1 && attrs.first.instance_of?(Hash)
          struct_initialize(*members.map { |m| attrs.first[m.to_sym] })
        else
          struct_initialize(*attrs)
        end
      end
      
      def to_h
        members.inject({}) do |h, m|
          h[m.to_sym] = self[m]
          h
        end
      end

      def encode_with(coder)
        members.each do |m|
          coder[m.to_s] = self[m]
        end
      end

      def init_with(coder)
        coder.map.each do |k, v|
          send("_#{k}=", v)
        end
      end

    end
  end
  
  def self.extend_dup!(struct)
    struct.class_eval do
      def dup(overrides={})
        self.class.new(to_h.merge(overrides))
      end
    end
  end
end
