
require 'test/unit/xml/notationdecl_mixin'

module REXML

  # The REXML::DocType mix-in adds methods that are useful for
  # Doctype declarations, but not present in the standard
  # REXML::DocType class
  class DocType
    
    # This method retrieves the public identifier identifying the document's DTD.
    undef :public if method_defined? :public
    def public
      case @external_id
      when "SYSTEM"
        nil
      when "PUBLIC"
        strip_quotes(@long_name)
      end
    end
    
    # This method retrieves the system identifier identifying the document's DTD
    undef :system if method_defined? :system
    def system
      case @external_id
      when "SYSTEM"
        strip_quotes(@long_name)
      when "PUBLIC"
        @uri.kind_of?(String) ? strip_quotes(@uri) : nil
      end
    end
    
    # This method returns a list of notations that have been declared in the
    # _internal_ DTD subset. Notations in the external DTD subset are not listed.
    undef :notations if method_defined? :notations
    def notations
      children().select {|node| node.kind_of?(REXML::NotationDecl)}
    end
    
    # Retrieves a named notation. Only notations declared in the internal
    # DTD subset can be retrieved.
    undef :notation if method_defined? :notation
    def notation(name)
      notations.find { |notation_decl|
        notation_decl.name == name
      }
    end
    
    private
    
    undef strip_quotes if private_method_defined? :strip_quotes
    def strip_quotes(quoted_string)
      quoted_string =~ /^[\'\"].*[\'\"]$/ ?
        quoted_string[1, quoted_string.length-2] :
        quoted_string
    end
    
  end
end
