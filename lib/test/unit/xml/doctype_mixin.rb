module REXML
  class DocType
  
    def public
      @long_name
    end
    
    def system
      @uri
    end
    
    def notations
      children().select {|node| node.kind_of?(REXML::NotationDecl)}
    end
    
    def notation(name)
      notations.find { |notation_decl|
        notation_decl.name == name
      }
    end
  end
end