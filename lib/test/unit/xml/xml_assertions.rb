#! /usr/bin/ruby

require 'rexml/document'
require 'test/unit/xml/attributes_mixin' # Must be required after rexml/document
require 'test/unit/xml/doctype_mixin' # Must be required after rexml/document
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
      #      Doctypes are equal if they fulfill all of the following conditions:
      #      * They have the same public identifier, or neither has a public identifier
      #      * If one of the doctypes has a system identifier that is a URN,
      #        the other doctype must have a system identifier that is the same URN.
      #        System identifiers that are URLs are ignored for comparison purposes.
      #        The reason is that the same DTD is very often stored in many different
      #        locations (for example different directories on different computers).
      #        Therefore the physical location of the DTD does not say anything useful
      #        about whether two documents are equal.
      #      * An entity declaration present in one of the doctype declarations
      #        must also be present in the other.
      #      * A notation declaration present in one of the doctype declarations
      #        must also be present in the other.
      # Internal General Entity Declaration::
      #      Internal General entity declarations are equal if they have the same name,
      #      and the same value.
      # External General Entity Declaration::
      #      External general entity declarations are equal if they have the same name,
      #      and if the identifiers are of the same type (PUBLIC or SYSTEM) and have
      #      the same value. Note that if the identifiers are URLs, a comparison may
      #      fail even though both URLS point to the same resource, for example if one
      #      URL is relative and the other is absolute.
      # Notation Declaration::
      #      Notation declarations are equal if they have the same name,
      #      and if the identifiers are of the same type (PUBLIC or SYSTEM) and have
      #      the same value. 
      # Elements::
      #      Elements are considered equal if they have the same generic
      #      identifier (tag name), belong to the same namespace, and have the same
      #      attributes. Note that the namespace _prefixes_ of two elements may be different
      #      as long as they belong to the same namespace.
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
          compare_doctypes(expected_node, actual_node)
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
        #when REXML::Entity
        #  compare_xml_entities(expected_node, actual_node)
        else
          puts "Unknown node type #{actual_node.class}"
          false
        end
      end
      
      def compare_doctypes(expected_node, actual_node)
        return compare_system_id(expected_node.system, actual_node.system) &&
          expected_node.public == actual_node.public &&
          compare_xml_internal_dtd_subset(expected_node, actual_node)
      end
      
      def compare_system_id(expected_id, actual_id)
        is_expected_urn = expected_id =~ /^urn:/i
        is_actual_urn = actual_id =~ /^urn:/i
        if is_expected_urn || is_actual_urn
          expected_id == actual_id
        else
          true
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
      
      def compare_xml_internal_dtd_subset(expected_node, actual_node)
        expected_subset = expected_node.children()
        actual_subset = actual_node.children()
        return false unless expected_subset.length == actual_subset.length
        expected_subset.inject(true) { |memo, expected_decl|
          #puts "Memo: " + memo.inspect
          #puts "Expected decl: " + expected_decl.inspect
          case expected_decl
          when REXML::Entity
            #puts "Actual entity decl: " + actual_node.entity(expected_decl.name).inspect
            memo &&
            expected_decl.value == actual_node.entities[expected_decl.name].value &&
            expected_decl.ndata == actual_node.entities[expected_decl.name].ndata
          when REXML::NotationDecl
            #puts "Expected decl: " + expected_decl.inspect
            true
          when REXML::Comment
            true
          else
            raise "Unexpected node type in internal DTD subset of expected document: " + expected_decl.inspect
          end
        } 
      end
      
#       def compare_xml_entity(expected_node, actual_node)
#         return expected_node.name == actual_node.name &&
#                expected_node.value == actual_node.value
#       end

      
    end      
  end
end

