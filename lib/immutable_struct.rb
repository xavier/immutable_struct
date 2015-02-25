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
      struct.send(:undef_method, "#{member}=".to_sym)
    end
  end

  def self.optionalize_constructor!(struct)
    struct.class_eval do
      alias_method :struct_initialize, :initialize

      def self.json_create(object)
        new(object["members"])
      end

      def initialize(*attrs)
        if members.size > 1 && attrs && attrs.size == 1 && attrs.first.is_a?(Hash)
          hash = attrs.first
          struct_initialize(*members.map { |m| hash[m] || hash[m.to_s] })
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
        struct_initialize(*members.map { |m| coder.map[m.to_s] })
      end

      def as_json
        klass = self.class.name
        klass.to_s.empty? and raise JSON::JSONError, "Only named structs are supported!"
        {
          JSON.create_id => klass,
          "members"      => to_h,
        }
      end

      def to_json(*args)
        as_json.to_json(*args)
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
