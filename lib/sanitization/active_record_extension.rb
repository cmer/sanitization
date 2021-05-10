module Sanitization
  module ActiveRecordExtension
    def self.append_features(base)
      super
      base.extend(ClassMethods)
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

        columns_to_format.each do |col|
          self.sanitization__store[col.name] ||= {}
          self.sanitization__store[col.name].merge!(options.slice(:case, :strip, :collapse, :nullify))
        end

        class_eval <<-EOV
          include Sanitization::ActiveRecordExtension::InstanceMethods
          before_save :sanitization__format_strings
        EOV
      end
      alias sanitization sanitizes
    end # module ClassMethods

    module InstanceMethods
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
        MULTIBYTE_SPACE = /[[:space:]#{MULTIBYTE_WHITE}]/.freeze
        MULTIBYTE_BLANK = /[[:blank:]#{MULTIBYTE_WHITE}]/.freeze
        MULTIBYTE_SUPPORTED = "\u0020" == " "

      private

      def sanitization__format_strings
        return unless self.class.sanitization__store

        class_formatting = self.class.sanitization__store
        class_formatting.each_pair do |col_name, col_formatting|
          sanitization__format_column(col_name, col_formatting)
        end
      end

      def sanitization__format_column(col_name, col_formatting)
        return unless self[col_name].is_a?(String)

        self[col_name].strip! if value_or_default(col_formatting, :strip)

        if value_or_default(col_formatting, :collapse)
          if MULTIBYTE_SUPPORTED && Encoding.compatible?(self[col_name], MULTIBYTE_BLANK)
            self[col_name].gsub!(/#{MULTIBYTE_BLANK}+/, " ")
          else
            self[col_name].squeeze!(" ")
          end
        end

        if value_or_default(col_formatting, :nullify) && !self[col_name].nil? && self[col_name].to_s.empty? && \
          self.class.columns.select { |c| c.name == col_name }.first.null
          return self[col_name] = nil
        end

        case_formatting_method = value_or_default(col_formatting, :case)
        if !case_formatting_method.nil? && case_formatting_method != :none
          self[col_name] = self[col_name].send(case_formatting_method)
        end

        self[col_name]
      end

      def value_or_default(col_formatting, transform)
        if col_formatting[transform].nil?
          Sanitization.configuration[transform]
        else
          col_formatting[transform]
        end
      end


    end # module InstanceMethods
  end # module ActiveRecordExt
end # module Sanitization

