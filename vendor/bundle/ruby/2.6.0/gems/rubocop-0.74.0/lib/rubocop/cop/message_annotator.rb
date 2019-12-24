# frozen_string_literal: true

module RuboCop
  module Cop
    # Message Annotator class annotates a basic offense message
    # based on params passed into initializer.
    #
    # @see #initialize
    #
    # @example
    #   RuboCop::Cop::MessageAnnotator.new(
    #     config, cop_config, @options
    #   ).annotate('message', 'Cop/CopName')
    #  #=> 'Cop/CopName: message (http://example.org/styleguide)'
    class MessageAnnotator
      attr_reader :options, :config, :cop_config

      @style_guide_urls = {}

      class << self
        attr_reader :style_guide_urls
      end

      # @param config [RuboCop::Config] Check configs for all cops
      #   @note Message Annotator specifically checks the
      #     following config options for_all_cops
      #     :StyleGuideBaseURL [String] URL for styleguide
      #     :DisplayStyleGuide [Boolean] Include styleguide and reference URLs
      #     :ExtraDetails [Boolean] Include cop details
      #     :DisplayCopNames [Boolean] Include cop name
      #
      # @param [Hash] cop_config configs for specific cop, from config#for_cop
      # @option cop_config [String] :StyleGuide Extension of base styleguide URL
      # @option cop_config [String] :Reference Full reference URL
      # @option cop_config [String] :Details
      #
      # @param [Hash, nil] options optional
      # @option options [Boolean] :display_style_guide
      #   Include style guide and reference URLs
      # @option options [Boolean] :extra_details
      #   Include cop specific details
      # @option options [Boolean] :debug
      #   Include debug output
      # @option options [Boolean] :display_cop_names
      #   Include cop name
      def initialize(config, cop_config, options)
        @config = config
        @cop_config = cop_config || {}
        @options = options
      end

      # Returns the annotated message,
      # based on params passed into initializer
      #
      # @return [String] annotated message
      def annotate(message, name)
        message = "#{name}: #{message}" if display_cop_names?
        message += " #{details}" if extra_details? && details
        if display_style_guide?
          links = urls.join(', ')
          message = "#{message} (#{links})"
        end
        message
      end

      def urls
        [style_guide_url, *reference_urls].compact
      end

      private

      def style_guide_url
        url = cop_config['StyleGuide']
        return nil if url.nil? || url.empty?

        self.class.style_guide_urls[url] ||= begin
          base_url = config.for_all_cops['StyleGuideBaseURL']
          if base_url.nil? || base_url.empty?
            url
          else
            URI.join(base_url, url).to_s
          end
        end
      end

      def display_style_guide?
        (options[:display_style_guide] ||
         config.for_all_cops['DisplayStyleGuide']) &&
          !urls.empty?
      end

      def reference_urls
        urls = Array(cop_config['Reference'])
        urls.nil? || urls.empty? ? nil : urls.reject(&:empty?)
      end

      def extra_details?
        options[:extra_details] || config.for_all_cops['ExtraDetails']
      end

      def debug?
        options[:debug]
      end

      def display_cop_names?
        return true if debug?
        return false if options[:display_cop_names] == false
        return true if options[:display_cop_names]
        return false if options[:format] == 'json'

        config.for_all_cops['DisplayCopNames']
      end

      def details
        details = cop_config && cop_config['Details']
        details.nil? || details.empty? ? nil : details
      end
    end
  end
end
