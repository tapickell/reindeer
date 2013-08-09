require "reindeer/version"
require 'reindeer/has_argument_handler'

# TODO:
# * lazy
#
# Maybe TODO:
# * trigger
# * does
# * handles
# * multiple attributes

module Reindeer

  # Exception thrown when the :is argument is invalid.
  # XXX Note sure if this is a good name.
  class BadIs < ArgumentError; end

  # Exception thrown when a required parameter isn't provided for
  # initialization.
  class MissingParameter < ArgumentError; end

  def self.extended(host_class)
    host_class.class_exec do

      @@attributes_required_to_initialize = []
      @@attributes_to_initialize          = []
      @@eager_attribute_builders          = {}

      def initialize(initial_values = {})
        initial_values ||= {}
        @@attributes_to_initialize.each do |attr|
          instance_variable_set :"@#{attr}", initial_values[attr]
        end

        @@attributes_required_to_initialize.each do |attr|
          if initial_values[attr].nil?
            raise MissingParameter
          else
            instance_variable_set :"@#{attr}", initial_values[attr]
          end
        end

        @@eager_attribute_builders.
          select { |attr|    instance_variable_get("@#{attr}").nil?}.
            each { |attr, b| instance_variable_set("@#{attr}", send(b)) }

        super()
      end
    end
  end

  def has(attribute_name, attribute_parameters)

    arguments = HasArgumentHandler.new(
      attribute_parameters.merge({ attribute_name: attribute_name })
    )

    class_exec do

      define_method(arguments.getter_name) do
        val = instance_variable_get("@#{arguments.attribute_name}")
        val.nil? ? attribute_parameters[:default] : val
      end
      define_method(arguments.setter_name) do |val|
        instance_variable_set "@#{arguments.attribute_name}", val
      end if arguments.setter?

      if attribute_parameters[:required]
        @@attributes_required_to_initialize << arguments.initializer_name
      else
        @@attributes_to_initialize << arguments.initializer_name
      end

      if attribute_parameters[:builder]
        @@eager_attribute_builders[arguments.attribute_name] =
          attribute_parameters[:builder]
      end

      build_predicate(arguments.predicate_name, arguments.getter_name)  if attribute_parameters[:predicate]
      build_clearer(  arguments.clearer_name, arguments.attribute_name) if attribute_parameters[:clearer]
    end
  end

  private

  def build_predicate(predicate_name, getter_name)
    puts predicate_name
    define_method(predicate_name) do
      not send(getter_name).nil?
    end
  end

  def build_clearer(clearer_name, attribute_name)
    define_method(clearer_name) do
      instance_variable_set "@#{attribute_name}", nil
    end
  end
end
