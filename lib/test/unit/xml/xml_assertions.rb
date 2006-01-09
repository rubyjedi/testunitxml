#! /usr/bin/ruby

require 'rexml/document'
require 'test/unit/xml/attributes_mixin' # Must be required after rexml/document
require 'test/unit'
require 'test/unit/xml/xmlequalfilter'
require 'test/unit/xml/nodeiterator'

=begin rdoc
This module contains assertions about XML documents. The assertions are
meant to be mixed in to test classes such as Test::Unit::TestCase.
=end
module Test
  module Unit
    module XML

      # This method checks whether two well-formed XML documents are equal.
      # Doctype declarations are ignored for the purposes of comparison.
      # Two XML documents are considered equal if:
      # * They contain the same type of nodes, in the same order,
      #   except for text nodes that are empty, or contain only
      #   whitespace. Such text nodes are ignored.
      # * The corresponding nodes in the two documents are equal.
      #
      # Nodes are tested for equality as follows:
      # XML Declarations::
      #      XML declarations are equal if they have the same version,
      #      encoding, and stand-alone pseudo-attributes.
      # Doctype::
      #      Doctype declarations are ignored.
      # Elements::
      #      Elements are considered equal if they have the same generic
      #      identifier (tag name) and belong to the same namespace. The
      #      namespace _prefixes_ may be different.
      # Attributes::
      #      Attributes are equal if they belong to the same namespace,
      #      have the same name, and the same value.
      # Namespace Declarations::
      #      Namespace _declarations_ (attributes named <tt>xmlns:<em>prefix</em></tt>)
      #      are ignored. There are several reasons for this:
      #      - As long as two elements or attributes
      #        belong to the same namespace, it does not matter what prefixes
      #        are used. XML processors may also change prefixes in unpredictable
      #        ways without this being an error.
      #      - XML processors may _move_ namespace
      #        declarations from one element to another (usually an ancestor,
      #        sometimes a descendant) without this being an error, or under
      #        control by the programmer.
      #      - XML processors may _add_ extraneous namespace declarations
      #        in a manner that is hard for programmers to control.
      # Processing Instructions::
      #      Processing instructions are considered equal if the string
      #      values of their targets and contents are equal.
      # Text::
      #      Text nodes are equal if their values are equal. However, empty
      #      text nodes, and text nodes containing only whitespace are ignored.
      # CDATA::
      #      CDATA nodes are equal if their text content is equal. Whitespace
      #      is _not_ normalized.
      # Comments::
      #      Comments are equal if they have the same content.
      #
      # The +expected_doc+ and +actual_doc+ arguments to this method may be of
      # the following types:
      # * A +REXML+ node, usually a <tt>REXML::Document</tt> or <tt>REXML::Element</tt>
      # * A +File+ or other +IO+ object representing an XML document
      # * A string containing an XML document
      def assert_xml_equal(expected_doc, actual_doc, message = nil)
        expected_doc = parse_xml(expected_doc)
        actual_doc = parse_xml(actual_doc)
        _wrap_assertion do
          full_message = build_message(message, <<EOT, actual_doc.inspect, expected_doc.inspect)

<?> expected to be equal to
<?> but was not.
EOT
          assert_block(full_message){are_equal?(expected_doc, actual_doc)}
        end
      end
      
      private
      
      def parse_xml(xml)
        case xml
        when IO
          REXML::Document.new(xml)
        when String
          REXML::Document.new(xml)
        else
          xml
        end
      end
      
      def are_equal?(expected_doc, actual_doc)
        iterate(expected_doc, actual_doc) do |expected_node, actual_node|
          unless compare_xml_nodes(expected_node, actual_node)
            return false
          end
        end
        true
      end
      
      def iterate(expected_doc, actual_doc)
        filter = Test::Unit::XML::XmlEqualFilter.new()
        expected_iterator = NodeIterator.new(expected_doc, filter)
        actual_iterator = NodeIterator.new(actual_doc, filter)
        while expected_iterator.has_next()
          expected_node = expected_iterator.next()
          actual_node = actual_iterator.next()
          yield expected_node, actual_node
        end
      end
      
      def compare_xml_nodes(expected_node, actual_node)
        return false unless actual_node.instance_of? expected_node.class
        case actual_node
        when REXML::Document
          # TODO: Implement Document comparison
          true
        when REXML::DocType
          # TODO: Implement DOCTYPE comparison
          true
        when REXML::Element :
          compare_elements(expected_node, actual_node)
        when REXML::CData
          compare_texts(expected_node, actual_node)
        when REXML::Text
          compare_texts(expected_node, actual_node)
        when REXML::Comment
          compare_comments(expected_node, actual_node)
        when REXML::Instruction
          compare_pi(expected_node, actual_node)
        when REXML::XMLDecl
          compare_xml_declaration(expected_node, actual_node)
        else
          puts "Unknown node type #{actual_node.class}"
          false
        end
      end
      
      def compare_elements(expected_node, actual_node)
        return  expected_node.name == actual_node.name &&
                expected_node.namespace() == actual_node.namespace() &&
                compare_attributes(expected_node.attributes, actual_node.attributes)
      end
            
      def compare_attributes(expected_attributes, actual_attributes)
        return false unless attribute_count(expected_attributes) == attribute_count(actual_attributes)
        expected_attributes.each_attribute do |expected_attribute|
          expected_prefix = expected_attribute.prefix()
          unless expected_prefix == 'xmlns' then
            expected_name = expected_attribute.name
            expected_namespace = expected_attribute.namespace
            actual_attribute = actual_attributes.get_attribute_ns(expected_namespace, expected_name)
            return false unless actual_attribute
            return false if expected_attribute != actual_attribute
          end
        end
        true
      end
      
      def attribute_count(attributes)
        # Do not count namespace declarations
        attributes.size - attributes.prefixes.size
      end
          
      def compare_texts(expected_node, actual_node)
        expected_node.value.eql?(actual_node.value)
      end  
      
      def compare_comments(expected_node, actual_node)
        expected_node == actual_node
      end
      
      def compare_pi(expected_pi, actual_pi)
        return expected_pi.target == actual_pi.target &&
               expected_pi.content == actual_pi.content
      end
      
      def compare_xml_declaration(expected_decl, actual_decl)
        return expected_decl == actual_decl
      end
      
    end      
  end
end

