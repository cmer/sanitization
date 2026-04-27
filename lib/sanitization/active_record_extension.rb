module Sanitization
  module ActiveRecordExtension
    def self.append_features(base)
      super
      base.extend(ClassMethods)
    end

    # Taken from `strip_attributes`: https://github.com/rmm5t/strip_attributes/blob/master/lib/strip_attributes.rb
    # Unicode invisible and whitespace characters. The POSIX character class
    # [:space:] corresponds to the Unicode class Z ("separator"). We also
    # include the following characters from Unicode class C ("control"), which
    # are spaces or invisible characters that make no sense at the start or end
    # of a string:
    #   U+180E MONGOLIAN VOWEL SEPARATOR
    #   U+200B ZERO WIDTH SPACE
    #   U+200C ZERO WIDTH NON-JOINER
    #   U+200D ZERO WIDTH JOINER
    #   U+2060 WORD JOINER
    #   U+FEFF ZERO WIDTH NO-BREAK SPACE
    MULTIBYTE_WHITE = "\u180E\u200B\u200C\u200D\u2060\uFEFF".freeze
    MULTIBYTE_BLANK = /[[:blank:]#{MULTIBYTE_WHITE}]/.freeze
    MULTIBYTE_SUPPORTED = "\u0020" == " "

    def self.format_value(value, settings)
      return value unless value.is_a?(String)

      v = value.dup
      v.strip! if value_or_default(settings, :strip)

      if value_or_default(settings, :collapse)
        if MULTIBYTE_SUPPORTED && Encoding.compatible?(v, MULTIBYTE_BLANK)
          v.gsub!(/#{MULTIBYTE_BLANK}+/, " ")
        else
          v.squeeze!(" ")
        end
      end

      return nil if value_or_default(settings, :nullify) && v.empty? && settings[:null]

      case_method = value_or_default(settings, :case)
      v = v.send(case_method) if case_method && case_method != :none

      v
    end

    def self.value_or_default(settings, transform)
      if settings[transform].nil?
        Sanitization.configuration[transform]
      else
        settings[transform]
      end
    end

    module ClassMethods
      attr_accessor :sanitization__store

      private
      def sanitizes(options = {})
        # Skip initialization if table is not yet created. For example, during migrations.
        begin
          return unless ActiveRecord::Base.connection.data_source_exists?(self.table_name)
        rescue ActiveRecord::NoDatabaseError
          return
        end

        self.sanitization__store ||= {}

        options[:only]   = Array.wrap(options[:only])
        options[:except] = Array.wrap(options[:except])

        unless options[:case].nil?
          raise ArgumentError.new("Invalid type for `case`: #{options[:case].class}") \
            unless [String, Symbol].include?(options[:case].class)
          options[:case] = options[:case].downcase.to_s
          options[:case] = options[:case] + "case" unless options[:case] =~ /case$/
        end

        columns_to_format  = self.columns.select { |c| c.type == :string }
        columns_to_format  = columns_to_format.concat(self.columns.select { |c| c.type == :text }) \
          if options[:include_text_type]

        columns_to_format = options[:only].map do |col|
          columns_to_format.detect { |c| c.name == col.to_s }
        end.compact if options[:only].present?

        options[:except].each do |col|
          columns_to_format.delete_if { |c| c.name == col.to_s }
        end

        if options[:case]
          @valid_case_methods ||= String.new.methods.map { |m|
            m.to_s if m.to_s =~ /case$/
          }.compact

          raise ArgumentError.new("Method not found: `:#{options[:case]}`. " +
            "Valid methods are: :#{@valid_case_methods.join(', :')}") \
            unless @valid_case_methods.include?(options[:case]) || options[:case] == :none
        end

        klass = self
        columns_to_format.each do |col|
          fresh = !self.sanitization__store.key?(col.name)
          self.sanitization__store[col.name] ||= { null: col.null }
          self.sanitization__store[col.name].merge!(options.slice(:case, :strip, :collapse, :nullify))

          if fresh
            col_name = col.name
            normalizes col_name.to_sym, with: ->(value) {
              Sanitization::ActiveRecordExtension.format_value(value, klass.sanitization__store[col_name])
            }
          end
        end
      end
      alias sanitization sanitizes
    end # module ClassMethods
  end # module ActiveRecordExt
end # module Sanitization
